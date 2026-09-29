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
    case .timeLimit:
      exit = "demandée : minuteur"
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
  private var playSession: PlaySession?
  private var timeLimit: SessionTimeLimit?
  private var outlineViews: [FailsafeClickView] = []
  private var outlineTimer: Timer?

  func createCoverWindows() throws -> [ScreenDescriptor] {
    closeCoverWindows()
    let screens = NSScreen.screens
    guard !screens.isEmpty else { throw KioskSessionError.noScreens }

    activateApp()
    let exitHandler = onAdultExit
    let hud = self.hud
    let configuration = BabyWorksConfigurationStore().load()
    let session = PlaySession.make(configuration.mode)
    let bridge = KioskInputBridge(hud: hud) { kind in
      hud.noteExit(kind)
      exitHandler?(kind)
    }
    inputBridge = bridge
    playSession = session

    var descriptors: [ScreenDescriptor] = []
    var outlines: [FailsafeClickView] = []
    for (index, screen) in screens.enumerated() {
      let descriptor = ScreenDescriptor(nsScreen: screen)
      let failsafe = FailsafeClickView(inputBridge: bridge)
      outlines.append(failsafe)
      let window = CoverWindow(
        screen: screen,
        descriptor: descriptor,
        background: session.windowBackground(colorIndex: index),
        inputBridge: bridge,
        contentView: session.makeContentView(
          inputBridge: bridge,
          colorIndex: index,
          scale: screen.backingScaleFactor,
          failsafe: failsafe
        )
      )
      windows.append(window)
      window.orderFrontRegardless()
      descriptors.append(descriptor)
    }
    outlineViews = outlines
    store.replaceWindows(windows)
    refocus()
    startOutlineClock()
    return descriptors
  }

  func refocus() {
    activateApp()
    guard let first = windows.first else { return }
    first.makeKey()
    let responder = first.contentView.flatMap { content in
      content.subviews.first { $0.acceptsFirstResponder } ?? content
    }
    first.makeFirstResponder(responder)
  }

  func closeCoverWindows() {
    stopOutlineClock()
    let remaining = windows
    windows.removeAll(keepingCapacity: false)
    for window in remaining {
      guard window.isVisible else { continue }
      window.contentView = nil
    }
    _ = store.closeAll()
    inputBridge = nil
    playSession?.reset()
    playSession = nil
    OceanSprite.purge()
    hud.resetHandlers()
  }

  private func startOutlineClock() {
    let limit = SessionTimeLimit(startedAt: ProcessInfo.processInfo.systemUptime)
    timeLimit = limit
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
      // Le timer du run loop est sur le fil principal, pas sur l’exécuteur MainActor.
      Task { @MainActor in
        self?.advanceOutlineClock()
      }
    }
    RunLoop.main.add(timer, forMode: .common)
    outlineTimer = timer
    advanceOutlineClock()
  }

  private func stopOutlineClock() {
    outlineTimer?.invalidate()
    outlineTimer = nil
    timeLimit = nil
    outlineViews.removeAll()
  }

  private func advanceOutlineClock() {
    guard let timeLimit else { return }
    let now = ProcessInfo.processInfo.systemUptime
    let progress = timeLimit.progress(at: now)
    for view in outlineViews {
      view.setOutlineProgress(progress)
    }
    guard timeLimit.isComplete(at: now) else { return }
    self.timeLimit = nil
    outlineTimer?.invalidate()
    outlineTimer = nil
    hud.noteExit(.timeLimit)
    onAdultExit?(.timeLimit)
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

@MainActor
private enum PlaySession {
  case ocean(OceanDirector)
  case galaxy(GalaxyDirector)

  static func make(_ mode: KioskPlayModeID) -> PlaySession {
    switch mode {
    case .ocean:
      .ocean(OceanDirector())
    case .galaxy:
      .galaxy(GalaxyDirector())
    }
  }

  func reset() {
    switch self {
    case .ocean(let director):
      director.reset()
    case .galaxy(let director):
      director.reset()
    }
  }

  func windowBackground(colorIndex: Int) -> NSColor {
    switch self {
    case .ocean:
      OceanStageView.waterColor
    case .galaxy:
      CoverPalette.color(at: colorIndex)
    }
  }

  func makeContentView(
    inputBridge: KioskInputBridge,
    colorIndex: Int,
    scale: CGFloat,
    failsafe: FailsafeClickView
  ) -> NSView {
    let stage: NSView
    switch self {
    case .ocean(let director):
      stage = OceanStageView(inputBridge: inputBridge, director: director, scale: scale)
    case .galaxy(let director):
      stage = GalaxyStageView(
        background: CoverPalette.color(at: colorIndex),
        inputBridge: inputBridge,
        director: director,
        scale: scale
      )
    }
    return PlayStageHost(stage: stage, failsafe: failsafe)
  }
}

/// Scène de jeu en dessous, carré de secours au-dessus. Les calques du mode (sol, poissons, glyphes) restent dans la scène.
private final class PlayStageHost: NSView {
  init(stage: NSView, failsafe: FailsafeClickView) {
    super.init(frame: .zero)
    wantsLayer = true
    stage.translatesAutoresizingMaskIntoConstraints = false
    stage.layer?.masksToBounds = true
    addSubview(stage)

    failsafe.translatesAutoresizingMaskIntoConstraints = false
    addSubview(failsafe)

    NSLayoutConstraint.activate([
      stage.leadingAnchor.constraint(equalTo: leadingAnchor),
      stage.trailingAnchor.constraint(equalTo: trailingAnchor),
      stage.topAnchor.constraint(equalTo: topAnchor),
      stage.bottomAnchor.constraint(equalTo: bottomAnchor),
      failsafe.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      failsafe.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      failsafe.widthAnchor.constraint(equalToConstant: FailsafeClickView.side),
      failsafe.heightAnchor.constraint(equalToConstant: FailsafeClickView.side),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) n’est pas supporté")
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
    background: NSColor,
    inputBridge: KioskInputBridge,
    contentView: NSView
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
    backgroundColor = background
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
    self.contentView = contentView
    // Swift (CoverWindowCoordinator / CoverWindowStore) ferme une seule fois.
    // Un close répété avec `true` sur-relâche la fenêtre.
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
  /// Au-dessus des hôtes de jeu (océan : bulles à 5, galaxie : glyphes à 2).
  static let abovePlayContent: CGFloat = 1_000
  static let buttonSide: CGFloat = 72
  static let outlineGutter: CGFloat = 4
  static let cornerRadius: CGFloat = 6
  static let outlineWidth: CGFloat = 3
  static var side: CGFloat { buttonSide + outlineGutter * 2 }

  private let inputBridge: KioskInputBridge
  private let fillLayer = CALayer()
  private let progressLayer = CAShapeLayer()

  init(inputBridge: KioskInputBridge) {
    self.inputBridge = inputBridge
    super.init(frame: .zero)
    wantsLayer = true
    layer?.zPosition = Self.abovePlayContent
    layer?.backgroundColor = NSColor.clear.cgColor

    fillLayer.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
    fillLayer.cornerRadius = Self.cornerRadius
    layer?.addSublayer(fillLayer)

    progressLayer.fillColor = nil
    progressLayer.strokeColor = NSColor.white.withAlphaComponent(0.72).cgColor
    progressLayer.lineWidth = Self.outlineWidth
    progressLayer.lineCap = .round
    progressLayer.lineJoin = .round
    progressLayer.strokeStart = 0
    progressLayer.strokeEnd = 0
    progressLayer.isHidden = true
    layer?.addSublayer(progressLayer)

    setAccessibilityLabel("Sortie de secours")
    setAccessibilityRole(.button)
  }

  func setOutlineProgress(_ progress: Double) {
    let clamped = min(1, max(0, progress))
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    progressLayer.isHidden = clamped <= 0
    progressLayer.strokeEnd = CGFloat(clamped)
    CATransaction.commit()
  }

  override func layout() {
    super.layout()
    layer?.zPosition = Self.abovePlayContent
    let scale = window?.backingScaleFactor ?? 2
    let gutter = Self.outlineGutter
    let button = CGRect(
      x: gutter,
      y: gutter,
      width: max(0, bounds.width - gutter * 2),
      height: max(0, bounds.height - gutter * 2)
    )
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    fillLayer.contentsScale = scale
    fillLayer.frame = button
    fillLayer.cornerRadius = Self.cornerRadius
    progressLayer.contentsScale = scale
    progressLayer.frame = CGRect(origin: .zero, size: bounds.size)
    progressLayer.path = Self.outlinePath(around: button, cornerRadius: Self.cornerRadius)
    CATransaction.commit()
  }

  /// Contour du carré, départ en haut au centre, sens horaire à l’écran.
  private static func outlinePath(around button: CGRect, cornerRadius: CGFloat) -> CGPath {
    let radius = min(cornerRadius, min(button.width, button.height) / 2)
    let path = CGMutablePath()
    path.move(to: CGPoint(x: button.midX, y: button.maxY))
    path.addArc(
      tangent1End: CGPoint(x: button.maxX, y: button.maxY),
      tangent2End: CGPoint(x: button.maxX, y: button.midY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: button.maxX, y: button.minY),
      tangent2End: CGPoint(x: button.midX, y: button.minY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: button.minX, y: button.minY),
      tangent2End: CGPoint(x: button.minX, y: button.midY),
      radius: radius
    )
    path.addArc(
      tangent1End: CGPoint(x: button.minX, y: button.maxY),
      tangent2End: CGPoint(x: button.midX, y: button.maxY),
      radius: radius
    )
    path.closeSubpath()
    return path
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
