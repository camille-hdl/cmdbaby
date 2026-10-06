import Foundation

public protocol MonotonicClock: Sendable {
  var now: TimeInterval { get }
}

public struct SystemMonotonicClock: MonotonicClock {
  public init() {}

  public var now: TimeInterval {
    ProcessInfo.processInfo.systemUptime
  }
}

public final class ManualClock: MonotonicClock, @unchecked Sendable {
  public var now: TimeInterval

  public init(now: TimeInterval = 0) {
    self.now = now
  }
}

public enum AdultExitKind: Equatable, Sendable {
  case passphrase
  case shiftEscape
  case failsafeClick
  case timeLimit
}

/// Reconnaît les sorties adultes sans dépendre du rendu et sans journaliser le tampon.
/// Sans verrou : chaque instance reste sur un seul thread (celui du tap, ou le fil principal).
public final class AdultExitRecognizer {
  public static let passphraseWindow: TimeInterval = 5

  private let settings: AdultExitSettings
  private let clock: any MonotonicClock
  private var target: [Character] { Array(settings.passphrase.value) }
  private var buffer: [Character] = []
  private var bufferStartedAt: TimeInterval?
  private var failsafeCount = 0
  private var failsafeWindowStart: TimeInterval?
  private var escapeHoldStartedAt: TimeInterval?

  private static let failsafeClickCount = 5
  private static let failsafeClickWindow: TimeInterval = 3

  public init(
    settings: AdultExitSettings = AdultExitSettings(),
    clock: any MonotonicClock = SystemMonotonicClock()
  ) {
    self.settings = settings
    self.clock = clock
  }

  public func reset() {
    buffer = []
    bufferStartedAt = nil
  }

  /// Vrai pendant un appui Maj-Échap en cours : l’appelant doit appeler `tick()` à l’échéance.
  public var isHoldingShiftEscape: Bool { escapeHoldStartedAt != nil }

  /// `.shiftEscape` quand Maj-Échap est maintenu depuis `AdultExitSettings.shiftEscapeHoldDuration`.
  public func tick() -> AdultExitKind? {
    guard let start = escapeHoldStartedAt,
      clock.now - start >= AdultExitSettings.shiftEscapeHoldDuration
    else {
      return nil
    }
    escapeHoldStartedAt = nil
    return .shiftEscape
  }

  public func handleKeyUp(isEscape: Bool) {
    if isEscape {
      escapeHoldStartedAt = nil
    }
  }

  /// Un modificateur ajouté ou relâché pendant l’appui l’annule : Maj seul, de bout en bout.
  public func handleModifiersChanged(_ modifiers: InputModifierMask) {
    if modifiers != [.shift] {
      escapeHoldStartedAt = nil
    }
  }

  public var prefixLength: Int { buffer.count }
  public var prefixTarget: Int {
    settings.enabledMethods.contains(.passphrase) ? target.count : 0
  }

  public func handleFailsafeClick() -> (count: Int, exit: AdultExitKind?) {
    guard settings.enabledMethods.contains(.failsafeClick) else {
      return (0, nil)
    }
    let now = clock.now
    if let start = failsafeWindowStart, now - start <= Self.failsafeClickWindow {
      failsafeCount += 1
    } else {
      failsafeWindowStart = now
      failsafeCount = 1
    }
    let exit: AdultExitKind? = failsafeCount >= Self.failsafeClickCount ? .failsafeClick : nil
    return (failsafeCount, exit)
  }

  public func handleKeyDown(
    letters: Set<Character>,
    isReturn: Bool,
    isEscape: Bool = false,
    modifiers: InputModifierMask = []
  ) -> AdultExitKind? {
    if isEscape {
      clearBuffer()
      holdEscape(modifiers: modifiers)
      return nil
    }

    guard settings.enabledMethods.contains(.passphrase) else {
      return nil
    }

    let now = clock.now
    if isReturn {
      let matches = buffer == target && isBufferInsideWindow(now)
      clearBuffer()
      return matches ? .passphrase : nil
    }

    let candidates = Set(letters.compactMap(passphraseLetter))
    guard !candidates.isEmpty else {
      clearBuffer()
      return nil
    }

    if buffer.isEmpty {
      bufferStartedAt = now
    } else if !isBufferInsideWindow(now) {
      buffer = []
      bufferStartedAt = now
    }

    guard buffer.count < target.count else {
      clearBuffer()
      return nil
    }
    let expected = target[buffer.count]
    guard candidates.contains(expected) else {
      clearBuffer()
      return nil
    }
    buffer.append(expected)
    return nil
  }

  /// Les répétitions automatiques d’Échap ne relancent pas un appui en cours.
  private func holdEscape(modifiers: InputModifierMask) {
    guard settings.enabledMethods.contains(.shiftEscape), modifiers == [.shift] else {
      escapeHoldStartedAt = nil
      return
    }
    if escapeHoldStartedAt == nil {
      escapeHoldStartedAt = clock.now
    }
  }

  private func passphraseLetter(_ letter: Character) -> Character? {
    guard let scalar = letter.lowercased().unicodeScalars.first,
      CharacterSet.letters.contains(scalar)
    else {
      return nil
    }
    return Character(scalar)
  }

  private func isBufferInsideWindow(_ now: TimeInterval) -> Bool {
    guard let start = bufferStartedAt else { return false }
    return now - start <= Self.passphraseWindow
  }

  private func clearBuffer() {
    buffer = []
    bufferStartedAt = nil
  }
}
