#!/bin/bash
# Installs the Portuguese PC keyboard layout for the ASUS Jelly75 KD201, plus
# the Alt Gr -> Option mapping that the AltGr layer needs.
#
#   ./install.sh             install (or update)
#   ./install.sh --uninstall remove
#
# No third-party software involved: a .keylayout file and hidutil, both built in.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYOUT="PortuguesePC-KD201.keylayout"
LAYOUT_DIR="$HOME/Library/Keyboard Layouts"
AGENT_LABEL="com.local.asus-kd201-altgr"
AGENT_DIR="$HOME/Library/LaunchAgents"
AGENT_PLIST="$AGENT_DIR/$AGENT_LABEL.plist"

# The launch agent must not point into this checkout: it may live in a git
# worktree that gets cleaned up later, which would break the mapping silently.
# The script is copied somewhere stable and the agent runs that copy.
RUNTIME_DIR="$HOME/Library/Application Support/asus-kd201"
RUNTIME_SCRIPT="$RUNTIME_DIR/altgr-remap.sh"

if [[ "${1:-}" == "--uninstall" ]]; then
  launchctl bootout "gui/$(id -u)/$AGENT_LABEL" 2>/dev/null || true
  rm -f "$AGENT_PLIST"
  bash "$SRC_DIR/altgr-remap.sh" --reset 2>/dev/null || true
  rm -rf "$RUNTIME_DIR"
  rm -f "$LAYOUT_DIR/$LAYOUT"
  echo "Removed the layout, the Alt Gr mapping and its launch agent."
  echo "Log out and back in to clear the layout from the input-source list."
  exit 0
fi

# 1. the layout ------------------------------------------------------------
mkdir -p "$LAYOUT_DIR"
cp "$SRC_DIR/$LAYOUT" "$LAYOUT_DIR/"
echo "Installed: $LAYOUT_DIR/$LAYOUT"

# 2. the Alt Gr mapping, re-applied at login and after reconnects -----------
mkdir -p "$RUNTIME_DIR"
cp "$SRC_DIR/altgr-remap.sh" "$RUNTIME_SCRIPT"
chmod +x "$RUNTIME_SCRIPT"
echo "Installed: $RUNTIME_SCRIPT"

mkdir -p "$AGENT_DIR"
sed "s|__SCRIPT__|$RUNTIME_SCRIPT|" \
    "$SRC_DIR/$AGENT_LABEL.plist" > "$AGENT_PLIST"
launchctl bootout "gui/$(id -u)/$AGENT_LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
echo "Installed: $AGENT_PLIST"

if bash "$RUNTIME_SCRIPT"; then
  :
else
  echo
  echo "The layout is installed, but the Alt Gr key is not remapped yet."
  echo "Uninstall Karabiner-Elements (it seizes the keyboard), then re-run:"
  echo "  ./altgr-remap.sh"
fi

cat <<'EOF'

Next steps
  1. System Settings -> Keyboard -> Keyboard layouts -> Edit... -> +
     -> Others (bottom of the list) -> "Portuguese PC (KD201)" -> Add
  2. Select it from the input menu in the menu bar.
  3. Put the keyboard in Mac mode with Fn+F12.

If the layout is listed but behaves like the old one, log out and back in —
macOS caches parsed keyboard layouts per filename.
EOF
