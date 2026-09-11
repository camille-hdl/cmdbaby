import ApplicationServices
import BabyWorkDiagnosticsKit
import CoreGraphics
import Foundation
import OSLog

/// Filtre de session Quartz : thread dédié, callback borné, aucune journalisation de frappe.
final class SessionInputFilter: @unchecked Sendable {
  private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "fr.camille.babywork.diagnostics",
    category: "InputFilter"
  )

  private let stateLock = NSLock()
  private var thread: Thread?
  private var runLoop: CFRunLoop?
  private var tapPort: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var suppressedCounts: [MonitoredShortcut: Int] = [:]

  private let onStatusChange: @Sendable (InputFilterStatus) -> Void
  private let onCountsChange: @Sendable ([MonitoredShortcut: Int]) -> Void

  init(
    onStatusChange: @escaping @Sendable (InputFilterStatus) -> Void,
    onCountsChange: @escaping @Sendable ([MonitoredShortcut: Int]) -> Void
  ) {
    self.onStatusChange = onStatusChange
    self.onCountsChange = onCountsChange
  }

  func start() {
    stateLock.lock()
    let alreadyRunning = thread != nil
    stateLock.unlock()
    guard !alreadyRunning else { return }

    onStatusChange(.starting)
    resetCounts()

    let thread = Thread { [weak self] in
      self?.runTapThread()
    }
    thread.name = "fr.camille.babywork.diagnostics.input-filter"
    thread.qualityOfService = .userInteractive

    stateLock.lock()
    self.thread = thread
    stateLock.unlock()

    thread.start()
  }

  func stop() {
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

    stateLock.lock()
    thread = nil
    runLoop = nil
    if let source = runLoopSource {
      if let loop {
        CFRunLoopRemoveSource(loop, source, .commonModes)
      }
      runLoopSource = nil
    }
    tapPort = nil
    stateLock.unlock()

    onStatusChange(.inactive)
  }

  func reenableTapIfPossible() {
    stateLock.lock()
    let port = tapPort
    stateLock.unlock()
    guard let port else { return }
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

    guard
      let port = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: mask,
        callback: callback,
        userInfo: Unmanaged.passUnretained(self).toOpaque()
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
    if type == .tapDisabledByTimeout {
      logger.warning("Filtre désactivé par dépassement de délai")
      onStatusChange(.disabledByTimeout)
      return Unmanaged.passUnretained(event)
    }
    if type == .tapDisabledByUserInput {
      logger.warning("Filtre désactivé par intervention utilisateur/système")
      onStatusChange(.disabledByUserInput)
      return Unmanaged.passUnretained(event)
    }

    // Ne classer que keyDown pour la suppression ; absorber aussi keyUp du même code
    // afin d’éviter des états de touche incohérents, sans jamais lire le caractère.
    guard type == .keyDown || type == .keyUp else {
      return Unmanaged.passUnretained(event)
    }

    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
    let modifiers = InputModifierMask(cgEventFlags: event.flags)
    let decision = ShortcutSuppressionPolicy.decision(keyCode: keyCode, modifiers: modifiers)

    switch decision {
    case .allow:
      return Unmanaged.passUnretained(event)
    case .suppress(let shortcut):
      if type == .keyDown {
        recordSuppression(of: shortcut)
      }
      return nil
    }
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

  private static func creationFailureReason() -> String {
    let inputMonitoring = CGPreflightListenEventAccess()
    let accessibility = AXIsProcessTrusted()
    switch (inputMonitoring, accessibility) {
    case (false, false):
      return "permissions Surveillance de l’entrée et Accessibilité manquantes"
    case (false, true):
      return "permission Surveillance de l’entrée manquante"
    case (true, false):
      return "permission Accessibilité manquante"
    case (true, true):
      return "tap de session refusé malgré les pré-vérifications"
    }
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
