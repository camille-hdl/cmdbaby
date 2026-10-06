import CmdBabyKit
import Carbon
import Foundation

/// Lettres de la disposition active, calculées hors du callback du tap.
/// TIS/HIToolbox n’est pas sûr sur le thread du CGEventTap (dispatch_assert_queue).
final class KeyboardLayoutLetter: @unchecked Sendable {
  static let shared = KeyboardLayoutLetter()

  /// Postée sur le fil principal à la fin de `refreshFromCurrentLayout()`.
  static let didChangeNotification = Notification.Name(
    "\(AppIdentity.bundleIdentifier).keyboardLayoutLetterDidChange"
  )

  private let lock = NSLock()
  /// Disposition active fusionnée avec la disposition ASCII : 1 ou 2 lettres par touche.
  private var letters: [UInt16: Set<Character>] = [:]
  /// Disposition active seule, pour le HUD : pas la lettre ASCII en plus.
  private var activeLetters: [UInt16: Character] = [:]
  private(set) var layoutName: String?

  private init() {}

  /// `merged` : disposition active et ASCII. `active` : disposition active seule, pour le HUD.
  func letters(for keyCode: UInt16) -> (merged: Set<Character>, active: Character?) {
    lock.lock()
    defer { lock.unlock() }
    return (letters[keyCode] ?? [], activeLetters[keyCode])
  }

  /// Lettres reconnues pour une frappe de fenêtre, et la lettre unique du HUD.
  func keyDownLetters(keyCode: UInt16, charactersIgnoringModifiers: String) -> (
    letters: Set<Character>, shown: Character?
  ) {
    let cached = letters(for: keyCode)
    let typed = charactersIgnoringModifiers.lowercased().first { $0.isLetter }
    var recognized = cached.merged
    if recognized.isEmpty {
      if let typed { recognized = [typed] }
    } else if let typed, let active = cached.active, typed != active {
      // L’événement prime sur la disposition active, comme avant ; la lettre ASCII reste.
      recognized.remove(active)
      recognized.insert(typed)
    }
    return (recognized, typed ?? cached.active)
  }

  /// Table keycode → lettres, lue sous le verrou.
  func snapshot() -> [UInt16: Set<Character>] {
    lock.lock()
    defer { lock.unlock() }
    return letters
  }

  @MainActor
  func refreshFromCurrentLayout() {
    defer {
      NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
    let inputSource = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue()
    layoutName = inputSource.flatMap { localizedName(of: $0) }
    let active = inputSource.flatMap { unicodeLetters(of: $0) }
    let asciiSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue()
    let ascii = asciiSource.flatMap { unicodeLetters(of: $0) }
    replaceTables(merged: merge(active: active, ascii: ascii), active: active ?? [:])
  }

  private func unicodeLetters(of inputSource: TISInputSource) -> [UInt16: Character]? {
    guard
      let rawLayout = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData)
    else {
      return nil
    }
    let layoutData = Unmanaged<CFData>.fromOpaque(rawLayout).takeUnretainedValue() as Data

    var map: [UInt16: Character] = [:]
    layoutData.withUnsafeBytes { buffer in
      guard let layout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
        return
      }
      for code in UInt16(0)...UInt16(127) {
        if let letter = translate(layout: layout, keyCode: code) {
          map[code] = letter
        }
      }
    }
    return map
  }

  /// Active sans données Unicode → ASCII seule. Aucune des deux → table vide.
  private func merge(
    active: [UInt16: Character]?,
    ascii: [UInt16: Character]?
  ) -> [UInt16: Set<Character>] {
    guard active != nil || ascii != nil else { return [:] }
    var merged: [UInt16: Set<Character>] = [:]
    var codes = Set<UInt16>()
    if let active { codes.formUnion(active.keys) }
    if let ascii { codes.formUnion(ascii.keys) }
    for code in codes {
      var set: Set<Character> = []
      if let letter = active?[code] { set.insert(letter) }
      if let letter = ascii?[code] { set.insert(letter) }
      if !set.isEmpty { merged[code] = set }
    }
    return merged
  }

  private func replaceTables(merged: [UInt16: Set<Character>], active: [UInt16: Character]) {
    lock.lock()
    letters = merged
    activeLetters = active
    lock.unlock()
  }

  private func localizedName(of inputSource: TISInputSource) -> String? {
    guard let rawName = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName) else {
      return nil
    }
    return Unmanaged<CFString>.fromOpaque(rawName).takeUnretainedValue() as String
  }

  private func translate(
    layout: UnsafePointer<UCKeyboardLayout>,
    keyCode: UInt16
  ) -> Character? {
    var deadKeyState: UInt32 = 0
    var chars = [UniChar](repeating: 0, count: 4)
    var actualLength = 0
    let status = UCKeyTranslate(
      layout,
      keyCode,
      UInt16(kUCKeyActionDisplay),
      0,
      UInt32(LMGetKbdType()),
      OptionBits(kUCKeyTranslateNoDeadKeysMask),
      &deadKeyState,
      chars.count,
      &actualLength,
      &chars
    )
    guard status == noErr, actualLength > 0 else { return nil }
    let scalar = String(utf16CodeUnits: chars, count: actualLength)
      .lowercased()
      .unicodeScalars
      .first
    guard let scalar, CharacterSet.letters.contains(scalar) else { return nil }
    return Character(scalar)
  }
}
