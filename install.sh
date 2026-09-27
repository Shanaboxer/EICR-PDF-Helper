#!/usr/bin/env bash
# DrSparX LaTeX helper installer for Linux / macOS.
#
# Registers the native-messaging host for whichever browsers it finds:
# Firefox, Chrome, Chromium, Brave, Edge, Vivaldi.
#
# IMPORTANT: run this as your NORMAL user, NOT with sudo. Browsers run as you,
# and look for this file in YOUR home folder. Running it as root installs it in
# root's home, where the browser can never see it.

set -euo pipefail

if [ "$(id -u)" = "0" ] && [ -z "${DRSPARX_ALLOW_ROOT:-}" ]; then
  echo "!! Do NOT run this with sudo / as root."
  echo "   Run it as your normal user:   ./install.sh"
  echo "   (The browser runs as you and won't see a root install.)"
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST_NAME="co.uk.drsparx.latex"
SCRIPT="$HERE/drsparx_latex.py"
FIREFOX_EXT_ID="forms@drsparx.co.uk"

# The stable Chrome extension ID this build produces (from the manifest key).
CHROME_ID_DEFAULT="$(cat "$HERE/CHROME_ID.txt" 2>/dev/null | tr -d '[:space:]' || true)"

chmod +x "$SCRIPT"

# Point the script's shebang at a real python3
PY="$(command -v python3 || true)"
if [ -z "$PY" ]; then
  echo "!! python3 not found. Install it first (sudo apt install python3), then re-run."
  exit 1
fi
sed -i.bak "1s|.*|#!$PY|" "$SCRIPT" && rm -f "$SCRIPT.bak"

OS="$(uname -s)"

# --- work out the Chrome extension ID to authorise ---
echo
echo "Chrome/Chromium needs the extension's ID to trust the helper."
echo "This build's fixed ID is: ${CHROME_ID_DEFAULT:-<unknown>}"
echo "If yours differs (go to the browser's Extensions page, enable Developer"
echo "mode, and read the ID under DrSparX Forms), type it now."
printf "Chrome extension ID [%s]: " "$CHROME_ID_DEFAULT"
read -r CHROME_ID || true
CHROME_ID="${CHROME_ID:-$CHROME_ID_DEFAULT}"

write_firefox_manifest() {
  local dir="$1"
  mkdir -p "$dir"
  cat > "$dir/$HOST_NAME.json" <<JSON
{
  "name": "$HOST_NAME",
  "description": "DrSparX LaTeX compiler bridge",
  "path": "$SCRIPT",
  "type": "stdio",
  "allowed_extensions": ["$FIREFOX_EXT_ID"]
}
JSON
  echo "  Firefox:  $dir/$HOST_NAME.json"
}

write_chrome_manifest() {
  local dir="$1"
  [ -n "$CHROME_ID" ] || return 0
  mkdir -p "$dir"
  cat > "$dir/$HOST_NAME.json" <<JSON
{
  "name": "$HOST_NAME",
  "description": "DrSparX LaTeX compiler bridge",
  "path": "$SCRIPT",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$CHROME_ID/"]
}
JSON
  echo "  Chrome:   $dir/$HOST_NAME.json"
}

echo
echo "Installing host manifests for browsers found on this machine:"

if [ "$OS" = "Darwin" ]; then
  APPSUP="$HOME/Library/Application Support"
  write_firefox_manifest "$HOME/Library/Application Support/Mozilla/NativeMessagingHosts"
  write_chrome_manifest "$APPSUP/Google/Chrome/NativeMessagingHosts"
  write_chrome_manifest "$APPSUP/Chromium/NativeMessagingHosts"
  write_chrome_manifest "$APPSUP/BraveSoftware/Brave-Browser/NativeMessagingHosts"
  write_chrome_manifest "$APPSUP/Microsoft Edge/NativeMessagingHosts"
  write_chrome_manifest "$APPSUP/Vivaldi/NativeMessagingHosts"
else
  # Linux — cover both native and Flatpak/Snap-ish config roots
  write_firefox_manifest "$HOME/.mozilla/native-messaging-hosts"
  # Chrome family: <config>/NativeMessagingHosts
  write_chrome_manifest "$HOME/.config/google-chrome/NativeMessagingHosts"
  write_chrome_manifest "$HOME/.config/chromium/NativeMessagingHosts"
  write_chrome_manifest "$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
  write_chrome_manifest "$HOME/.config/microsoft-edge/NativeMessagingHosts"
  write_chrome_manifest "$HOME/.config/vivaldi/NativeMessagingHosts"
fi

echo
echo "Done. Now:"
echo "  1. FULLY quit your browser (close every window) and reopen it."
echo "  2. Open the extension -> Settings -> Test connection."
echo "     It should read: local XeLaTeX."
