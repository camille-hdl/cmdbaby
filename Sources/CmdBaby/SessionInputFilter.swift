import AppKit
import ApplicationServices
import CmdBabyKit
import CoreGraphics
import Foundation

/// Filtre de session Quartz : thread dédié, callback borné, aucune journalisation de frappe.
/// Un filtre par session : après `stop()`, il ne redémarre pas.
final class SessionInputFilter: @unchecked Sendable {
  private let log = LifecycleLogRecorder.shared

  private let stateLock = NSLock()
  private var thread: Thread?
  private var runLoop: CFRunLoop?
  private var tapPort: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var lifecycle = TapLifecycle()
  private let killSwitch = SessionInputKillSwitch()
  private var suppressedCounts: [MonitoredShortcut: Int] = [:]
  private let exitRecognizer: AdultExitRecognizer

  private let onStatusChange: @Sendable (InputFilterStatus) -> Void
  private let onCountsChange: @Sendable ([MonitoredShortcut: Int]) -> Void
  private let onAdultExit: @Sendable (AdultExitKind) -> Void

  init(
    onStatusChange: @escaping @Sendable (InputFilterStatus) -> Void,
    onCountsChange: @escaping @Sendable ([MonitoredShortcut: Int]) -> Void,
    onAdultExit: @escaping @Sendable (AdultExitKind) -> Void,
    exits: AdultExitSettings
  ) {
    self.exitRecognizer = AdultExitRecognizer(settings: exits)
    self.onStatusChange = onStatusChange
    self.onCountsChange = onCountsChange
    self.onAdultExit = onAdultExit
  }

  func start() {
    stateLock.lock()
    let alreadyRunning = thread != nil
    stateLock.unlock()
    guard !alreadyRunning else { return }

    killSwitch.reset()
    onStatusChange(.starting)
    resetCounts()
    exitRecognizer.reset()

    if !AXIsProcessTrusted() {
      Self.promptForAccessibilityTrust()
    }

    let thread = Thread { [weak self] in
      self?.runTapThread()
    }
    thread.name = "\(AppIdentity.bundleIdentifier).input-filter"
    thread.qualityOfService = .userInteractive

    stateLock.lock()
    self.thread = thread
    stateLock.unlock()

    thread.start()
  }

  /// Sûr à tout moment, même avant que le thread du tap ait créé son port.
  func stop() {
    killSwitch.engage()
    stateLock.lock()
    let onStop = lifecycle.requestStop()
    let loop = runLoop
    let port = tapPort
    stateLock.unlock()

    if onStop == .disableAndStopLoop, let port, let loop {
      CGEvent.tapEnable(tap: port, enable: false)
      log.emit(.tapDisable(reason: "stop"))
      // Le bloc s’exécute dès que la boucle tourne, même si elle n’a pas encore démarré.
      CFRunLoopPerformBlock(loop, CFRunLoopMode.commonModes.rawValue) {
        CFRunLoopStop(loop)
      }
      CFRunLoopWakeUp(loop)
    }
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
    if killSwitch.isEngaged { return }
    CGEvent.tapEnable(tap: port, enable: true)
    onStatusChange(.active)
    log.emit(.tapReenable(reason: "requested"))
  }

  private func runTapThread() {
    let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
      | CGEventMask(1 << CGEventType.keyUp.rawValue)
      | CGEventMask(1 << CGEventType.flagsChanged.rawValue)
      | CGEventMask(1 << Self.systemDefinedEventType)
    // tapDisabledByTimeout et tapDisabledByUserInput arrivent sans être dans le masque.

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
      log.emit(.tapFail(reason: "creation"))
      onStatusChange(.failed(reason))
      stateLock.lock()
      thread = nil
      stateLock.unlock()
      return
    }

    log.emit(.tapCreate)
    let loop = CFRunLoopGetCurrent()
    let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)

    // Sous le verrou : `stop()` voit soit aucun port, soit un tap actif et sa boucle.
    stateLock.lock()
    let afterCreation = lifecycle.portCreated()
    if afterCreation == .enable {
      CFRunLoopAddSource(loop, source, .commonModes)
      CGEvent.tapEnable(tap: port, enable: true)
      tapPort = port
      runLoopSource = source
      runLoop = loop
    }
    stateLock.unlock()

    guard afterCreation == .enable else {
      CFMachPortInvalidate(port)
      log.emit(.tapDisable(reason: "stoppedBeforeEnable"))
      stateLock.lock()
      thread = nil
      stateLock.unlock()
      return
    }

    onStatusChange(.active)
    log.emit(.tapEnable)
    CFRunLoopRun()

    CGEvent.tapEnable(tap: port, enable: false)
    CFRunLoopRemoveSource(loop, source, .commonModes)
    CFMachPortInvalidate(port)
    stateLock.lock()
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
    if killSwitch.isEngaged {
      return Unmanaged.passUnretained(event)
    }

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
      let reason = type == .tapDisabledByTimeout ? "timeout" : "userInput"
      log.emit(.tapDisable(reason: reason))
      stateLock.lock()
      let port = tapPort
      stateLock.unlock()
      if let port {
        CGEvent.tapEnable(tap: port, enable: true)
      }
      onStatusChange(.active)
      log.emit(.tapReenable(reason: reason))
      return Unmanaged.passUnretained(event)
    }

    if type == .flagsChanged {
      let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
      let decision = ShortcutSuppressionPolicy.flagsChangedDecision(keyCode: keyCode)
      return absorbing(event, decision, record: event.flags.contains(.maskSecondaryFn))
    }

    if type.rawValue == Self.systemDefinedEventType {
      let subtype = NSEvent(cgEvent: event).map { Int($0.subtype.rawValue) }
      guard let subtype else { return Unmanaged.passUnretained(event) }
      let decision = ShortcutSuppressionPolicy.systemDefinedDecision(subtype: subtype)
      return absorbing(event, decision, record: true)
    }

    guard type == .keyDown || type == .keyUp else {
      return Unmanaged.passUnretained(event)
    }

    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    let modifiers = InputModifierMask(cgEventFlags: event.flags)
    let cached = KeyboardLayoutLetter.shared.letters(for: keyCode)
    let letters = letterFromEvent(event, cached: cached.merged)
    let shown = cached.active ?? unicodeLetter(from: event)
    let isReturn = keyCode == 0x24 || keyCode == 0x4C
    let isEscape = keyCode == 0x35
    let shiftDown = modifiers.contains(.shift)

    if type == .keyDown {
      let distinguishing = modifiers.intersection(.distinguishing)
      let lettersForPhrase = distinguishing.isEmpty ? letters : []
      let kind = exitRecognizer.handleKeyDown(
        letters: lettersForPhrase,
        isReturn: isReturn && distinguishing.subtracting(.shift).isEmpty,
        isEscape: isEscape,
        shiftDown: shiftDown
      )
      if let kind {
        killSwitch.engage()
        onAdultExit(kind)
        return Unmanaged.passUnretained(event)
      }
    }

    let decision = ShortcutSuppressionPolicy.decision(
      keyCode: keyCode,
      modifiers: modifiers,
      letter: shown
    )
    if type == .keyDown, case .suppress(let shortcut) = decision {
      recordSuppression(of: shortcut)
      return nil
    }
    // Les lettres ordinaires arrivent aux fenêtres de couverture, qui reconnaissent aussi la sortie.
    return Unmanaged.passUnretained(event)
  }

  /// `NX_SYSDEFINED` : touches média, luminosité, volume, Spotlight, Dictée…
  private static let systemDefinedEventType: UInt32 = 14

  private func absorbing(
    _ event: CGEvent,
    _ decision: InputFilterDecision,
    record: Bool
  ) -> Unmanaged<CGEvent>? {
    guard case .suppress(let shortcut) = decision else {
      return Unmanaged.passUnretained(event)
    }
    if record {
      recordSuppression(of: shortcut)
    }
    return nil
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

  private func letterFromEvent(_ event: CGEvent, cached: Set<Character>) -> Set<Character> {
    if !cached.isEmpty {
      return cached
    }
    if let fallback = unicodeLetter(from: event) {
      return [fallback]
    }
    return []
  }

  private func unicodeLetter(from event: CGEvent) -> Character? {
    var length = 0
    var chars = [UniChar](repeating: 0, count: 4)
    event.keyboardGetUnicodeString(
      maxStringLength: 4,
      actualStringLength: &length,
      unicodeString: &chars
    )
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
