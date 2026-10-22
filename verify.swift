// Verifies the installed "Portugues PC (KD201)" layout against the legends
// printed on the physical keyboard, including dead-key sequences.
//
//   swiftc -O verify.swift -o verify && ./verify
//
// Requires the layout to be installed in ~/Library/Keyboard Layouts/.

import Carbon
import Foundation

let SHIFT = UInt32(shiftKey >> 8)
let OPT   = UInt32(optionKey >> 8)
let CAPS  = UInt32(alphaLock >> 8)

// (keycode, modifiers) pressed in order -> expected resulting text
struct Case { let name: String; let keys: [(Int, UInt32)]; let want: String }

let cases: [Case] = [
  // --- the six keys macOS's own Portuguese layout gets wrong ---------------
  Case(name: "left of 1  -> \\",      keys: [(10, 0)],     want: "\\"),
  Case(name: "left of 1  -> |",      keys: [(10, SHIFT)], want: "|"),
  Case(name: "left of Z  -> <",      keys: [(50, 0)],     want: "<"),
  Case(name: "left of Z  -> >",      keys: [(50, SHIFT)], want: ">"),
  Case(name: "right of ' -> <<",     keys: [(24, 0)],     want: "\u{00AB}"),
  Case(name: "right of ' -> >>",     keys: [(24, SHIFT)], want: "\u{00BB}"),
  Case(name: "right of P -> +",      keys: [(33, 0)],     want: "+"),
  Case(name: "right of P -> *",      keys: [(33, SHIFT)], want: "*"),
  Case(name: "right of C -> masc",   keys: [(39, 0)],     want: "\u{00BA}"),
  Case(name: "right of C -> fem",    keys: [(39, SHIFT)], want: "\u{00AA}"),

  // --- other ASCII that must survive escaping ------------------------------
  Case(name: "6 shift -> &",         keys: [(22, SHIFT)], want: "&"),
  Case(name: "2 shift -> \"",        keys: [(19, SHIFT)], want: "\""),
  Case(name: "quote key -> '",       keys: [(27, 0)],     want: "'"),
  Case(name: "7 shift -> /",         keys: [(26, SHIFT)], want: "/"),

  // --- AltGr layer ---------------------------------------------------------
  Case(name: "AltGr 2 -> @",         keys: [(19, OPT)],   want: "@"),
  Case(name: "AltGr 3 -> GBP",       keys: [(20, OPT)],   want: "\u{00A3}"),
  Case(name: "AltGr 4 -> sect",      keys: [(21, OPT)],   want: "\u{00A7}"),
  Case(name: "AltGr 7 -> {",         keys: [(26, OPT)],   want: "{"),
  Case(name: "AltGr 8 -> [",         keys: [(28, OPT)],   want: "["),
  Case(name: "AltGr 9 -> ]",         keys: [(25, OPT)],   want: "]"),
  Case(name: "AltGr 0 -> }",         keys: [(29, OPT)],   want: "}"),
  Case(name: "AltGr E -> EUR",       keys: [(14, OPT)],   want: "\u{20AC}"),

  // --- dead keys: accented vowels -----------------------------------------
  Case(name: "acute + a -> a-acute",  keys: [(30, 0), (0, 0)],          want: "\u{00E1}"),
  Case(name: "acute + E -> E-acute",  keys: [(30, 0), (14, SHIFT)],     want: "\u{00C9}"),
  Case(name: "grave + a -> a-grave",  keys: [(30, SHIFT), (0, 0)],      want: "\u{00E0}"),
  Case(name: "tilde + a -> a-tilde",  keys: [(42, 0), (0, 0)],          want: "\u{00E3}"),
  Case(name: "tilde + o -> o-tilde",  keys: [(42, 0), (31, 0)],         want: "\u{00F5}"),
  Case(name: "tilde + n -> n-tilde",  keys: [(42, 0), (45, 0)],         want: "\u{00F1}"),
  Case(name: "circ  + e -> e-circ",   keys: [(42, SHIFT), (14, 0)],     want: "\u{00EA}"),
  Case(name: "circ  + o -> o-circ",   keys: [(42, SHIFT), (31, 0)],     want: "\u{00F4}"),
  Case(name: "diaer + u -> u-diaer",  keys: [(33, OPT), (32, 0)],       want: "\u{00FC}"),
  Case(name: "c-cedilla direct",      keys: [(41, 0)],                  want: "\u{00E7}"),
  Case(name: "C-cedilla shifted",     keys: [(41, SHIFT)],              want: "\u{00C7}"),

  // --- dead key + space -> the bare accent ---------------------------------
  Case(name: "acute + space",  keys: [(30, 0), (49, 0)],       want: "\u{00B4}"),
  Case(name: "grave + space",  keys: [(30, SHIFT), (49, 0)],   want: "`"),
  Case(name: "tilde + space",  keys: [(42, 0), (49, 0)],       want: "~"),
  Case(name: "circ  + space",  keys: [(42, SHIFT), (49, 0)],   want: "^"),
  Case(name: "diaer + space",  keys: [(33, OPT), (49, 0)],     want: "\u{00A8}"),

  // --- dead key followed by a letter it does not combine with --------------
  Case(name: "acute + s -> accent then s", keys: [(30, 0), (1, 0)], want: "\u{00B4}s"),

  // --- literal tilde / caret / backtick without needing space --------------
  Case(name: "Opt tilde key -> ~",        keys: [(42, OPT)],         want: "~"),
  Case(name: "Opt+Shift tilde key -> ^",  keys: [(42, OPT|SHIFT)],   want: "^"),
  Case(name: "Opt+Shift acute key -> `",  keys: [(30, OPT|SHIFT)],   want: "`"),

  // --- caps lock: letters uppercase, digits unaffected ---------------------
  Case(name: "caps + a -> A",  keys: [(0, CAPS)],   want: "A"),
  Case(name: "caps + 1 -> 1",  keys: [(18, CAPS)],  want: "1"),
  Case(name: "caps + cedilla", keys: [(41, CAPS)],  want: "\u{00C7}"),

  // --- control keys still work --------------------------------------------
  Case(name: "Return",     keys: [(36, 0)],  want: "\r"),
  Case(name: "Tab",        keys: [(48, 0)],  want: "\t"),
  Case(name: "Space",      keys: [(49, 0)],  want: " "),
]

let LAYOUT_NAME = "Portuguese PC (KD201)"

// Match the name exactly. macOS keeps stale input-source entries around for
// layouts that have been renamed or deleted until the next logout, so a
// substring match can silently test a ghost instead of the installed file.
func findLayout(named target: String) -> Data? {
  let list = TISCreateInputSourceList(nil, true)!.takeRetainedValue() as! [TISInputSource]
  for src in list {
    guard let np = TISGetInputSourceProperty(src, kTISPropertyLocalizedName) else { continue }
    let name = Unmanaged<CFString>.fromOpaque(np).takeUnretainedValue() as String
    guard name == target else { continue }
    guard let p = TISGetInputSourceProperty(src, kTISPropertyUnicodeKeyLayoutData) else { continue }
    return (Unmanaged<CFData>.fromOpaque(p).takeUnretainedValue() as Data)
  }
  return nil
}

guard let data = findLayout(named: LAYOUT_NAME) else {
  print("FAIL: layout '\(LAYOUT_NAME)' not found. Is it installed in ~/Library/Keyboard Layouts/ ?")
  exit(2)
}

var passed = 0, failed = 0

data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
  let layout = raw.bindMemory(to: UCKeyboardLayout.self).baseAddress!
  let kbd = UInt32(LMGetKbdType())

  for c in cases {
    var deadState: UInt32 = 0
    var got = ""
    for (kc, mods) in c.keys {
      var len = 0
      var chars = [UniChar](repeating: 0, count: 16)
      let err = UCKeyTranslate(layout, UInt16(kc), UInt16(kUCKeyActionDown), mods,
                               kbd, 0, &deadState, 16, &len, &chars)
      if err == noErr && len > 0 {
        got += String(utf16CodeUnits: chars, count: len)
      }
    }
    if got == c.want {
      passed += 1
    } else {
      failed += 1
      let show = { (s: String) in s.unicodeScalars
        .map { $0.value < 0x20 ? "\\x\(String($0.value, radix: 16))" : String($0) }.joined() }
      print("FAIL  \(c.name):  want [\(show(c.want))]  got [\(show(got))]")
    }
  }
}

print("\n\(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
