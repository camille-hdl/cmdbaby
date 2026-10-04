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
public final class AdultExitRecognizer: @unchecked Sendable {
  public static let passphraseWindow: TimeInterval = 5

  private let settings: AdultExitSettings
  private let clock: any MonotonicClock
  private var target: [Character] { Array(settings.passphrase.value) }
  private var buffer: [Character] = []
  private var bufferStartedAt: TimeInterval?
  private var failsafeCount = 0
  private var failsafeWindowStart: TimeInterval?

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
    letter: Character?,
    isReturn: Bool,
    isEscape: Bool = false,
    shiftDown: Bool = false
  ) -> AdultExitKind? {
    if isEscape && shiftDown {
      clearBuffer()
      return settings.enabledMethods.contains(.shiftEscape) ? .shiftEscape : nil
    }
    if isEscape {
      clearBuffer()
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

    guard let letter, let scalar = letter.lowercased().unicodeScalars.first,
      CharacterSet.letters.contains(scalar)
    else {
      clearBuffer()
      return nil
    }

    let character = Character(scalar)
    if buffer.isEmpty {
      bufferStartedAt = now
    } else if !isBufferInsideWindow(now) {
      buffer = []
      bufferStartedAt = now
    }

    buffer.append(character)
    if !target.starts(with: buffer) {
      clearBuffer()
    }
    return nil
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
