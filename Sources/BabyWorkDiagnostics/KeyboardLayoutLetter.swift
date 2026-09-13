import Carbon
import Foundation

/// Lettres de la disposition active, calculées hors du callback du tap.
/// TIS/HIToolbox n’est pas sûr sur le thread du CGEventTap (dispatch_assert_queue).
final class KeyboardLayoutLetter: @unchecked Sendable {
  static let shared = KeyboardLayoutLetter()

  private let lock = NSLock()
  private var letters: [UInt16: Character] = [:]

  private init() {}

  func fromKeyCode(_ keyCode: UInt16) -> Character? {
    lock.lock()
    defer { lock.unlock() }
    return letters[keyCode]
  }

  @MainActor
  func refreshFromCurrentLayout() {
    guard let inputSource = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else {
      return
    }
    guard
      let rawLayout = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData)
    else {
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

    lock.lock()
    letters = map
    lock.unlock()
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
