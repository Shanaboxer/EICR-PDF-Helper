#!/usr/bin/env python3
"""DrSparX LaTeX native-messaging host.

Firefox sends a JSON message asking us to compile a LaTeX job; we run the
local `xelatex`, and send the finished PDF back (base64). This lets the
extension use the real TeX install already on an electrician's PC, which
gives pixel-identical output to the templates they designed.

Native-messaging framing: each message is a little-endian uint32 length
prefix followed by that many bytes of UTF-8 JSON, on stdin/stdout.
"""
import sys
import os
import json
import struct
import base64
import shutil
import tempfile
import subprocess

MAX_MESSAGE = 200 * 1024 * 1024  # 200 MB ceiling, plenty for a PDF


def read_message():
    raw_len = sys.stdin.buffer.read(4)
    if len(raw_len) < 4:
        return None
    (length,) = struct.unpack("<I", raw_len)
    if length == 0 or length > MAX_MESSAGE:
        return None
    data = sys.stdin.buffer.read(length)
    return json.loads(data.decode("utf-8"))


def send_message(obj):
    data = json.dumps(obj).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(data)))
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


def find_engine(name):
    # honour an explicit path in the environment, else search PATH and the
    # usual TeX Live / MiKTeX install spots
    candidates = [os.environ.get("DRSPARX_" + name.upper())]
    candidates.append(shutil.which(name))
    if os.name == "nt":
        candidates.append(shutil.which(name + ".exe"))
        for root in (r"C:\texlive", r"C:\Program Files\MiKTeX", r"C:\Program Files\MiKTeX 2.9"):
            candidates.append(os.path.join(root, "miktex", "bin", "x64", name + ".exe"))
    else:
        for p in ("/usr/bin", "/usr/local/bin", "/Library/TeX/texbin", "/opt/homebrew/bin"):
            candidates.append(os.path.join(p, name))
    for c in candidates:
        if c and os.path.exists(c):
            return c
    return None


def compile_job(msg):
    engine_name = msg.get("engine", "xelatex")
    if engine_name not in ("xelatex", "lualatex", "pdflatex"):
        return {"ok": False, "error": "unsupported engine: %s" % engine_name}
    engine = find_engine(engine_name)
    if not engine:
        return {"ok": False, "error": "%s not found on this machine" % engine_name}

    main = msg.get("main", "job.tex")
    files = msg.get("files", {})
    binary = set(msg.get("binary", []))

    with tempfile.TemporaryDirectory(prefix="drsparx_") as tmp:
        for name, content in files.items():
            path = os.path.join(tmp, os.path.basename(name))
            if name in binary:
                with open(path, "wb") as f:
                    f.write(base64.b64decode(content))
            else:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(content)

        cmd = [engine, "-interaction=nonstopmode", "-halt-on-error", main]
        env = dict(os.environ)
        try:
            proc = subprocess.run(
                cmd, cwd=tmp, env=env,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                timeout=120,
            )
        except subprocess.TimeoutExpired:
            return {"ok": False, "error": "compile timed out after 120s"}

        log = proc.stdout.decode("utf-8", "replace")
        pdf_path = os.path.join(tmp, os.path.splitext(os.path.basename(main))[0] + ".pdf")
        if not os.path.exists(pdf_path):
            return {"ok": False, "error": "no PDF produced", "log": log}
        with open(pdf_path, "rb") as f:
            pdf = f.read()
        return {"ok": True, "pdf": base64.b64encode(pdf).decode("ascii"), "log": log[-4000:]}


def main():
    while True:
        msg = read_message()
        if msg is None:
            break
        try:
            action = msg.get("action")
            if action == "ping":
                send_message({"ok": True, "pong": True})
            elif action == "compile":
                send_message(compile_job(msg))
            else:
                send_message({"ok": False, "error": "unknown action: %r" % action})
        except Exception as exc:  # never crash the pipe; report instead
            send_message({"ok": False, "error": "host exception: %s" % exc})


if __name__ == "__main__":
    main()
