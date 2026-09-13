import AppKit
import BabyWorkDiagnosticsKit
import QuartzCore

/// État live du kiosque, affiché sur les couvertures. Aucune persistance.
final class KioskHUD: @unchecked Sendable {
  private let lock = NSLock()
  private var source = "—"
  private var lastKey = "—"
  private var sequence = "0/6"
  private var failsafeClicks = "0/5"
  private var mouseSeen = 0
  private var shifts = "—"
  private var tap = "—"
  private var exit = "—"
  private var handlers: [@Sendable (String) -> Void] = []

  func resetHandlers() {
    lock.lock()
    handlers.removeAll(keepingCapacity: false)
    lock.unlock()
  }

  func addHandler(_ handler: @escaping @Sendable (String) -> Void) {
    lock.lock()
    handlers.append(handler)
    let text = renderLocked()
    lock.unlock()
    publish(text, handlers: [handler])
  }

  func noteWindowKey(letter: Character?, isReturn: Bool, isEscape: Bool = false, filled: Int, target: Int) {
    lock.lock()
    source = "fenêtre keyDown"
    if isEscape {
      lastKey = "Échap"
    } else if isReturn {
      lastKey = "Entrée"
    } else {
      lastKey = letter.map(String.init) ?? "(non lettre)"
    }
    sequence = "\(filled)/\(target)"
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  func noteFilterKey(letter: Character?, isReturn: Bool, isEscape: Bool = false, filled: Int, target: Int) {
    lock.lock()
    source = "filtre tap"
    if isEscape {
      lastKey = "Échap"
    } else if isReturn {
      lastKey = "Entrée"
    } else {
      lastKey = letter.map(String.init) ?? "(non lettre)"
    }
    sequence = "\(filled)/\(target)"
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  func noteFailsafeClick(count: Int) {
    lock.lock()
    source = "carré secours"
    failsafeClicks = "\(min(count, 5))/5"
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  func noteBackgroundClick() {
    lock.lock()
    mouseSeen += 1
    source = "clic couverture"
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  func noteShifts(left: Bool, right: Bool, origin: String) {
    lock.lock()
    source = origin
    switch (left, right) {
    case (true, true):
      shifts = "gauche+droite"
    case (true, false):
      shifts = "gauche"
    case (false, true):
      shifts = "droite"
    case (false, false):
      shifts = "—"
    }
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  func noteTap(_ status: String) {
    lock.lock()
    tap = status
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  func noteExit(_ kind: AdultExitKind) {
    lock.lock()
    switch kind {
    case .passphrase:
      exit = "demandée : parent+Entrée"
    case .shiftEscape:
      exit = "demandée : Majuscule-Échap"
    case .failsafeClick:
      exit = "demandée : 5 clics"
    }
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  func noteTeardown(hiddenWindows: Int) {
    lock.lock()
    if hiddenWindows < 0 {
      exit = "arrêt : filtre coupé, présentation restaurée"
    } else {
      exit = "démontage : \(hiddenWindows) fenêtre(s)"
    }
    let text = renderLocked()
    let handlers = handlers
    lock.unlock()
    publish(text, handlers: handlers)
  }

  private func renderLocked() -> String {
    """
    source     \(source)
    touche     \(lastKey)
    séquence   \(sequence)
    clics      \(failsafeClicks)
    souris     \(mouseSeen)
    maj        \(shifts)
    tap        \(tap)
    sortie     \(exit)
    """
  }

  private func publish(_ text: String, handlers: [@Sendable (String) -> Void]) {
    let apply: @Sendable () -> Void = {
      for handler in handlers {
        handler(text)
      }
    }
    if Thread.isMainThread {
      apply()
    } else {
      DispatchQueue.main.async(execute: apply)
    }
  }
}

/// Une fenêtre sans bordure par `NSScreen` vivant, jamais une fenêtre géante ni une liste mise en cache.
@MainActor
final class CoverWindowCoordinator {
  var onAdultExit: (@Sendable (AdultExitKind) -> Void)?
  var hud = KioskHUD()
  var store = CoverWindowStore()
  private var windows: [NSWindow] = []
  private var inputBridge: KioskInputBridge?
  private var playDirector: GalaxyDirector?

  func createCoverWindows() throws -> [ScreenDescriptor] {
    closeCoverWindows()
    let screens = NSScreen.screens
    guard !screens.isEmpty else { throw KioskSessionError.noScreens }

    activateApp()
    let exitHandler = onAdultExit
    let hud = self.hud
    let director = GalaxyDirector()
    let bridge = KioskInputBridge(hud: hud) { kind in
      hud.noteExit(kind)
      exitHandler?(kind)
    }
    inputBridge = bridge
    playDirector = director

    var descriptors: [ScreenDescriptor] = []
    for (index, screen) in screens.enumerated() {
      let descriptor = ScreenDescriptor(nsScreen: screen)
      let window = CoverWindow(
        screen: screen,
        descriptor: descriptor,
        colorIndex: index,
        inputBridge: bridge,
        director: director
      )
      windows.append(window)
      window.orderFrontRegardless()
      descriptors.append(descriptor)
    }
    store.replaceWindows(windows)
    refocus()
    return descriptors
  }

  func refocus() {
    activateApp()
    guard let first = windows.first else { return }
    first.makeKey()
    first.makeFirstResponder(first.contentView)
  }

  func closeCoverWindows() {
    _ = store.closeAll()
    windows.removeAll(keepingCapacity: false)
    inputBridge = nil
    playDirector?.reset()
    playDirector = nil
    hud.resetHandlers()
  }

  private func activateApp() {
    if #available(macOS 14, *) {
      NSApp.activate()
    } else {
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}

/// Reconnaissance des sorties depuis les callbacks AppKit (hors exécuteur MainActor).
final class KioskInputBridge: @unchecked Sendable {
  private let lock = NSLock()
  private let recognizer = AdultExitRecognizer()
  private let clickCounter = FailsafeClickCounter()
  private let hud: KioskHUD
  private let onExit: @Sendable (AdultExitKind) -> Void

  init(hud: KioskHUD, onExit: @escaping @Sendable (AdultExitKind) -> Void) {
    self.hud = hud
    self.onExit = onExit
  }

  func noteKeyDown(letter: Character?, isReturn: Bool, isEscape: Bool, shiftDown: Bool) {
    lock.lock()
    let kind = recognizer.handleKeyDown(
      letter: letter,
      isReturn: isReturn,
      isEscape: isEscape,
      shiftDown: shiftDown
    )
    let filled = recognizer.prefixLength
    let target = recognizer.prefixTarget
    lock.unlock()
    hud.noteWindowKey(
      letter: letter,
      isReturn: isReturn,
      isEscape: isEscape,
      filled: filled,
      target: target
    )
    if let kind {
      onExit(kind)
    }
  }

  func noteShifts(left: Bool, right: Bool) {
    hud.noteShifts(left: left, right: right, origin: "fenêtre flagsChanged")
  }

  func noteFailsafeClick() {
    let result = clickCounter.register()
    hud.noteFailsafeClick(count: result.count)
    if result.triggered {
      onExit(.failsafeClick)
    }
  }

  func noteBackgroundClick() {
    hud.noteBackgroundClick()
  }
}

private final class CoverWindow: NSWindow {
  private let inputBridge: KioskInputBridge

  /// AppKit appelle ces accesseurs depuis la runloop, hors de l’exécuteur MainActor Swift.
  nonisolated override var canBecomeKey: Bool { true }
  nonisolated override var canBecomeMain: Bool { true }

  init(
    screen: NSScreen,
    descriptor: ScreenDescriptor,
    colorIndex: Int,
    inputBridge: KioskInputBridge,
    director: GalaxyDirector
  ) {
    self.inputBridge = inputBridge
    super.init(
      contentRect: screen.frame,
      styleMask: .borderless,
      backing: .buffered,
      defer: false
    )
    setFrame(screen.frame, display: true)
    isOpaque = true
    hasShadow = false
    isMovable = false
    isRestorable = false
    backgroundColor = CoverPalette.color(at: colorIndex)
    collectionBehavior = [
      .canJoinAllSpaces,
      .fullScreenAuxiliary,
      .stationary,
      .ignoresCycle,
    ]
    level = .screenSaver
    ignoresMouseEvents = false
    tabbingMode = .disallowed
    animationBehavior = .none
    acceptsMouseMovedEvents = true
    identifier = NSUserInterfaceItemIdentifier("fr.camille.babywork.cover.\(descriptor.id)")
    contentView = GalaxyStageView(
      background: CoverPalette.color(at: colorIndex),
      inputBridge: inputBridge,
      director: director,
      scale: screen.backingScaleFactor
    )
    isReleasedWhenClosed = false
  }

  nonisolated override func flagsChanged(with event: NSEvent) {
    let left = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(0x38))
    let right = CGEventSource.keyState(.hidSystemState, key: CGKeyCode(0x3C))
    inputBridge.noteShifts(left: left, right: right)
  }

  nonisolated override func performKeyEquivalent(with event: NSEvent) -> Bool {
    event.modifierFlags.contains(.command)
  }
}

private enum CoverPalette {
  private static let colors: [NSColor] = [
    NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.18, alpha: 1),
    NSColor(calibratedRed: 0.12, green: 0.04, blue: 0.20, alpha: 1),
    NSColor(calibratedRed: 0.03, green: 0.14, blue: 0.18, alpha: 1),
  ]

  static func color(at index: Int) -> NSColor {
    colors[index % colors.count]
  }
}

/// Cinq clics dans une fenêtre de 3 s, sans journaliser le rythme.
private final class FailsafeClickCounter: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0
  private var windowStart: TimeInterval?

  func register() -> (count: Int, triggered: Bool) {
    lock.lock()
    defer { lock.unlock() }
    let now = ProcessInfo.processInfo.systemUptime
    if let start = windowStart, now - start <= 3 {
      count += 1
    } else {
      windowStart = now
      count = 1
    }
    return (count, count >= 5)
  }
}

final class FailsafeClickView: NSView {
  private let inputBridge: KioskInputBridge

  init(inputBridge: KioskInputBridge) {
    self.inputBridge = inputBridge
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
    layer?.cornerRadius = 6
    setAccessibilityLabel("Sortie de secours")
    setAccessibilityRole(.button)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) n’est pas supporté")
  }

  nonisolated override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  nonisolated override func mouseDown(with event: NSEvent) {
    inputBridge.noteFailsafeClick()
  }
}

extension ScreenDescriptor {
  init(nsScreen: NSScreen) {
    let number = nsScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
    let identifier = number.map { String($0.uint32Value) } ?? nsScreen.localizedName
    self.init(
      id: identifier,
      name: nsScreen.localizedName,
      originX: nsScreen.frame.origin.x,
      originY: nsScreen.frame.origin.y,
      width: nsScreen.frame.size.width,
      height: nsScreen.frame.size.height,
      scale: nsScreen.backingScaleFactor,
      isMain: nsScreen === NSScreen.main
    )
  }
}
