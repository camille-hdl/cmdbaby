import ApplicationServices
import BabyWorkDiagnosticsKit
import CoreGraphics
import Foundation
import OSLog

/// Coupure globale du tap, lisible depuis le callback sans hop MainActor.
final class SessionInputKillSwitch: @unchecked Sendable {
  static let shared = SessionInputKillSwitch()

  private let lock = NSLock()
  private var engaged = false

  func reset() {
    lock.lock()
    engaged = false
    lock.unlock()
  }

  func engage() {
    lock.lock()
    engaged = true
    lock.unlock()
  }

  var isEngaged: Bool {
    lock.lock()
    defer { lock.unlock() }
    return engaged
  }
}

/// Filtre de session Quartz : thread dédié, callback borné, aucune journalisation de frappe.
final class SessionInputFilter: @unchecked Sendable {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "fr.camille.babywork",
    category: "InputFilter"
  )

  private let stateLock = NSLock()
  private var thread: Thread?
  private var runLoop: CFRunLoop?
  private var tapPort: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var suppressedCounts: [MonitoredShortcut: Int] = [:]
  private let exitRecognizer = AdultExitRecognizer()

  private let onStatusChange: @Sendable (InputFilterStatus) -> Void
  private let onCountsChange: @Sendable ([MonitoredShortcut: Int]) -> Void
  private let onAdultExit: @Sendable (AdultExitKind) -> Void
  private let hud: KioskHUD?

  init(
    onStatusChange: @escaping @Sendable (InputFilterStatus) -> Void,
    onCountsChange: @escaping @Sendable ([MonitoredShortcut: Int]) -> Void,
    onAdultExit: @escaping @Sendable (AdultExitKind) -> Void,
    hud: KioskHUD? = nil
  ) {
    self.onStatusChange = onStatusChange
    self.onCountsChange = onCountsChange
    self.onAdultExit = onAdultExit
    self.hud = hud
  }

  func start() {
    stateLock.lock()
    let alreadyRunning = thread != nil
    stateLock.unlock()
    guard !alreadyRunning else { return }

    SessionInputKillSwitch.shared.reset()
    onStatusChange(.starting)
    resetCounts()
    exitRecognizer.reset()

    if !AXIsProcessTrusted() {
      Self.promptForAccessibilityTrust()
    }

    let thread = Thread { [weak self] in
      self?.runTapThread()
    }
    thread.name = "fr.camille.babywork.input-filter"
    thread.qualityOfService = .userInteractive

    stateLock.lock()
    self.thread = thread
    stateLock.unlock()

    thread.start()
  }

  func handles() -> (port: CFMachPort?, loop: CFRunLoop?) {
    stateLock.lock()
    defer { stateLock.unlock() }
    return (tapPort, runLoop)
  }

  func stop() {
    SessionInputKillSwitch.shared.engage()
    stateLock.lock()
    let loop = runLoop
    let port = tapPort
    stateLock.unlock()

    if let port {
      CGEvent.tapEnable(tap: port, enable: false)
    }
    if let loop {
      CFRunLoopStop(loop)
    }
    hud?.noteTap("arrêté")
    onStatusChange(.inactive)
  }

  func isTapEnabled() -> Bool {
    stateLock.lock()
    let port = tapPort
    stateLock.unlock()
    guard let port else { return false }
    return CGEvent.tapIsEnabled(tap: port)
  }

  func reenableTapIfPossible() {
    stateLock.lock()
    let port = tapPort
    stateLock.unlock()
    guard let port else { return }
    if SessionInputKillSwitch.shared.isEngaged { return }
    CGEvent.tapEnable(tap: port, enable: true)
    onStatusChange(.active)
    logger.info("Réactivation du filtre demandée après désactivation système")
  }

  private func runTapThread() {
    let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
      | CGEventMask(1 << CGEventType.keyUp.rawValue)
      | CGEventMask(1 << CGEventType.flagsChanged.rawValue)
      | CGEventMask(1 << CGEventType.tapDisabledByTimeout.rawValue)
      | CGEventMask(1 << CGEventType.tapDisabledByUserInput.rawValue)

    let callback: CGEventTapCallBack = { proxy, type, event, refcon in
      guard let refcon else {
        return Unmanaged.passUnretained(event)
      }
      let filter = Unmanaged<SessionInputFilter>.fromOpaque(refcon).takeUnretainedValue()
      return filter.handleEvent(proxy: proxy, type: type, event: event)
    }

    let createTap: () -> CFMachPort? = {
      CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: mask,
        callback: callback,
        userInfo: Unmanaged.passUnretained(self).toOpaque()
      )
    }

    guard
      let port = AccessibilityTapCreation.createWithSingleTrustPrompt(
        isProcessTrusted: { AXIsProcessTrusted() },
        // Prompt déjà affiché dans `start()` sur le thread appelant (MainActor).
        promptForTrust: {},
        create: createTap
      )
    else {
      let reason = Self.creationFailureReason()
      logger.error("Création du CGEventTap impossible")
      onStatusChange(.failed(reason))
      stateLock.lock()
      thread = nil
      stateLock.unlock()
      return
    }

    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
    let loop = CFRunLoopGetCurrent()
    CFRunLoopAddSource(loop, source, .commonModes)
    CGEvent.tapEnable(tap: port, enable: true)

    stateLock.lock()
    tapPort = port
    runLoopSource = source
    runLoop = loop
    stateLock.unlock()

    onStatusChange(.active)
    hud?.noteTap("actif")
    logger.info("Filtre de session actif")
    CFRunLoopRun()

    stateLock.lock()
    if let source = runLoopSource {
      CFRunLoopRemoveSource(loop, source, .commonModes)
    }
    tapPort = nil
    runLoopSource = nil
    runLoop = nil
    thread = nil
    stateLock.unlock()
  }

  private func handleEvent(
    proxy _: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent
  ) -> Unmanaged<CGEvent>? {
    if SessionInputKillSwitch.shared.isEngaged {
      return Unmanaged.passUnretained(event)
    }

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      logger.warning("Filtre désactivé (\(String(describing: type))), réactivation")
      hud?.noteTap("désactivé → réactivation")
      stateLock.lock()
      let port = tapPort
      stateLock.unlock()
      if let port {
        CGEvent.tapEnable(tap: port, enable: true)
      }
      hud?.noteTap("actif")
      onStatusChange(.active)
      return Unmanaged.passUnretained(event)
    }

    if type == .flagsChanged {
      let left = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(0x38))
      let right = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(0x3C))
      hud?.noteShifts(left: left, right: right, origin: "filtre flagsChanged")
      return Unmanaged.passUnretained(event)
    }

    guard type == .keyDown || type == .keyUp else {
      return Unmanaged.passUnretained(event)
    }

    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    let modifiers = InputModifierMask(cgEventFlags: event.flags)
    let letter = letterFromEvent(event, keyCode: keyCode)
    let isReturn = keyCode == 0x24 || keyCode == 0x4C
    let isEscape = keyCode == 0x35
    let shiftDown = modifiers.contains(.shift)

    if type == .keyDown {
      let distinguishing = modifiers.intersection(.distinguishing)
      let letterForPhrase = distinguishing.isEmpty ? letter : nil
      let kind = exitRecognizer.handleKeyDown(
        letter: letterForPhrase,
        isReturn: isReturn && distinguishing.subtracting(.shift).isEmpty,
        isEscape: isEscape,
        shiftDown: shiftDown
      )
      hud?.noteFilterKey(
        letter: letter,
        isReturn: isReturn,
        isEscape: isEscape,
        filled: exitRecognizer.prefixLength,
        target: exitRecognizer.prefixTarget
      )
      if let kind {
        SessionInputKillSwitch.shared.engage()
        onAdultExit(kind)
        return Unmanaged.passUnretained(event)
      }
    }

    let decision = ShortcutSuppressionPolicy.decision(
      keyCode: keyCode,
      modifiers: modifiers,
      letter: letter
    )
    if type == .keyDown, case .suppress(let shortcut) = decision {
      recordSuppression(of: shortcut)
      return nil
    }
    // Les lettres ordinaires arrivent aux fenêtres de couverture, qui reconnaissent aussi la sortie.
    return Unmanaged.passUnretained(event)
  }

  private func recordSuppression(of shortcut: MonitoredShortcut) {
    stateLock.lock()
    suppressedCounts[shortcut, default: 0] += 1
    let snapshot = suppressedCounts
    stateLock.unlock()
    onCountsChange(snapshot)
  }

  private func resetCounts() {
    stateLock.lock()
    suppressedCounts = [:]
    stateLock.unlock()
    onCountsChange([:])
  }

  private func letterFromEvent(_ event: CGEvent, keyCode: UInt16) -> Character? {
    if let cached = KeyboardLayoutLetter.shared.fromKeyCode(keyCode) {
      return cached
    }
    var length = 0
    var chars = [UniChar](repeating: 0, count: 4)
    event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &length, unicodeString: &chars)
    guard length > 0 else { return nil }
    let scalar = String(utf16CodeUnits: chars, count: Int(length))
      .lowercased()
      .unicodeScalars
      .first
    guard let scalar, CharacterSet.letters.contains(scalar) else { return nil }
    return Character(scalar)
  }

  private static func promptForAccessibilityTrust() {
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
  }

  private static func creationFailureReason() -> String {
    let inputMonitoring = CGPreflightListenEventAccess()
    let post = CGPreflightPostEventAccess()
    let accessibility = AXIsProcessTrusted()
    if accessibility {
      return "tap de session refusé malgré Accessibilité"
    }
    if inputMonitoring || post {
      return "Accessibilité manquante (le tap actif n’utilise pas Surveillance de l’entrée)"
    }
    return "Accessibilité manquante"
  }
}

extension InputModifierMask {
  init(cgEventFlags flags: CGEventFlags) {
    var mask = InputModifierMask()
    if flags.contains(.maskCommand) { mask.insert(.command) }
    if flags.contains(.maskAlternate) { mask.insert(.option) }
    if flags.contains(.maskControl) { mask.insert(.control) }
    if flags.contains(.maskShift) { mask.insert(.shift) }
    self = mask
  }
}
