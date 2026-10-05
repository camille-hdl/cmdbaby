import Carbon
import Foundation

/// Lettres de la disposition active, calculées hors du callback du tap.
/// TIS/HIToolbox n’est pas sûr sur le thread du CGEventTap (dispatch_assert_queue).
final class KeyboardLayoutLetter: @unchecked Sendable {
  static let shared = KeyboardLayoutLetter()

  /// Postée sur le fil principal à la fin de `refreshFromCurrentLayout()`.
  static let didChangeNotification = Notification.Name(
    "fr.camille.babywork.keyboardLayoutLetterDidChange"
  )

  private let lock = NSLock()
  private var letters: [UInt16: Character] = [:]
  private(set) var layoutName: String?

  private init() {}

  func fromKeyCode(_ keyCode: UInt16) -> Character? {
    lock.lock()
    defer { lock.unlock() }
    return letters[keyCode]
  }

  /// Table keycode → lettres, lue sous le verrou.
  func snapshot() -> [UInt16: Set<Character>] {
    lock.lock()
    defer { lock.unlock() }
    return letters.mapValues { [$0] }
  }

  @MainActor
  func refreshFromCurrentLayout() {
    defer {
      NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
    guard let inputSource = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else {
      return
    }
    layoutName = localizedName(of: inputSource)
    guard
      let rawLayout = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData)
    else {
      replaceLetters([:])
      return
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

    replaceLetters(map)
  }

  private func replaceLetters(_ map: [UInt16: Character]) {
    lock.lock()
    letters = map
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
