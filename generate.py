#!/usr/bin/env python3
"""
Generates PortuguesePC.keylayout — a macOS keyboard layout matching a standard
Portuguese *PC/ISO* keyboard (the legends printed on an ASUS Jelly75 KD201),
rather than Apple's own Portuguese layout.

macOS's built-in "Portuguese" targets Apple's ISO keyboard, which places six
punctuation keys differently:

    physical key      macOS "Portuguese"    PT PC keycap
    left of 1         < >                   \\ |
    left of Z         § ±                   < >
    right of '        + *                   « »
    right of P        º ª                   + *   (AltGr ¨)
    right of Ç        ~ ^                   º ª
    right of º        \\ |                   ~ ^

Run:  python3 generate.py   ->   PortuguesePC.keylayout
"""

import os

LAYOUT_NAME = "Portuguese PC (KD201)"
LAYOUT_ID = "-19010"

# Dead-key states and the bare glyph each produces on its own.
STATES = {
    "acute": "´",   # ´
    "grave": "`",   # `
    "tilde": "~",   # ~
    "circ":  "^",   # ^
    "diae":  "¨",   # ¨
}

# What each dead state produces when followed by a given letter.
COMBOS = {
    "acute": {"a": "á", "e": "é", "i": "í", "o": "ó", "u": "ú",
              "A": "Á", "E": "É", "I": "Í", "O": "Ó", "U": "Ú"},
    "grave": {"a": "à", "e": "è", "i": "ì", "o": "ò", "u": "ù",
              "A": "À", "E": "È", "I": "Ì", "O": "Ò", "U": "Ù"},
    "tilde": {"a": "ã", "o": "õ", "n": "ñ",
              "A": "Ã", "O": "Õ", "N": "Ñ"},
    "circ":  {"a": "â", "e": "ê", "i": "î", "o": "ô", "u": "û",
              "A": "Â", "E": "Ê", "I": "Î", "O": "Ô", "U": "Û"},
    "diae":  {"a": "ä", "e": "ë", "i": "ï", "o": "ö", "u": "ü",
              "A": "Ä", "E": "Ë", "I": "Ï", "O": "Ö", "U": "Ü"},
}

# Letters routed through <action> so they can combine with a dead key.
LIVE_LETTERS = set("aeioun") | set("AEIOUN")


def dead(state):
    return ("dead", state)


# ---------------------------------------------------------------------------
# keycode -> (base, shift, option/AltGr, option+shift)
#
# Keycodes are macOS virtual keycodes *as this keyboard actually emits them*:
#   kc 10 = key left of "1"  (kVK_ISO_Section)
#   kc 50 = key left of "Z"  (kVK_ANSI_Grave)
# That is Apple's ISO arrangement, not the generic PC ISO one. A generic PC
# ISO keyboard sends HID 0x35 (-> kc 50) for the key left of "1" and HID 0x64
# (-> kc 10) for the key left of "Z"; the KD201 reports them the other way
# round, so the two tuples below sit on the codes shown here. Checked against
# the hardware 2026-10-22 after the keys came out swapped.
# ---------------------------------------------------------------------------
KEYS = {
    # --- number row -------------------------------------------------------
    10: ("\\", "|", "‹", "›"),            # \ |   (key left of 1)   ‹ ›
    18: ("1", "!", "¹", "¡"),             # 1 !          ¹ ¡
    19: ("2", '"', "@", "²"),                  # 2 " @        ²
    20: ("3", "#", "£", "€"),             # 3 # £        €
    21: ("4", "$", "§", "¢"),             # 4 $ §        ¢
    23: ("5", "%", "‰", "∞"),             # 5 %          ‰ ∞
    22: ("6", "&", "¶", "•"),             # 6 &          ¶ •
    26: ("7", "/", "{", "÷"),                  # 7 / {        ÷
    28: ("8", "(", "[", "°"),                  # 8 ( [        °
    25: ("9", ")", "]", "±"),                  # 9 ) ]        ±
    29: ("0", "=", "}", "≠"),                  # 0 = }        ≠
    27: ("'", "?", "§", "¿"),             # ' ?          § ¿
    24: ("«", "»", "≤", "≥"),   # « »          ≤ ≥

    # --- QWERTY row -------------------------------------------------------
    12: ("q", "Q", "œ", "Œ"),
    13: ("w", "W", "∑", "∑"),
    14: ("e", "E", "€", "Æ"),             # AltGr+E = €
    15: ("r", "R", "®", "®"),
    17: ("t", "T", "™", "™"),
    16: ("y", "Y", "¥", "¥"),
    32: ("u", "U", "†", "‡"),
    34: ("i", "I", "ı", "˚"),
    31: ("o", "O", "ø", "Ø"),
    35: ("p", "P", "π", "∏"),
    33: ("+", "*", dead("diae"), "±"),         # + *   AltGr = ¨ (dead)
    30: (dead("acute"), dead("grave"), dead("diae"), "`"),
                                                    # ´ `   Opt+Shift = literal `

    # --- home row ---------------------------------------------------------
    0:  ("a", "A", "å", "Å"),
    1:  ("s", "S", "ß", "ß"),
    2:  ("d", "D", "∂", "∆"),
    3:  ("f", "F", "ƒ", "ƒ"),
    5:  ("g", "G", "˙", "˙"),
    4:  ("h", "H", "ˇ", "ˇ"),
    38: ("j", "J", "¯", "¯"),
    40: ("k", "K", "„", "‚"),
    37: ("l", "L", "‘", "’"),
    41: ("ç", "Ç", "¸", "˛"),   # ç Ç
    39: ("º", "ª", "°", "˚"),   # º ª
    42: (dead("tilde"), dead("circ"), "~", "^"),    # ~ ^   Opt = literal ~ / ^

    # --- bottom row -------------------------------------------------------
    50: ("<", ">", "≤", "≥"),             # < >   (key left of Z)
    6:  ("z", "Z", "Ω", "Ω"),
    7:  ("x", "X", "«", "»"),
    8:  ("c", "C", "©", "©"),
    9:  ("v", "V", "√", "√"),
    11: ("b", "B", "∫", "∫"),
    45: ("n", "N", "¬", "¬"),
    46: ("m", "M", "µ", "µ"),
    43: (",", ";", "“", "”"),             # , ;
    47: (".", ":", "…", "·"),             # . :
    44: ("-", "_", "—", "–"),             # - _
}

# Control / navigation keys — identical in every map.
CONTROL = {
    36:  "\r",      # Return
    48:  "\t",      # Tab
    51:  "\x08",    # Delete (backspace)
    53:  "\x1b",    # Escape
    71:  "\x1b",    # Clear
    76:  "\x03",    # Enter (keypad)
    115: "\x01",    # Home
    116: "\x0b",    # Page Up
    117: "\x7f",    # Forward Delete
    119: "\x04",    # End
    121: "\x0c",    # Page Down
    123: "\x1c",    # Left
    124: "\x1d",    # Right
    125: "\x1f",    # Down
    126: "\x1e",    # Up
}
for _fk in (122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113):
    CONTROL[_fk] = "\x10"  # F1..F15

# Numeric keypad — identical in every map.
KEYPAD = {
    65: ".", 67: "*", 69: "+", 75: "/", 78: "-", 81: "=",
    82: "0", 83: "1", 84: "2", 85: "3", 86: "4",
    87: "5", 88: "6", 89: "7", 91: "8", 92: "9",
}

SPACE = 49  # an action, so "dead key + space" yields the bare accent


def is_cased_letter(value):
    """True for letters that have a distinct upper/lower form (a, ç ... not º)."""
    return (isinstance(value, str) and len(value) == 1
            and value.lower() != value.upper())


# ---------------------------------------------------------------------------
# XML emission
# ---------------------------------------------------------------------------
def esc(s):
    """Escape for a keylayout attribute.

    macOS's keylayout parser understands *numeric* character references but not
    the named ones (&amp; &lt; &gt;) — a key written as output="&lt;" silently
    produces nothing. So every character that is not a plain, safe ASCII glyph
    is emitted as &#xNNNN;, exactly as Apple's own layouts do.
    """
    special = '&<>"\''
    out = []
    for ch in s:
        if ch in special or ord(ch) < 0x20 or ord(ch) > 0x7E:
            out.append("&#x%04X;" % ord(ch))
        else:
            out.append(ch)
    return "".join(out)


def key_xml(code, val):
    """One <key> element. `val` is a literal string or ('dead', state)."""
    if isinstance(val, tuple):
        return '      <key code="%d" action="dead_%s"/>' % (code, val[1])
    if val in LIVE_LETTERS:
        return '      <key code="%d" action="%s"/>' % (code, val)
    return '      <key code="%d" output="%s"/>' % (code, esc(val))


def build_map(index, picker):
    lines = ['    <keyMap index="%d">' % index]
    for code in sorted(KEYS):
        lines.append(key_xml(code, picker(KEYS[code])))
    lines.append('      <key code="%d" action="space"/>' % SPACE)
    for code in sorted(CONTROL):
        lines.append('      <key code="%d" output="%s"/>' % (code, esc(CONTROL[code])))
    for code in sorted(KEYPAD):
        lines.append('      <key code="%d" output="%s"/>' % (code, esc(KEYPAD[code])))
    lines.append('    </keyMap>')
    return "\n".join(lines)


def main():
    maps = [
        build_map(0, lambda t: t[0]),   # base
        build_map(1, lambda t: t[1]),   # shift
        # caps: uppercase for cased letters, base for everything else
        build_map(2, lambda t: t[1] if is_cased_letter(t[0]) else t[0]),
        build_map(3, lambda t: t[2]),   # option / AltGr
        build_map(4, lambda t: t[3]),   # option + shift
    ]

    actions = []
    for state in STATES:
        actions.append('    <action id="dead_%s">' % state)
        actions.append('      <when state="none" next="%s"/>' % state)
        actions.append('    </action>')

    for letter in sorted(LIVE_LETTERS):
        actions.append('    <action id="%s">' % letter)
        actions.append('      <when state="none" output="%s"/>' % esc(letter))
        for state in STATES:
            if letter in COMBOS[state]:
                actions.append('      <when state="%s" output="%s"/>'
                               % (state, esc(COMBOS[state][letter])))
        actions.append('    </action>')

    actions.append('    <action id="space">')
    actions.append('      <when state="none" output="&#x0020;"/>')
    for state, glyph in STATES.items():
        actions.append('      <when state="%s" output="%s"/>' % (state, esc(glyph)))
    actions.append('    </action>')

    terminators = ['    <when state="%s" output="%s"/>' % (s, esc(g))
                   for s, g in STATES.items()]

    nl = chr(10)
    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE keyboard SYSTEM "file://localhost/System/Library/DTDs/KeyboardLayout.dtd">
<!--
  {LAYOUT_NAME}

  Portuguese PC/ISO layout for macOS. Matches the legends printed on a standard
  PT PC keyboard (ASUS Jelly75 KD201); Apple's built-in "Portuguese" layout puts
  six punctuation keys elsewhere.

  Generated by generate.py — edit that, not this file.
-->
<keyboard group="126" id="{LAYOUT_ID}" name="{LAYOUT_NAME}" maxout="4">
  <layouts>
    <layout first="0" last="255" modifiers="mods" mapSet="ptpc"/>
  </layouts>
  <modifierMap id="mods" defaultIndex="0">
    <keyMapSelect mapIndex="0">
      <modifier keys=""/>
      <modifier keys="command"/>
      <modifier keys="anyControl"/>
      <modifier keys="command anyControl"/>
    </keyMapSelect>
    <keyMapSelect mapIndex="1">
      <modifier keys="anyShift"/>
      <modifier keys="anyShift command"/>
      <modifier keys="anyShift caps"/>
      <modifier keys="anyShift anyControl"/>
      <modifier keys="anyShift caps command"/>
    </keyMapSelect>
    <keyMapSelect mapIndex="2">
      <modifier keys="caps"/>
      <modifier keys="caps command"/>
      <modifier keys="caps anyControl"/>
    </keyMapSelect>
    <keyMapSelect mapIndex="3">
      <modifier keys="anyOption"/>
      <modifier keys="anyOption command"/>
      <modifier keys="anyOption caps"/>
      <modifier keys="anyOption anyControl"/>
    </keyMapSelect>
    <keyMapSelect mapIndex="4">
      <modifier keys="anyOption anyShift"/>
      <modifier keys="anyOption anyShift command"/>
      <modifier keys="anyOption anyShift caps"/>
      <modifier keys="anyOption anyShift anyControl"/>
    </keyMapSelect>
  </modifierMap>
  <keyMapSet id="ptpc">
{nl.join(maps)}
  </keyMapSet>
  <actions>
{nl.join(actions)}
  </actions>
  <terminators>
{nl.join(terminators)}
  </terminators>
</keyboard>
"""
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "PortuguesePC-KD201.keylayout")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(xml)
    print("wrote", out)


if __name__ == "__main__":
    main()
