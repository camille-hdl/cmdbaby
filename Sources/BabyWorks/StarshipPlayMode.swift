import AppKit
import BabyWorkDiagnosticsKit
import QuartzCore

/// Ciel commun à tous les écrans, qui change en fondu.
@MainActor
final class StarshipDirector {
  private struct ScreenSlot {
    var index: Int
    var frame: CGRect?
    var painter: StarshipPainter
  }

  let tuning: StarshipTuning

  private var screens: [ScreenSlot] = []
  private var skybox: CGImage?
  private var skyboxName: String?
  private var rng = SystemRandomNumberGenerator()
  /// Dernier écran où le curseur est entré. `nil` tant qu’il n’a pas quitté l’écran du vaisseau.
  private var lastPointerScreenIndex: Int?
  /// Écran où se trouve le vaisseau. `nil` tant qu’aucun cadre n’est connu.
  private(set) var homeScreenIndex: Int?
  private var ticker: Timer?
  private var skyboxTimer: Timer?
  /// Image précédente, à sortir du cache une fois le fondu terminé.
  private var skyboxToForget: (name: String, at: TimeInterval)?
  /// Le premier affichage attend la fin du tour : les écrans s’enregistrent un par un.
  private var initialChoiceScheduled = false
  private var placementGeneration = 0

  init(tuning: StarshipTuning = .standard) {
    self.tuning = tuning
  }

  func register(screenIndex: Int, painter: StarshipPainter) {
    screens.append(ScreenSlot(index: screenIndex, frame: nil, painter: painter))
    startTicker()
    startSkyboxTimer()
    if skyboxName == nil {
      let name = StarshipSkyboxRotation.first(using: &rng)
      skyboxName = name
      skybox = StarshipSprite.cgImage(named: name)
    }
    publishSkybox()
    chooseHomeScreenIfReady()
  }

  func noteFrame(screenIndex: Int, frame: CGRect) {
    guard let slot = screens.firstIndex(where: { $0.index == screenIndex }) else { return }
    if screens[slot].frame == frame { return }
    screens[slot].frame = frame
    publishSkybox()
    chooseHomeScreenIfReady()
  }

  /// Le curseur est sur l’écran `screenIndex`. Ne fait rien si c’est déjà l’écran du vaisseau,
  /// ni avant le premier affichage : au lancement, le vaisseau naît sur le plus grand.
  func notePointer(screenIndex: Int) {
    guard let homeScreenIndex else { return }
    guard screenIndex != homeScreenIndex else { return }
    lastPointerScreenIndex = screenIndex
    chooseHomeScreenIfReady()
  }

  /// Barre d’espace : un tour du vaisseau sur son écran. Les répétitions et les autres touches
  /// ne font rien pour l’instant.
  func handleKey(_ event: NSEvent) {
    switch StarshipKey.action(keyCode: event.keyCode, isARepeat: event.isARepeat) {
    case .spin:
      guard let homeScreenIndex else { return }
      painter(at: homeScreenIndex)?.spin(duration: tuning.spinDuration)
    case .other, .ignored:
      break
    }
  }

  /// Centre du vaisseau, en coordonnées locales à l’écran du vaisseau.
  /// `nil` tant qu’aucun écran n’a de cadre.
  var shipCenter: CGPoint? {
    guard let homeScreenIndex,
      let frame = screens.first(where: { $0.index == homeScreenIndex })?.frame
    else { return nil }
    return CGPoint(x: frame.width / 2, y: frame.height / 2)
  }

  func reset() {
    placementGeneration += 1
    initialChoiceScheduled = false
    let timer = ticker
    ticker = nil
    timer?.invalidate()
    let rotationTimer = skyboxTimer
    skyboxTimer = nil
    rotationTimer?.invalidate()
    skyboxToForget = nil
    for slot in screens {
      slot.painter.teardown()
    }
    screens.removeAll(keepingCapacity: false)
    skybox = nil
    skyboxName = nil
    rng = SystemRandomNumberGenerator()
    lastPointerScreenIndex = nil
    homeScreenIndex = nil
  }

  private func framedScreens() -> [TerminalScreen] {
    screens.compactMap { slot in
      guard let frame = slot.frame else { return nil }
      return TerminalScreen(
        index: slot.index,
        x: Double(frame.origin.x),
        y: Double(frame.origin.y),
        width: Double(frame.size.width),
        height: Double(frame.size.height)
      )
    }
  }

  private func publishSkybox() {
    guard let skybox else { return }
    let framed = framedScreens()
    for slot in screens {
      guard slot.frame != nil,
        let rect = StarshipSkyboxFraming.contentsRect(forScreen: slot.index, among: framed)
      else { continue }
      slot.painter.showSkybox(image: skybox, contentsRect: rect)
    }
  }

  /// Copie l’idée de `TerminalDirector.choosePromptScreenIfReady`.
  /// Tant que le curseur n’a pas choisi d’écran, le premier affichage est différé
  /// d’un tour pour naître sur le plus grand, sans warp.
  private func chooseHomeScreenIfReady() {
    if homeScreenIndex == nil && lastPointerScreenIndex == nil {
      scheduleInitialChoice()
      return
    }
    applyHomeScreenChoice()
  }

  private func scheduleInitialChoice() {
    guard !initialChoiceScheduled else { return }
    initialChoiceScheduled = true
    let generation = placementGeneration
    DispatchQueue.main.async { [weak self] in
      MainActor.assumeIsolated {
        guard let self, self.placementGeneration == generation else { return }
        self.initialChoiceScheduled = false
        self.applyHomeScreenChoice()
      }
    }
  }

  private func applyHomeScreenChoice() {
    let framed = framedScreens()
    guard framed.count == screens.count else { return }
    guard let index = TerminalScreenLayout.placement(
      lastClickedIndex: lastPointerScreenIndex,
      screens: framed
    ) else { return }
    guard index != homeScreenIndex else { return }
    let previous = homeScreenIndex
    if let previous {
      painter(at: previous)?.hideShip(animated: true)
    }
    painter(at: index)?.showShip(animated: previous != nil)
    homeScreenIndex = index
  }

  private func painter(at index: Int) -> StarshipPainter? {
    screens.first { $0.index == index }?.painter
  }

  private func startTicker() {
    guard ticker == nil else { return }
    let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.tick()
      }
    }
    ticker = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  private func startSkyboxTimer() {
    guard skyboxTimer == nil else { return }
    let timer = Timer(timeInterval: tuning.skyboxInterval, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.rotateSkybox()
      }
    }
    skyboxTimer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  /// Passe à un autre ciel. Une seule transaction : les fondus partent ensemble.
  private func rotateSkybox() {
    guard let skyboxName else { return }
    let name = StarshipSkyboxRotation.next(after: skyboxName, using: &rng)
    guard let image = StarshipSprite.cgImage(named: name) else { return }
    let framed = framedScreens()
    let duration = tuning.skyboxFadeDuration
    CATransaction.begin()
    for slot in screens {
      guard slot.frame != nil,
        let rect = StarshipSkyboxFraming.contentsRect(forScreen: slot.index, among: framed)
      else { continue }
      slot.painter.crossfadeSkybox(to: image, contentsRect: rect, duration: duration)
    }
    CATransaction.commit()
    let previousName = skyboxName
    self.skyboxName = name
    skybox = image
    skyboxToForget = (name: previousName, at: ProcessInfo.processInfo.systemUptime + duration)
  }

  private func tick() {
    let now = ProcessInfo.processInfo.systemUptime
    if let pending = skyboxToForget, now >= pending.at {
      StarshipSprite.forget(named: pending.name)
      skyboxToForget = nil
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for slot in screens {
      slot.painter.tick(now: now)
    }
    CATransaction.commit()
  }
}

/// Ciel commun à tous les écrans, vaisseau au centre de l’écran du vaisseau.
@MainActor
final class StarshipPlayMode: PlayMode {
  private let director: StarshipDirector
  #if DEBUG
  private var checkedCatalogImages = false
  #endif

  init(tuning: StarshipTuning = .standard) {
    director = StarshipDirector(tuning: tuning)
  }

  func windowBackground(screenIndex _: Int) -> NSColor {
    StarshipStageView.backgroundColor
  }

  func makeStage(inputBridge: KioskInputBridge, screenIndex: Int, scale: CGFloat) -> NSView {
    assertCatalogImagesIfNeeded()
    return StarshipStageView(
      inputBridge: inputBridge,
      director: director,
      screenIndex: screenIndex,
      scale: scale
    )
  }

  func reset() {
    director.reset()
    StarshipSprite.purge()
  }

  private func assertCatalogImagesIfNeeded() {
    #if DEBUG
    guard !checkedCatalogImages else { return }
    checkedCatalogImages = true
    for name in StarshipCatalog.allImageNames {
      assert(
        StarshipSprite.cgImage(named: name) != nil,
        "Image du mode Vaisseau introuvable : \(name)"
      )
    }
    #endif
  }
}

/// Ciel et vaisseau d’un écran. Le `contentsRect` choisit le morceau du ciel.
@MainActor
final class StarshipPainter {
  let skyboxBack = CALayer()
  let skyboxFront = CALayer()
  let shipRoot = CALayer()

  private let tuning: StarshipTuning
  private let shipBob = CALayer()
  private let shipSpin = CALayer()
  private let shipAim = CALayer()
  private let shipSprite = CALayer()
  private var ephemerals: [(layer: CALayer, endsAt: TimeInterval)] = []
  private var warpToken = 0
  /// Compteur de tours, pour que chaque appui ait sa propre animation.
  private var spinCounter = 0
  /// Fin du fondu en cours. `nil` quand le ciel du dessous est le ciel courant.
  private var skyboxFadeEndsAt: TimeInterval?

  private static let warpKey = "warp"
  private static let skyboxFadeKey = "skyboxFade"

  init(tuning: StarshipTuning, scale: CGFloat) {
    self.tuning = tuning
    configureSkybox(skyboxBack, zPosition: 0)
    configureSkybox(skyboxFront, zPosition: 1)
    skyboxFront.opacity = 0
    installShip(scale: scale)
  }

  func setBounds(_ bounds: CGRect, scale: CGFloat) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skyboxBack.frame = bounds
    skyboxFront.frame = bounds
    shipRoot.position = CGPoint(x: bounds.midX, y: bounds.midY)
    shipSprite.contentsScale = scale
    CATransaction.commit()
  }

  func showShip(animated: Bool) {
    warpToken += 1
    shipRoot.removeAnimation(forKey: Self.warpKey)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    shipRoot.isHidden = false
    shipRoot.opacity = 1
    shipRoot.transform = CATransform3DIdentity
    if animated {
      shipRoot.add(Self.appearWarp(duration: tuning.shipWarpDuration), forKey: Self.warpKey)
    }
    CATransaction.commit()
  }

  func hideShip(animated: Bool) {
    warpToken += 1
    let token = warpToken
    guard animated else {
      shipRoot.removeAnimation(forKey: Self.warpKey)
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      shipRoot.isHidden = true
      CATransaction.commit()
      return
    }
    CATransaction.begin()
    CATransaction.setCompletionBlock { [weak self] in
      MainActor.assumeIsolated {
        guard let self, self.warpToken == token else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.shipRoot.isHidden = true
        self.shipRoot.removeAnimation(forKey: Self.warpKey)
        CATransaction.commit()
      }
    }
    shipRoot.add(Self.disappearWarp(duration: tuning.shipWarpDuration), forKey: Self.warpKey)
    CATransaction.commit()
  }

  /// Un tour complet sur `shipSpin`, dans le sens horaire. Les tours s’additionnent.
  func spin(duration: Double) {
    let turn = CABasicAnimation(keyPath: "transform.rotation.z")
    turn.fromValue = 0
    turn.toValue = -2 * Double.pi
    turn.duration = duration
    turn.isAdditive = true
    turn.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    shipSpin.add(turn, forKey: "spin-\(spinCounter)")
    spinCounter += 1
  }

  /// Ajoute `layer` à la scène et le retire automatiquement après `lifetime` secondes.
  func addEphemeral(_ layer: CALayer, lifetime: TimeInterval, now: TimeInterval) {
    skyboxBack.superlayer?.addSublayer(layer)
    ephemerals.append((layer: layer, endsAt: now + lifetime))
  }

  /// Retire les éphémères expirés et pose le ciel fondu sur le calque du dessous.
  func tick(now: TimeInterval) {
    if let endsAt = skyboxFadeEndsAt, now >= endsAt {
      settleSkyboxFade()
    }
    ephemerals.removeAll { item in
      guard now >= item.endsAt else { return false }
      item.layer.removeFromSuperlayer()
      return true
    }
  }

  func teardown() {
    warpToken += 1
    skyboxFadeEndsAt = nil
    shipRoot.removeAnimation(forKey: Self.warpKey)
    skyboxFront.removeAnimation(forKey: Self.skyboxFadeKey)
    for item in ephemerals {
      item.layer.removeFromSuperlayer()
    }
    ephemerals.removeAll(keepingCapacity: false)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skyboxBack.contents = nil
    skyboxFront.contents = nil
    skyboxFront.opacity = 0
    CATransaction.commit()
    shipRoot.removeFromSuperlayer()
    skyboxFront.removeFromSuperlayer()
    skyboxBack.removeFromSuperlayer()
  }

  private func configureSkybox(_ layer: CALayer, zPosition: CGFloat) {
    layer.zPosition = zPosition
    layer.contentsGravity = .resize
    layer.magnificationFilter = .linear
    layer.minificationFilter = .trilinear
  }

  private func settleSkyboxFade() {
    skyboxBack.contents = skyboxFront.contents
    skyboxBack.contentsRect = skyboxFront.contentsRect
    skyboxFront.removeAnimation(forKey: Self.skyboxFadeKey)
    skyboxFront.contents = nil
    skyboxFront.opacity = 0
    skyboxFadeEndsAt = nil
  }

  private func installShip(scale: CGFloat) {
    let image = StarshipSprite.cgImage(named: StarshipCatalog.shipSprite)
    let size = Self.shipSize(width: tuning.shipWidth, image: image)
    let shipBounds = CGRect(origin: .zero, size: size)
    let center = CGPoint(x: size.width / 2, y: size.height / 2)

    shipRoot.bounds = shipBounds
    shipRoot.zPosition = 20
    shipRoot.isHidden = true

    for layer in [shipBob, shipSpin, shipAim, shipSprite] {
      layer.bounds = shipBounds
      layer.position = center
    }
    shipSprite.contents = image
    shipSprite.contentsGravity = .resizeAspect
    shipSprite.contentsScale = scale

    shipRoot.addSublayer(shipBob)
    shipBob.addSublayer(shipSpin)
    shipSpin.addSublayer(shipAim)
    shipAim.addSublayer(shipSprite)

    let bob = CABasicAnimation(keyPath: "transform.translation.y")
    bob.fromValue = -4
    bob.toValue = 4
    bob.duration = 1.2
    bob.autoreverses = true
    bob.repeatCount = .infinity
    bob.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    shipBob.add(bob, forKey: "bob")
  }

  private static func shipSize(width: Double, image: CGImage?) -> CGSize {
    let points = CGFloat(width)
    guard let image, image.width > 0 else {
      return CGSize(width: points, height: points)
    }
    let ratio = CGFloat(image.height) / CGFloat(image.width)
    return CGSize(width: points, height: points * ratio)
  }

  private static func appearWarp(duration: Double) -> CAAnimationGroup {
    let scale = CAKeyframeAnimation(keyPath: "transform.scale")
    scale.values = [0.1, 1.15, 1]
    scale.keyTimes = [0, 0.7, 1]
    scale.duration = duration
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 0
    opacity.toValue = 1
    opacity.duration = duration
    let group = CAAnimationGroup()
    group.animations = [scale, opacity]
    group.duration = duration
    return group
  }

  private static func disappearWarp(duration: Double) -> CAAnimationGroup {
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 1
    scale.toValue = 0.1
    scale.duration = duration
    scale.fillMode = .forwards
    scale.isRemovedOnCompletion = false
    let opacity = CABasicAnimation(keyPath: "opacity")
    opacity.fromValue = 1
    opacity.toValue = 0
    opacity.duration = duration
    opacity.fillMode = .forwards
    opacity.isRemovedOnCompletion = false
    let group = CAAnimationGroup()
    group.animations = [scale, opacity]
    group.duration = duration
    group.fillMode = .forwards
    group.isRemovedOnCompletion = false
    return group
  }

  /// `contentsRect` partage l’origine en bas à gauche du calque non retourné.
  /// Vérifié avec `skybox-space-band` : la bande claire reste dans le même sens que le PNG.
  func showSkybox(image: CGImage, contentsRect: StarshipUnitRect) {
    let rect = Self.cgRect(contentsRect)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    if skyboxFadeEndsAt == nil {
      skyboxBack.contents = image
      skyboxBack.contentsRect = rect
    } else {
      skyboxBack.contentsRect = rect
      skyboxFront.contentsRect = rect
    }
    CATransaction.commit()
  }

  /// Fondu du calque du dessus vers `image`. Le dessous garde le ciel courant jusqu’à la fin.
  func crossfadeSkybox(to image: CGImage, contentsRect: StarshipUnitRect, duration: TimeInterval) {
    let rect = Self.cgRect(contentsRect)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skyboxBack.contentsRect = rect
    skyboxFront.contents = image
    skyboxFront.contentsRect = rect
    skyboxFront.opacity = 0
    CATransaction.commit()

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 0
    fade.toValue = 1
    fade.duration = duration
    fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skyboxFront.opacity = 1
    CATransaction.commit()
    skyboxFront.add(fade, forKey: Self.skyboxFadeKey)
    skyboxFadeEndsAt = ProcessInfo.processInfo.systemUptime + duration
  }

  private static func cgRect(_ rect: StarshipUnitRect) -> CGRect {
    CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
  }
}

/// Ciel et vaisseau de la session sur un écran. La frappe remonte d’abord les sorties adultes.
final class StarshipStageView: NSView {
  static let backgroundColor = NSColor(
    srgbRed: 0x0B / 255,
    green: 0x0B / 255,
    blue: 0x1F / 255,
    alpha: 1
  )

  private let inputBridge: KioskInputBridge
  private let director: StarshipDirector
  private let screenIndex: Int
  private let sceneLayer = CALayer()
  private var painter: StarshipPainter!
  private var trackingArea: NSTrackingArea?

  init(
    inputBridge: KioskInputBridge,
    director: StarshipDirector,
    screenIndex: Int,
    scale: CGFloat
  ) {
    self.inputBridge = inputBridge
    self.director = director
    self.screenIndex = screenIndex
    super.init(frame: .zero)
    wantsLayer = true
    guard let root = layer else {
      fatalError("StarshipStageView n’a pas de calque")
    }
    root.backgroundColor = Self.backgroundColor.cgColor
    root.contentsScale = scale
    root.addSublayer(sceneLayer)
    let painter = StarshipPainter(tuning: director.tuning, scale: scale)
    self.painter = painter
    sceneLayer.addSublayer(painter.skyboxBack)
    sceneLayer.addSublayer(painter.skyboxFront)
    sceneLayer.addSublayer(painter.shipRoot)
    director.register(screenIndex: screenIndex, painter: painter)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) n’est pas supporté")
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    reportFrame()
  }

  override func layout() {
    super.layout()
    guard painter != nil else { return }
    let scale = window?.backingScaleFactor ?? 2
    layer?.contentsScale = scale
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    sceneLayer.frame = bounds
    sceneLayer.contentsScale = scale
    CATransaction.commit()
    painter.setBounds(bounds, scale: scale)
    reportFrame()
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let trackingArea {
      removeTrackingArea(trackingArea)
    }
    let area = NSTrackingArea(
      rect: bounds,
      options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    trackingArea = area
    addTrackingArea(area)
  }

  override func mouseEntered(with event: NSEvent) {
    director.notePointer(screenIndex: screenIndex)
  }

  override func mouseMoved(with event: NSEvent) {
    director.notePointer(screenIndex: screenIndex)
  }

  override func mouseDragged(with event: NSEvent) {
    director.notePointer(screenIndex: screenIndex)
  }

  override func mouseDown(with event: NSEvent) {
    director.notePointer(screenIndex: screenIndex)
    window?.makeFirstResponder(self)
  }

  private func reportFrame() {
    guard let frame = window?.frame else { return }
    director.noteFrame(screenIndex: screenIndex, frame: frame)
  }

  override var acceptsFirstResponder: Bool { true }
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  override func keyDown(with event: NSEvent) {
    let code = UInt16(event.keyCode)
    let isReturn = code == 0x24 || code == 0x4C
    let isEscape = code == 0x35
    let shiftDown = event.modifierFlags.contains(.shift)
    let ignoring = event.charactersIgnoringModifiers ?? ""
    let letter = ignoring.lowercased().first { $0.isLetter }
      ?? KeyboardLayoutLetter.shared.fromKeyCode(code)
    inputBridge.noteKeyDown(
      letter: letter,
      isReturn: isReturn,
      isEscape: isEscape,
      shiftDown: shiftDown
    )
    director.handleKey(event)
  }
}
