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

  private struct LiveTarget {
    let id: Int
    let kind: StarshipTargetKind
    let flight: StarshipFlight
    let spawnedAt: TimeInterval
    /// Instant du tir automatique : apparition plus le délai tiré.
    let fireAt: TimeInterval
    /// Position figée une fois visée. `nil` tant que la cible vole.
    var doomedAt: StarshipPoint?
    /// Moment de l’explosion une fois visée. `nil` tant que la cible vole.
    var explodeAt: TimeInterval?
  }

  /// Cibles à faire exploser ce tick, et rayons à tirer après les avoir figées.
  private struct TargetStep {
    var exploding: [LiveTarget] = []
    var beams: [(from: CGPoint, to: CGPoint, angle: Double)] = []
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
  /// Début de la session, pour `tuning.screenChangeDelay`.
  private var sessionStartedAt: TimeInterval
  private var ticker: Timer?
  private var skyboxTimer: Timer?
  /// Image précédente, à sortir du cache une fois le fondu terminé.
  private var skyboxToForget: (name: String, at: TimeInterval)?
  /// Le premier affichage attend la fin du tour : les écrans s’enregistrent un par un.
  private var initialChoiceScheduled = false
  private var placementGeneration = 0
  private var keyRate: StarshipKeyRate
  private var gaugeLevel = 0.0
  private var lastTick: TimeInterval = 0
  /// Cibles en vol, dans l’ordre d’apparition.
  private var targets: [LiveTarget] = []
  private var nextTargetID = 0

  init(tuning: StarshipTuning = .standard) {
    self.tuning = tuning
    keyRate = StarshipKeyRate(window: tuning.keyRateWindow, cap: tuning.keyRateCap)
    sessionStartedAt = ProcessInfo.processInfo.systemUptime
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
  /// ni avant le premier affichage, ni pendant `tuning.screenChangeDelay` :
  /// au lancement, le vaisseau naît sur le plus grand, sans warp.
  func notePointer(screenIndex: Int) {
    guard let homeScreenIndex else { return }
    guard screenIndex != homeScreenIndex else { return }
    guard StarshipScreenChoice.followsPointer(sessionAge: sessionAge, tuning: tuning) else { return }
    lastPointerScreenIndex = screenIndex
    chooseHomeScreenIfReady()
  }

  /// Barre d’espace : un tour du vaisseau. Chaque frappe réelle, espace compris, compte pour la jauge.
  func handleKey(_ event: NSEvent) {
    let action = StarshipKey.action(keyCode: event.keyCode, isARepeat: event.isARepeat)
    if action != .ignored {
      keyRate.record(at: ProcessInfo.processInfo.systemUptime)
    }
    switch action {
    case .spin:
      guard let homeScreenIndex else { return }
      painter(at: homeScreenIndex)?.spin(duration: tuning.spinDuration)
    case .other:
      spawnTarget(label: StarshipGlyph.label(for: event.characters))
    case .ignored:
      break
    }
  }

  /// Clic : le vaisseau pivote vers `point` puis tire dans cette direction.
  /// Rien si `screenIndex` n’est pas l’écran du vaisseau.
  func fire(towards point: CGPoint, screenIndex: Int) {
    guard screenIndex == homeScreenIndex,
      let origin = shipCenter,
      let frame = screens.first(where: { $0.index == screenIndex })?.frame,
      let painter = painter(at: screenIndex)
    else { return }

    let now = ProcessInfo.processInfo.systemUptime
    let originPoint = StarshipPoint(x: Double(origin.x), y: Double(origin.y))
    let click = StarshipPoint(x: Double(point.x), y: Double(point.y))
    let angle = StarshipAim.angle(from: originPoint, to: click) ?? painter.aimAngle
    painter.aimShip(at: angle, duration: tuning.aimDuration)
    doomTarget(along: angle, from: originPoint, now: now, painter: painter)

    let directionX = cos(angle)
    let directionY = sin(angle)
    let nose = Double(painter.shipHeight) / 2
    let start = CGPoint(
      x: origin.x + CGFloat(nose * directionX),
      y: origin.y + CGFloat(nose * directionY)
    )
    let exit = StarshipAim.rayExit(
      from: originPoint,
      angle: angle,
      width: Double(frame.width),
      height: Double(frame.height)
    )
    let end = CGPoint(
      x: CGFloat(exit.x + tuning.boltOvershoot * directionX),
      y: CGFloat(exit.y + tuning.boltOvershoot * directionY)
    )
    let distance = hypot(end.x - start.x, end.y - start.y)
    painter.fireBolt(
      from: start,
      to: end,
      angle: angle,
      duration: Double(distance) / tuning.boltSpeed,
      delay: tuning.aimDuration
    )
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
    sessionStartedAt = ProcessInfo.processInfo.systemUptime
    keyRate = StarshipKeyRate(window: tuning.keyRateWindow, cap: tuning.keyRateCap)
    gaugeLevel = 0
    lastTick = 0
    targets.removeAll(keepingCapacity: false)
    nextTargetID = 0
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
  /// d’un tour pour naître sur le plus grand, sans warp. Pendant `screenChangeDelay`,
  /// un curseur déjà noté ne compte pas non plus.
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
    guard let index = StarshipScreenChoice.index(
      sessionAge: sessionAge,
      pointerScreenIndex: lastPointerScreenIndex,
      screens: framed,
      tuning: tuning
    ) else { return }
    guard index != homeScreenIndex else { return }
    let previous = homeScreenIndex
    if let previous {
      explodeAllTargets(now: ProcessInfo.processInfo.systemUptime)
      painter(at: previous)?.hideShip(animated: true)
      painter(at: previous)?.hideGauge()
    }
    homeScreenIndex = index
    let rate = keyRate.perMinute(at: ProcessInfo.processInfo.systemUptime)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    paintGauge(rate: rate)
    CATransaction.commit()
    installPendingGaugePulse()
    painter(at: index)?.showShip(animated: previous != nil)
    painter(at: index)?.showGauge()
  }

  private var sessionAge: Double {
    ProcessInfo.processInfo.systemUptime - sessionStartedAt
  }

  private func painter(at index: Int) -> StarshipPainter? {
    screens.first { $0.index == index }?.painter
  }

  private func paintGauge(rate: Double) {
    guard let homeScreenIndex else { return }
    painter(at: homeScreenIndex)?.updateGauge(
      level: gaugeLevel,
      color: StarshipGauge.color(level: gaugeLevel),
      atCap: rate >= tuning.keyRateCap
    )
  }

  private func installPendingGaugePulse() {
    guard let homeScreenIndex else { return }
    painter(at: homeScreenIndex)?.installPendingGaugePulse()
  }

  private func startTicker() {
    guard ticker == nil else { return }
    lastTick = ProcessInfo.processInfo.systemUptime
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
    let dt = lastTick == 0 ? 1.0 / 60.0 : min(0.05, max(1.0 / 120.0, now - lastTick))
    lastTick = now
    if let pending = skyboxToForget, now >= pending.at {
      StarshipSprite.forget(named: pending.name)
      skyboxToForget = nil
    }
    let rate = keyRate.perMinute(at: now)
    let level = StarshipGauge.level(perMinute: rate, cap: tuning.keyRateCap)
    gaugeLevel = StarshipGauge.eased(current: gaugeLevel, target: level, dt: dt)
    // Le tir automatique est décidé avant le bouclier : une cible visée reste figée.
    let step = advanceTargets(now: now)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    paintGauge(rate: rate)
    moveTargets(step: step, now: now)
    for slot in screens {
      slot.painter.tick(now: now)
    }
    CATransaction.commit()
    if let homeScreenIndex, let painter = painter(at: homeScreenIndex) {
      for beam in step.beams {
        painter.aimShip(at: beam.angle, duration: tuning.aimDuration)
        painter.fireBeam(
          from: beam.from,
          to: beam.to,
          delay: tuning.aimDuration,
          duration: tuning.beamDuration,
          now: now
        )
      }
    }
    for target in step.exploding {
      explode(target, now: now)
    }
    installPendingGaugePulse()
  }

  /// Sans écran du vaisseau, la frappe ne fait rien. Au-delà de `maxTargets`, la plus ancienne explose.
  private func spawnTarget(label: String?) {
    guard let homeScreenIndex,
      let frame = screens.first(where: { $0.index == homeScreenIndex })?.frame,
      let center = shipCenter,
      let painter = painter(at: homeScreenIndex)
    else { return }

    let now = ProcessInfo.processInfo.systemUptime
    if targets.count >= tuning.maxTargets, let oldest = targets.first {
      explode(oldest, now: now)
    }

    let margin = tuning.targetWidth / 2 + 10
    let start = StarshipSpawn.edgePoint(
      width: Double(frame.width),
      height: Double(frame.height),
      margin: margin,
      roll: Double.random(in: 0..<1)
    )
    let goal = StarshipPoint(x: Double(center.x), y: Double(center.y))
    let flight = StarshipFlight.random(
      start: start,
      goal: goal,
      tuning: tuning,
      speedRoll: Double.random(in: 0..<1),
      accelerationRoll: Double.random(in: 0..<1)
    )
    let picked = StarshipCatalog.pickTarget(
      kindRoll: Double.random(in: 0..<1),
      spriteRoll: Double.random(in: 0..<1)
    )
    let id = nextTargetID
    nextTargetID += 1
    painter.addTarget(
      id: id,
      kind: picked.kind,
      sprite: picked.sprite,
      label: label,
      at: CGPoint(x: start.x, y: start.y),
      heading: flight.heading
    )
    let delay = StarshipFireSchedule.delay(
      for: flight,
      tuning: tuning,
      roll: Double.random(in: 0..<1)
    )
    targets.append(
      LiveTarget(
        id: id,
        kind: picked.kind,
        flight: flight,
        spawnedAt: now,
        fireAt: now + delay
      )
    )
  }

  /// Fige les cibles dues et note les explosions de ce tick : tir arrivé à échéance, ou bouclier.
  /// Une cible déjà visée ne bouge plus : le bouclier ne la concerne plus.
  /// Le bouclier ne la retire pas avant le tir prévu.
  private func advanceTargets(now: TimeInterval) -> TargetStep {
    var step = TargetStep()
    let center = shipCenter
    let ship = center.map { StarshipPoint(x: Double($0.x), y: Double($0.y)) }
    let currentAim = homeScreenIndex.flatMap { painter(at: $0)?.aimAngle } ?? .pi / 2

    for index in targets.indices {
      if let explodeAt = targets[index].explodeAt {
        if now >= explodeAt {
          step.exploding.append(targets[index])
        }
        continue
      }

      if now >= targets[index].fireAt, let center, let ship {
        let position = position(of: targets[index], at: now)
        targets[index].doomedAt = position
        let explodeAt = now + tuning.aimDuration
        targets[index].explodeAt = explodeAt
        let point = CGPoint(x: position.x, y: position.y)
        let angle = StarshipAim.angle(from: ship, to: position) ?? currentAim
        step.beams.append((from: center, to: point, angle: angle))
        if now >= explodeAt {
          step.exploding.append(targets[index])
        }
        continue
      }

      let elapsed = now - targets[index].spawnedAt
      if StarshipFireSchedule.shieldDestroys(
        flight: targets[index].flight,
        elapsed: elapsed,
        fireDelay: targets[index].fireAt - targets[index].spawnedAt,
        tuning: tuning
      ) {
        step.exploding.append(targets[index])
      }
    }
    return step
  }

  /// Le déplacement se fait dans la transaction du tick. Une cible visée reste sur `doomedAt`.
  private func moveTargets(step: TargetStep, now: TimeInterval) {
    guard let homeScreenIndex, let painter = painter(at: homeScreenIndex) else { return }
    let explodingIDs = Set(step.exploding.map(\.id))
    for target in targets {
      if let doomed = target.doomedAt {
        painter.moveTarget(id: target.id, to: CGPoint(x: doomed.x, y: doomed.y))
        continue
      }
      if explodingIDs.contains(target.id) { continue }
      let position = position(of: target, at: now)
      painter.moveTarget(id: target.id, to: CGPoint(x: position.x, y: position.y))
    }
  }

  /// Un tir au clic qui traverse une cible encore en vol la fige et la fait exploser à l’impact.
  private func doomTarget(
    along angle: Double,
    from origin: StarshipPoint,
    now: TimeInterval,
    painter: StarshipPainter
  ) {
    let candidates: [(id: Int, center: StarshipPoint)] = targets.compactMap { target in
      guard target.explodeAt == nil else { return nil }
      return (id: target.id, center: position(of: target, at: now))
    }
    guard let hit = StarshipAim.firstHit(
      origin: origin,
      angle: angle,
      candidates: candidates,
      radius: tuning.targetWidth / 2
    ), let index = targets.firstIndex(where: { $0.id == hit }) else { return }

    let doomed = position(of: targets[index], at: now)
    targets[index].doomedAt = doomed
    let separation = hypot(doomed.x - origin.x, doomed.y - origin.y)
    targets[index].explodeAt = now + tuning.aimDuration + separation / tuning.boltSpeed
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    painter.moveTarget(id: hit, to: CGPoint(x: doomed.x, y: doomed.y))
    CATransaction.commit()
  }

  private func position(of target: LiveTarget, at now: TimeInterval) -> StarshipPoint {
    target.flight.position(at: now - target.spawnedAt)
  }

  private func explodeAllTargets(now: TimeInterval) {
    let flying = targets
    for target in flying {
      explode(target, now: now)
    }
  }

  private func explode(_ target: LiveTarget, now: TimeInterval) {
    targets.removeAll { $0.id == target.id }
    guard let homeScreenIndex else { return }
    painter(at: homeScreenIndex)?.explodeTarget(id: target.id, kind: target.kind, now: now)
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
    sceneLayer.addSublayer(painter.gaugeTrack)
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
    let point = convert(event.locationInWindow, from: nil)
    director.fire(towards: point, screenIndex: screenIndex)
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
    let key = KeyboardLayoutLetter.shared.keyDownLetters(
      keyCode: code,
      charactersIgnoringModifiers: event.charactersIgnoringModifiers ?? ""
    )
    inputBridge.noteKeyDown(
      letters: key.letters,
      shownLetter: key.shown,
      isReturn: isReturn,
      isEscape: isEscape,
      shiftDown: shiftDown
    )
    director.handleKey(event)
  }
}
