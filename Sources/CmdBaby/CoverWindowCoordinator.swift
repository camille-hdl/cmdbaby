import AppKit
import CmdBabyKit
import QuartzCore

/// Une fenêtre sans bordure par `NSScreen` vivant, jamais une fenêtre géante ni une liste mise en cache.
/// Un écran branché, débranché ou redimensionné en cours de session suit dans la seconde.
@MainActor
final class CoverWindowCoordinator {
  private struct Cover {
    let screenID: ScreenID
    let screenIndex: Int
    let window: NSWindow
    let failsafe: FailsafeClickView
    let parentBanner: NSTextField
  }

  var onAdultExit: (@Sendable (AdultExitKind) -> Void)?
  private var covers: [Cover] = []
  /// Index de scène du prochain écran ; jamais réutilisé dans une session.
  private var nextScreenIndex = 0
  private var inputBridge: KioskInputBridge?
  private var playMode: (any PlayMode)?
  private var sessionMode: KioskPlayModeID = KioskPlayModeCatalog.default
  private var exits = AdultExitSettings()
  private var timeLimit: SessionTimeLimit?
  private var outlineTimer: Timer?
  private var sessionObservers: [NSObjectProtocol] = []
  private var parentWarningVisible = false
  private let displaySleep = DisplaySleepAssertion()

  /// Mémorise le mode et les sorties de la session qui va démarrer.
  func prepare(mode: KioskPlayModeID, exits: AdultExitSettings) {
    sessionMode = mode
    self.exits = exits
  }

  func createCoverWindows() throws -> [ScreenDescriptor] {
    closeCoverWindows()
    let screens = NSScreen.screens
    guard !screens.isEmpty else { throw KioskSessionError.noScreens }

    activateApp()
    let exitHandler = onAdultExit
    inputBridge = KioskInputBridge(exits: exits) { kind in
      exitHandler?(kind)
    }
    playMode = PlayModeRegistry.make(sessionMode)

    for screen in screens {
      addCover(on: screen)
    }
    refocus()
    startOutlineClock()
    observeSessionNotifications()
    displaySleep.take()
    return screens.map(ScreenDescriptor.init(nsScreen:))
  }

  func refocus() {
    activateApp()
    guard let first = covers.first?.window else { return }
    first.makeKeyAndOrderFront(nil)
    let responder = first.contentView.flatMap { content in
      content.subviews.first { $0.acceptsFirstResponder } ?? content
    }
    first.makeFirstResponder(responder)
  }

  var primaryCoverIsKey: Bool {
    covers.first?.window.isKeyWindow == true
  }

  /// Après la présentation kiosque, le key peut rater le premier tour : retry borné.
  func ensurePrimaryCoverIsKey(log: LifecycleLogRecorder = .shared) async {
    var sequence = CoverKeySequence()
    while sequence.shouldMakeKey {
      if sequence.makeKeyIsRetry {
        try? await Task.sleep(for: .seconds(CoverKeyPresentation.makeKeyRetryDelay))
      }
      refocus()
      await Self.yieldMainQueue()
      let event = sequence.recordMakeKey(isKey: primaryCoverIsKey)
      log.emit(event)
    }
  }

  private static func yieldMainQueue() async {
    await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        continuation.resume()
      }
    }
  }

  func closeCoverWindows() {
    displaySleep.release()
    stopObservingSessionNotifications()
    stopOutlineClock()
    parentWarningVisible = false
    let remaining = covers
    covers.removeAll(keepingCapacity: false)
    nextScreenIndex = 0
    for cover in remaining {
      Self.dismiss(cover.window)
    }
    inputBridge = nil
    playMode?.reset()
    playMode = nil
  }

  private func addCover(on screen: NSScreen) {
    guard let mode = playMode, let bridge = inputBridge else { return }
    let screenIndex = nextScreenIndex
    nextScreenIndex += 1
    let descriptor = ScreenDescriptor(nsScreen: screen)
    let failsafe = FailsafeClickView(
      inputBridge: bridge,
      acceptsClicks: exits.enabledMethods.contains(.failsafeClick)
    )
    let stage = mode.makeStage(
      inputBridge: bridge,
      screenIndex: screenIndex,
      scale: screen.backingScaleFactor
    )
    let banner = ParentWarningBanner.make()
    banner.isHidden = !parentWarningVisible
    let window = CoverWindow(
      screen: screen,
      descriptor: descriptor,
      background: mode.windowBackground(screenIndex: screenIndex),
      inputBridge: bridge,
      contentView: PlayStageHost(stage: stage, failsafe: failsafe, banner: banner)
    )
    covers.append(
      Cover(
        screenID: screen.screenID,
        screenIndex: screenIndex,
        window: window,
        failsafe: failsafe,
        parentBanner: banner
      )
    )
    window.orderFrontRegardless()
  }

  private static func dismiss(_ window: NSWindow) {
    window.contentView = nil
    window.ignoresMouseEvents = true
    window.alphaValue = 0
    window.orderOut(nil)
    window.close()
  }

  /// Bandeau pour l’adulte quand la protection du clavier n’est plus garantie. Jamais la phrase.
  func showParentWarning(_ visible: Bool) {
    guard visible != parentWarningVisible else { return }
    parentWarningVisible = visible
    for cover in covers {
      cover.parentBanner.isHidden = !visible
    }
  }

  private func observeSessionNotifications() {
    let center = NotificationCenter.default
    sessionObservers = [
      center.addObserver(
        forName: NSApplication.didChangeScreenParametersNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          self?.followScreenChanges()
        }
      },
      // Une notification ou une autre app ne garde pas le clavier : les lettres restent dans la scène.
      center.addObserver(
        forName: NSApplication.didResignActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          guard let self, !self.covers.isEmpty else { return }
          LifecycleLogRecorder.shared.emit(.guardRefocus)
          self.refocus()
        }
      },
    ]
  }

  private func stopObservingSessionNotifications() {
    for observer in sessionObservers {
      NotificationCenter.default.removeObserver(observer)
    }
    sessionObservers.removeAll()
  }

  /// Couvre les écrans branchés, ferme ceux débranchés, recadre ceux redimensionnés.
  private func followScreenChanges() {
    guard let mode = playMode else { return }
    let screens = Dictionary(
      NSScreen.screens.map { ($0.screenID, $0) },
      uniquingKeysWith: { first, _ in first }
    )
    let diff = CoverLayoutDiff.changes(
      current: Dictionary(
        covers.map { ($0.screenID, $0.window.frame) },
        uniquingKeysWith: { first, _ in first }
      ),
      next: screens.mapValues(\.frame)
    )
    guard !diff.isEmpty else { return }

    for id in diff.remove {
      guard let position = covers.firstIndex(where: { $0.screenID == id }) else { continue }
      let cover = covers.remove(at: position)
      Self.dismiss(cover.window)
      mode.removeStage(screenIndex: cover.screenIndex)
    }
    for id in diff.reframe {
      guard let screen = screens[id], let cover = covers.first(where: { $0.screenID == id }) else {
        continue
      }
      cover.window.setFrame(screen.frame, display: true)
    }
    for id in diff.add {
      guard let screen = screens[id] else { continue }
      addCover(on: screen)
    }
    advanceOutlineClock()
    refocus()
    LifecycleLogRecorder.shared.emit(
      .coversFollowScreens(added: diff.add.count, removed: diff.remove.count, reframed: diff.reframe.count)
    )
  }

  private func startOutlineClock() {
    let limit = SessionTimeLimit(
      startedAt: ProcessInfo.processInfo.systemUptime,
      settings: exits
    )
    timeLimit = limit
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
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
  }

  private func advanceOutlineClock() {
    guard let timeLimit else { return }
    let now = ProcessInfo.processInfo.systemUptime
    let progress = timeLimit.progress(at: now)
    for cover in covers {
      cover.failsafe.setOutlineProgress(progress)
    }
    guard timeLimit.isComplete(at: now) else { return }
    self.timeLimit = nil
    outlineTimer?.invalidate()
    outlineTimer = nil
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

/// Pont clavier et clics des fenêtres et des scènes.
@MainActor
final class KioskInputBridge {
  private let recognizer: AdultExitRecognizer
  private let onExit: @Sendable (AdultExitKind) -> Void

  init(
    exits: AdultExitSettings,
    onExit: @escaping @Sendable (AdultExitKind) -> Void
  ) {
    self.recognizer = AdultExitRecognizer(settings: exits)
    self.onExit = onExit
  }

  func noteKeyDown(
    letters: Set<Character>,
    isReturn: Bool,
    isEscape: Bool,
    shiftDown: Bool
  ) {
    let kind = recognizer.handleKeyDown(
      letters: letters,
      isReturn: isReturn,
      isEscape: isEscape,
      shiftDown: shiftDown
    )
    if let kind {
      onExit(kind)
    }
  }

  func noteFailsafeClick() {
    let result = recognizer.handleFailsafeClick()
    if let exit = result.exit {
      onExit(exit)
    }
  }
}

/// Scène de jeu en dessous, carré de secours au-dessus. Les calques du mode (sol, poissons, glyphes) restent dans la scène.
private final class PlayStageHost: NSView {
  init(stage: NSView, failsafe: FailsafeClickView, banner: NSTextField) {
    super.init(frame: .zero)
    wantsLayer = true
    stage.translatesAutoresizingMaskIntoConstraints = false
    stage.layer?.masksToBounds = true
    addSubview(stage)

    failsafe.translatesAutoresizingMaskIntoConstraints = false
    addSubview(failsafe)

    banner.translatesAutoresizingMaskIntoConstraints = false
    addSubview(banner)

    NSLayoutConstraint.activate([
      stage.leadingAnchor.constraint(equalTo: leadingAnchor),
      stage.trailingAnchor.constraint(equalTo: trailingAnchor),
      stage.topAnchor.constraint(equalTo: topAnchor),
      stage.bottomAnchor.constraint(equalTo: bottomAnchor),
      failsafe.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      failsafe.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      failsafe.widthAnchor.constraint(equalToConstant: FailsafeClickView.side),
      failsafe.heightAnchor.constraint(equalToConstant: FailsafeClickView.side),
      banner.centerXAnchor.constraint(equalTo: centerXAnchor),
      banner.topAnchor.constraint(equalTo: topAnchor, constant: 12),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) n’est pas supporté")
  }
}

/// Petit bandeau discret en haut de chaque couverture, au-dessus de la scène.
@MainActor
private enum ParentWarningBanner {
  static func make() -> NSTextField {
    let label = NSTextField(labelWithString: L10n.current("session.guard.warning"))
    label.font = .systemFont(ofSize: 13, weight: .medium)
    label.textColor = .white
    label.drawsBackground = true
    label.backgroundColor = NSColor.black.withAlphaComponent(0.6)
    label.wantsLayer = true
    label.layer?.zPosition = 100
    label.layer?.cornerRadius = 6
    label.layer?.masksToBounds = true
    return label
  }
}

private final class CoverWindow: NSWindow {
  private let inputBridge: KioskInputBridge

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

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
    identifier = NSUserInterfaceItemIdentifier("\(AppIdentity.bundleIdentifier).cover.\(descriptor.id)")
    self.contentView = contentView
    // Une seule fermeture par fenêtre : un `close` répété avec `true` sur-relâche.
    isReleasedWhenClosed = false
  }

  override func performKeyEquivalent(with event: NSEvent) -> Bool {
    event.modifierFlags.contains(.command)
  }
}

final class FailsafeClickView: NSView {
  /// Au-dessus des hôtes de jeu (océan : bulles à 5, vaisseau : jauge à 40).
  static let abovePlayContent: CGFloat = 1_000
  static let buttonSide: CGFloat = 72
  static let outlineGutter: CGFloat = 4
  static let cornerRadius: CGFloat = 6
  static let outlineWidth: CGFloat = 3
  static var side: CGFloat { buttonSide + outlineGutter * 2 }

  private let inputBridge: KioskInputBridge
  private let acceptsClicks: Bool
  private let fillLayer = CALayer()
  private let progressLayer = CAShapeLayer()

  init(inputBridge: KioskInputBridge, acceptsClicks: Bool) {
    self.inputBridge = inputBridge
    self.acceptsClicks = acceptsClicks
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

    if acceptsClicks {
      setAccessibilityLabel(L10n.current("cover.failsafe.accessibility"))
      setAccessibilityRole(.button)
    } else {
      setAccessibilityLabel(L10n.current("cover.timer.accessibility"))
      setAccessibilityRole(.staticText)
    }
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    guard acceptsClicks else { return nil }
    return super.hitTest(point)
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

  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  override func mouseDown(with event: NSEvent) {
    inputBridge.noteFailsafeClick()
  }
}

extension NSScreen {
  /// `CGDirectDisplayID` de l’écran ; 0 si macOS ne le donne pas.
  var screenID: ScreenID {
    let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
    return number?.uint32Value ?? 0
  }
}

extension ScreenDescriptor {
  init(nsScreen: NSScreen) {
    self.init(
      id: String(nsScreen.screenID),
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
