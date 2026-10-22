#!/bin/bash
# Makes the ASUS Jelly75 KD201's "Alt Gr" key behave as Option, so it reaches
# the AltGr layer of the Portuguese PC layout (@ £ § { [ ] } € ¨).
#
# In Mac mode that key sends right *Command*, which a keyboard layout cannot
# reinterpret — Command combinations go to menus, not to text. hidutil is
# macOS's own per-device HID remapper, so this needs no third-party software.
#
#   ./altgr-remap.sh          apply
#   ./altgr-remap.sh --reset  undo (also undone by unplugging the keyboard)
#
# Scoped to this keyboard by vendor/product id — the MacBook's built-in
# keyboard and every other device are untouched.

# Matched by product name, not vendor/product id, on purpose: this keyboard
# reports different ids depending on how it is connected —
#   Bluetooth     0x0b05 / 0x1c48
#   2.4GHz dongle 0xae24 / 0x8918
# so an id-based match silently stops working when you switch transport.
MATCH='{"Product":"ASUS KD201"}'

# HID keyboard usages:
#   0xE0 left control   0xE3 left command
#   0xE6 right option   0xE7 right command
RIGHT_COMMAND=0x7000000E7
RIGHT_OPTION=0x7000000E6
LEFT_CONTROL=0x7000000E0
LEFT_COMMAND=0x7000000E3

# Set to 1 to also swap left Command and Control on this keyboard, which is what
# the old Karabiner profile did. Off by default: it is a personal preference,
# not part of making the Portuguese layout correct.
SWAP_LEFT_CMD_CTRL=0

if [[ "${1:-}" == "--reset" ]]; then
  hidutil property --matching "$MATCH" --set '{"UserKeyMapping":[]}' >/dev/null
  echo "Reset key mapping for ASUS KD201."
  exit 0
fi

MAPPINGS="{\"HIDKeyboardModifierMappingSrc\":$RIGHT_COMMAND,\"HIDKeyboardModifierMappingDst\":$RIGHT_OPTION}"

if [[ "$SWAP_LEFT_CMD_CTRL" == "1" ]]; then
  MAPPINGS="$MAPPINGS,{\"HIDKeyboardModifierMappingSrc\":$LEFT_COMMAND,\"HIDKeyboardModifierMappingDst\":$LEFT_CONTROL}"
  MAPPINGS="$MAPPINGS,{\"HIDKeyboardModifierMappingSrc\":$LEFT_CONTROL,\"HIDKeyboardModifierMappingDst\":$LEFT_COMMAND}"
fi

hidutil property --matching "$MATCH" --set "{\"UserKeyMapping\":[$MAPPINGS]}" >/dev/null

# hidutil prints nothing on success and silently no-ops if the device is absent
# or has been seized by another process, so confirm the mapping actually stuck.
if hidutil property --matching "$MATCH" --get UserKeyMapping 2>/dev/null | grep -q "HIDKeyboardModifierMappingSrc"; then
  echo "Alt Gr now acts as Option on the ASUS KD201."
else
  echo "Could not apply the mapping." >&2
  echo "Is the keyboard connected? If Karabiner-Elements is still installed it" >&2
  echo "seizes the device exclusively and hidutil cannot see it." >&2
  exit 1
fi
