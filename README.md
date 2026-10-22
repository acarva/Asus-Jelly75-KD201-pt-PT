# Portuguese PC layout for macOS — ASUS Jelly75 KD201

A macOS keyboard layout that matches the legends actually printed on a standard
Portuguese **PC/ISO** keyboard, in this case the ASUS Jelly75 KD201. No
third-party software — a `.keylayout` file plus `hidutil`, both built into macOS.

macOS ships a "Portuguese" layout, but it targets **Apple's** Portuguese ISO
keyboard, which moves several punctuation keys. The net effect on a PC keyboard
is six keys that type the wrong character:

| Physical key | macOS "Portuguese" types | Keycap says |
|---|---|---|
| left of `1` | `<` `>` | `\` `\|` |
| left of `Z` | `§` `±` | `<` `>` |
| right of `'` | `+` `*` | `«` `»` |
| right of `P` | `º` `ª` | `+` `*` |
| right of `Ç` | `~` `^` | `º` `ª` |
| right of `º` | `\` `\|` | `~` `^` |

The AltGr layer differs too: on a PT PC keyboard `£` is on `3`, `§` on `4`,
`{` on `7`, `}` on `0` and `€` on `E`.

### The two ISO keys left of `1` and left of `Z`

These two swap virtual keycodes between keyboards, and the KD201 follows
**Apple's** arrangement rather than the generic PC one: it emits keycode `10`
(`kVK_ISO_Section`) for the key left of `1` and keycode `50` (`kVK_ANSI_Grave`)
for the key left of `Z`. A generic PC ISO keyboard sends them the other way
round. The layout was first written for the generic convention, which put `<`
and `\` on each other's keys; it was corrected on 2026-10-22. If you ever
rebuild this for a different keyboard and those two keys come out swapped, the
fix is to exchange the `10:` and `50:` entries in `generate.py` (and the four
matching assertions in `verify.swift`).

## Files

| File | What it is |
|---|---|
| `PortuguesePC-KD201.keylayout` | The layout itself. This is the deliverable. |
| `generate.py` | Generates the `.keylayout`. Edit this, not the XML. |
| `verify.swift` | 48 assertions run against the *installed* layout. |
| `altgr-remap.sh` | Makes the Alt Gr key act as Option, this keyboard only. |
| `com.local.asus-kd201-altgr.plist` | Launch agent that re-applies that mapping. |
| `install.sh` | Puts all of it in place. |

## Install

```bash
./install.sh
```

Then:

1. **System Settings → Keyboard → Keyboard layouts → Edit… → `+`**. In the
   language list, scroll to **Others** at the bottom — custom layouts are filed
   there, not under Portuguese — and add **"Portuguese PC (KD201)"**.
2. Select it from the input menu in the menu bar.
3. Put the keyboard in Mac mode with **Fn+F12** (Fn+F11 is Windows mode). The
   grey sub-legends — `⌥` on the Win key, `⌘` on Alt — describe Mac mode.

`./install.sh --uninstall` reverses everything.

## The Alt Gr key

In Mac mode this keyboard's **Alt Gr** sends *right Command*, not Option. A
keyboard layout cannot rescue that: Command combinations are routed to menu
shortcuts before any text is produced, so `Alt Gr`+`3` opens a menu instead of
typing `£`.

`altgr-remap.sh` fixes it at the HID level with **`hidutil`**, macOS's own
per-device remapper, turning right Command into right Option. It matches on the
product name `ASUS KD201`, so the MacBook's built-in keyboard and everything
else are untouched.

Matching by name rather than by vendor/product id is deliberate: this keyboard
reports **different ids depending on how it is connected** — `0x0b05`/`0x1c48`
over Bluetooth, `0xae24`/`0x8918` through the 2.4GHz dongle. An id-based match
works until you switch transport and then silently stops.

hidutil mappings live on the *connected device*, so they vanish on unplug,
wireless reconnect and reboot. The launch agent re-applies the mapping at login
and once a minute thereafter; re-setting an identical mapping is a no-op.

The layout treats **either** Option key as AltGr, so `@ £ § { [ ] } € ¨` also
work from the left `Win`(⌥) key even without the remap.

### Karabiner-Elements must not be installed

Karabiner **seizes** the keyboard exclusively and re-emits its events through a
virtual device. While it is installed, `hidutil list` cannot even see the ASUS
and the remap silently does nothing. Uninstall it with the official script:

```bash
sudo '/Library/Application Support/org.pqrs/Karabiner-Elements/uninstall.sh'
```

That script deletes the files but leaves its launch agents running, as orphaned
processes whose binaries no longer exist. Force Quit cannot end them — launchd
owns them, not the Dock. Unload the jobs instead:

```bash
for j in Karabiner-Menu Karabiner-NotificationWindow \
         karabiner_console_user_server Karabiner-Core-Service-rev2; do
  launchctl bootout "gui/$(id -u)/org.pqrs.service.agent.$j"
done
```

The DriverKit virtual-keyboard extension outlives the uninstaller too. Remove it
from **System Settings → General → Login Items & Extensions → Driver
Extensions**; SIP blocks `systemextensionsctl uninstall` once the owning app is
gone.

The Karabiner profile that used to be here, "ASUS KD201 Portuguese PC Layout
Adaptation Profile", also swapped **left Command and Control** on this keyboard.
That was a personal preference rather than a layout fix, so it is off by default;
set `SWAP_LEFT_CMD_CTRL=1` at the top of `altgr-remap.sh` to keep it.

## Layout reference

Base / Shift / AltGr:

```
 \|     1!  2"@  3#£  4$§  5%  6&  7/{  8([  9)]  0=}  '?  «»
        Q   W    E€   R    T   Y   U    I    O    P    +*¨  ´`
        A   S    D    F    G   H   J    K    L    Ç    ºª   ~^
 <>     Z   X    C    V    B   N   M    ,;   .:   -_
```

Dead keys: `´` (acute), `` ` `` (grave, Shift), `~` (tilde), `^` (circumflex,
Shift), `¨` (diaeresis, AltGr on the `+*` key). Each followed by a space gives
the bare accent; followed by a letter it does not combine with, it emits the
accent then the letter.

Two conveniences beyond the PC layout, for typing code:

- **Option + the `~^` key** gives a literal `~`, **Option+Shift** a literal `^` —
  no trailing space needed.
- **Option+Shift + the `´``` key** gives a literal backtick `` ` ``.

Left Option otherwise keeps the usual Mac characters (`å ø œ ∞ †` …).

## Editing it

```bash
python3 generate.py                       # rewrites the .keylayout
cp PortuguesePC-KD201.keylayout ~/Library/Keyboard\ Layouts/
swiftc -O verify.swift -o verify && ./verify
```

Three things cost real time when building this, all worth knowing:

- **macOS caches parsed layouts per filename.** Editing a `.keylayout` in place
  and reinstalling it keeps serving the *old* parse. Log out and back in, or
  install under a new filename.
- **Only numeric character references work.** `output="&lt;"` parses as XML but
  macOS silently produces *nothing*; it must be `output="&#x003C;"`. Apple's own
  layouts do the same. `generate.py` escapes `& < > " '` this way for that
  reason.
- **Stale entries linger.** A layout that has been renamed or deleted stays in
  the input-source list until the next logout, so `verify.swift` matches the
  layout name exactly rather than by substring — otherwise it can test a ghost
  and report failures that no longer exist.
