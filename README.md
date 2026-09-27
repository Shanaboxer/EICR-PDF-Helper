# DrSparX LaTeX native host

This tiny program lets the **DrSparX Forms** Firefox extension compile
certificates using the real `xelatex` already installed on this computer.
It is optional: without it the extension falls back to a slower built-in
engine. Installing it gives faster builds and output identical to the
original DrSparX templates.

Downloads / updates: https://github.com/Shanaboxer/EICR-PDF-Helper
(green **Code** button → **Download ZIP**, then unzip and run the file
for your OS below).

## What you need first
* A TeX distribution with `xelatex` (TeX Live on Linux/macOS, MiKTeX on
  Windows). Test in a terminal: `xelatex --version`.
* Python 3.
* The **extension ID**. In Firefox this host is registered for
  `forms@drsparx.co.uk` (already set in the installers below).

## Install

### Linux / macOS
```
./install.sh
```

### Windows (PowerShell, as your normal user)
```
powershell -ExecutionPolicy Bypass -File install-windows.ps1
```

Runs for **both Firefox and Chrome/Edge/Brave**, with no prompts — it
already knows this build's Chrome ID
(`plgfggbkknfkbpifhniejffmgilnjkgp`). On Linux/Mac run it as
`./install.sh` (dot-slash), **not** with `sudo`.

Then fully quit and reopen your browser and open the extension. The engine label in the
form's sidebar should read **local XeLaTeX** after the first build.

## Uninstall
Delete `drsparx_latex.py` and the manifest the installer created
(`~/.mozilla/native-messaging-hosts/co.uk.drsparx.latex.json` on Linux,
`~/Library/.../NativeMessagingHosts/...` on macOS, or the registry key on
Windows).
