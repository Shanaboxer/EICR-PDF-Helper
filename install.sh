#!/usr/bin/env bash
# Register the DrSparX LaTeX native host with Firefox on Linux or macOS.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_NAME="co.uk.drsparx.latex"
EXT_ID="forms@drsparx.co.uk"
SCRIPT="$HERE/drsparx_latex.py"
chmod +x "$SCRIPT"

case "$(uname -s)" in
  Darwin) DIR="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts" ;;
  *)      DIR="$HOME/.mozilla/native-messaging-hosts" ;;
esac
mkdir -p "$DIR"

cat > "$DIR/$HOST_NAME.json" <<JSON
{
  "name": "$HOST_NAME",
  "description": "DrSparX LaTeX compiler bridge",
  "path": "$SCRIPT",
  "type": "stdio",
  "allowed_extensions": ["$EXT_ID"]
}
JSON

# make sure a python3 shebang resolves; rewrite it to the found interpreter
PY="$(command -v python3 || true)"
if [ -n "$PY" ]; then
  sed -i.bak "1s|.*|#!$PY|" "$SCRIPT" && rm -f "$SCRIPT.bak"
fi

echo "Installed native host manifest at:"
echo "  $DIR/$HOST_NAME.json"
echo "Restart Firefox, then rebuild a certificate. Engine should read 'local XeLaTeX'."
