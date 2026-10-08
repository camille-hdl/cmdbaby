import AppKit
import CmdBabyKit
import QuartzCore

/// Ciel, vaisseau et jauge d’un écran. Le `contentsRect` choisit le morceau du ciel.
@MainActor
final class StarshipPainter {
  let skyboxBack = CALayer()
  let skyboxFront = CALayer()
  let shipRoot = CALayer()
  let gaugeTrack = CALayer()

  private let tuning: StarshipTuning
  private let shipBob = CALayer()
  private let shipSpin = CALayer()
  private let shipAim = CALayer()
  private let shipSprite = CALayer()
  private var ephemerals: [(layer: CALayer, endsAt: TimeInterval)] = []
  private var warpToken = 0
  /// Compteur de tours, pour que chaque appui ait sa propre animation.
  private var spinCounter = 0
  /// Fin de la file de tours, dans le temps local de `shipSpin`.
  private var spinQueue = StarshipSpinQueue()
  /// Fin du fondu en cours. `nil` quand le ciel du dessous est le ciel courant.
  private var skyboxFadeEndsAt: TimeInterval?
  /// Rotation z déjà posée sur `shipAim`. 0 : nez vers le haut.
  private var currentAimRotation = 0.0
  private let gaugeFill = CALayer()
  /// Dernier plafond connu, pour ne pas relancer la pulsation à chaque frame.
  private var gaugeAtCap = false
  /// La pulsation s’ajoute après la transaction : dedans, `setDisableActions` la jette au commit.
  private var gaugePulsePending = false
  private var contentsScale: CGFloat
  private var targetsByID: [Int: TargetView] = [:]

  private struct TargetView {
    let root: CALayer
    let label: String?
  }

  private static let warpKey = "warp"
  private static let skyboxFadeKey = "skyboxFade"
  /// Sprite 9 × 54 px agrandi 1,6 fois.
  private static let boltSize = CGSize(width: 14, height: 86)
  private static let burstSide: CGFloat = 120
  private static let debrisSide: CGFloat = 24
  private static let debrisLifetime = 0.5
  private static let glyphPopDuration = 0.3
  private static let muzzleSide: CGFloat = 28
  private static let muzzleDuration = 0.12
  private static let gaugeSize = CGSize(width: 28, height: 220)
  private static let gaugeFromRight: CGFloat = 70
  private static let gaugeBottom: CGFloat = 116
  private static let gaugeCornerRadius: CGFloat = 14
  private static let gaugeFillOrigin = CGPoint(x: 4, y: 4)
  private static let gaugeFillWidth: CGFloat = 20
  private static let gaugeFillSpan: CGFloat = 212
  private static let gaugeFillCornerRadius: CGFloat = 10
  private static let gaugePulseKey = "pulse"

  init(tuning: StarshipTuning, scale: CGFloat) {
    self.tuning = tuning
    contentsScale = scale
    configureSkybox(skyboxBack, zPosition: 0)
    configureSkybox(skyboxFront, zPosition: 1)
    skyboxFront.opacity = 0
    installShip(scale: scale)
    installGauge()
  }

  func setBounds(_ bounds: CGRect, scale: CGFloat) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skyboxBack.frame = bounds
    skyboxFront.frame = bounds
    let center = StarshipShip.center(
      width: Double(bounds.width),
      height: Double(bounds.height),
      fractionFromBottom: tuning.shipCenterFromBottom
    )
    shipRoot.position = CGPoint(x: center.x, y: center.y)
    gaugeTrack.frame = CGRect(
      x: bounds.width - Self.gaugeFromRight,
      y: Self.gaugeBottom,
      width: Self.gaugeSize.width,
      height: Self.gaugeSize.height
    )
    contentsScale = scale
    shipSprite.contentsScale = scale
    gaugeTrack.contentsScale = scale
    gaugeFill.contentsScale = scale
    for target in targetsByID.values {
      for child in target.root.sublayers ?? [] {
        child.contentsScale = scale
      }
    }
    CATransaction.commit()
  }

  /// Hauteur et couleur à chaque tick. La pulsation ne redémarre que si `atCap` change.
  func updateGauge(level: Double, color: StarshipRGB, atCap: Bool) {
    let clamped = min(1, max(0, level))
    let shown = atCap ? StarshipRGB(hex: 0xFF0000) : color
    gaugeFill.frame = CGRect(
      x: Self.gaugeFillOrigin.x,
      y: Self.gaugeFillOrigin.y,
      width: Self.gaugeFillWidth,
      height: Self.gaugeFillSpan * CGFloat(clamped)
    )
    gaugeFill.backgroundColor = Self.cgColor(shown)
    guard atCap != gaugeAtCap else { return }
    gaugeAtCap = atCap
    if atCap {
      gaugeTrack.shadowOpacity = 0.9
      gaugePulsePending = true
    } else {
      gaugeTrack.shadowOpacity = 0
      gaugePulsePending = false
      gaugeTrack.removeAnimation(forKey: Self.gaugePulseKey)
    }
  }

  /// À appeler une fois les actions réactivées.
  func installPendingGaugePulse() {
    guard gaugePulsePending else { return }
    gaugePulsePending = false
    gaugeTrack.add(Self.gaugePulse(), forKey: Self.gaugePulseKey)
  }

  func showGauge() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    gaugeTrack.isHidden = false
    CATransaction.commit()
  }

  func hideGauge() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    gaugeTrack.isHidden = true
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

  /// Un tour complet sur `shipSpin`, sens horaire. Les tours s’enchaînent :
  /// un nouvel appui allonge la toupie, il ne la remplace pas et ne l’accélère pas.
  /// Au-delà de `maxBacklog` secondes de tours en attente, l’appui est ignoré.
  func spin(duration: Double, maxBacklog: Double) {
    let now = shipSpin.convertTime(CACurrentMediaTime(), from: nil)
    guard let start = spinQueue.addTurn(now: now, duration: duration, maxBacklog: maxBacklog) else { return }
    let turn = CABasicAnimation(keyPath: "transform.rotation.z")
    turn.fromValue = 0
    turn.toValue = -2 * Double.pi
    turn.duration = duration
    turn.isAdditive = true
    turn.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    if start > now {
      turn.beginTime = start
    }
    shipSpin.add(turn, forKey: "spin-\(spinCounter)")
    spinCounter += 1
  }

  /// Angle de visée actuel : 0 = vers la droite. `π/2` tant que le vaisseau n’a pas pivoté.
  var aimAngle: Double {
    currentAimRotation + .pi / 2
  }

  /// Hauteur du sprite, en points. Le nez est à la moitié de cette hauteur du centre.
  var shipHeight: CGFloat {
    shipRoot.bounds.height
  }

  /// Tourne `shipAim` vers `angle` par le chemin le plus court.
  func aimShip(at angle: Double, duration: Double) {
    let rotation = StarshipAim.nearestEquivalent(of: angle - .pi / 2, to: currentAimRotation)
    let turn = CABasicAnimation(keyPath: "transform.rotation.z")
    turn.fromValue = currentAimRotation
    turn.toValue = rotation
    turn.duration = duration
    turn.timingFunction = CAMediaTimingFunction(name: .easeOut)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    shipAim.setValue(rotation, forKeyPath: "transform.rotation.z")
    CATransaction.commit()
    shipAim.add(turn, forKey: "aim")
    currentAimRotation = rotation
  }

  /// Rayon bleu de `start` à `end`. Invisible pendant `delay` (le vaisseau pivote), puis un flash qui s’éteint.
  func fireBeam(from start: CGPoint, to end: CGPoint, delay: Double, duration: Double, now: TimeInterval) {
    addEphemeral(
      beamLayer(from: start, to: end, delay: delay, duration: duration),
      lifetime: delay + duration + 0.05,
      now: now
    )
  }

  /// Projectile bleu de `start` à `end`. Il attend au nez pendant `delay`, le temps de viser.
  func fireBolt(from start: CGPoint, to end: CGPoint, angle: Double, duration: Double, delay: Double) {
    let now = ProcessInfo.processInfo.systemUptime
    let departsAt = CACurrentMediaTime() + delay
    addEphemeral(
      boltLayer(from: start, to: end, angle: angle, duration: duration, departsAt: departsAt),
      lifetime: delay + duration + 0.05,
      now: now
    )
    addEphemeral(
      muzzleFlash(at: start, departsAt: departsAt),
      lifetime: delay + Self.muzzleDuration + 0.05,
      now: now
    )
  }

  /// Cible au bord de l’écran : sprite orienté selon sa sorte, glyphe droit par-dessus.
  func addTarget(
    id: Int,
    kind: StarshipTargetKind,
    sprite: String,
    label: String?,
    at point: CGPoint,
    heading: Double
  ) {
    let root = CALayer()
    root.zPosition = 10
    let spriteLayer = targetSprite(named: sprite, kind: kind, heading: heading)
    let size = spriteLayer.bounds.size
    root.bounds = CGRect(origin: .zero, size: size)
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    spriteLayer.position = center
    root.addSublayer(spriteLayer)
    if let label {
      root.addSublayer(glyphLayer(label, at: center))
    }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    root.position = point
    skyboxBack.superlayer?.addSublayer(root)
    CATransaction.commit()
    if kind == .meteor {
      spriteLayer.add(Self.meteorSpin(), forKey: "spin")
    }
    targetsByID[id] = TargetView(root: root, label: label)
  }

  func moveTarget(id: Int, to point: CGPoint) {
    targetsByID[id]?.root.position = point
  }

  /// Retire la cible et joue l’explosion là où elle se trouvait.
  func explodeTarget(id: Int, kind: StarshipTargetKind, now: TimeInterval) {
    guard let flying = targetsByID.removeValue(forKey: id) else { return }
    let point = flying.root.position
    flying.root.removeFromSuperlayer()
    addEphemeral(burst(at: point), lifetime: tuning.explosionDuration, now: now)
    for _ in 0..<5 {
      guard let debris = debris(kind: kind, from: point) else { continue }
      addEphemeral(debris, lifetime: Self.debrisLifetime, now: now)
    }
    if let label = flying.label {
      let pop = glyphLayer(label, at: point)
      pop.zPosition = 31
      pop.opacity = 0
      pop.add(Self.glyphPop(), forKey: "pop")
      addEphemeral(pop, lifetime: Self.glyphPopDuration, now: now)
    }
  }

  /// Décor : une seule animation linéaire de position, du départ à l’arrivée.
  /// Un trait est un calque de couleur unie, sans image. `mediaBeginTime` est l’instant de média
  /// commun à tous les écrans. Pas de glyphe, pas de cible, pas de flash.
  func addScenery(
    _ element: StarshipSceneryElement,
    on screen: TerminalScreen,
    mediaBeginTime: CFTimeInterval
  ) {
    guard element.duration > 0, let scene = skyboxFront.superlayer else { return }
    let layer = sceneryLayer(element, on: screen, mediaBeginTime: mediaBeginTime)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    if let shipIndex = scene.sublayers?.firstIndex(where: { $0 === shipRoot }) {
      scene.insertSublayer(layer, at: UInt32(shipIndex))
    } else {
      scene.addSublayer(layer)
    }
    CATransaction.commit()
    ephemerals.append((layer: layer, endsAt: element.start + element.duration))
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
    gaugeTrack.removeAnimation(forKey: Self.gaugePulseKey)
    for target in targetsByID.values {
      target.root.removeFromSuperlayer()
    }
    targetsByID.removeAll(keepingCapacity: false)
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
    gaugeTrack.removeFromSuperlayer()
    skyboxFront.removeFromSuperlayer()
    skyboxBack.removeFromSuperlayer()
  }

  private func sceneryLayer(
    _ element: StarshipSceneryElement,
    on screen: TerminalScreen,
    mediaBeginTime: CFTimeInterval
  ) -> CALayer {
    let layer = CALayer()
    if element.layer == .speedStreak {
      layer.bounds = CGRect(x: 0, y: 0, width: element.width, height: element.size)
      layer.backgroundColor = Self.cgColor(tuning.speedStreakColor)
    } else {
      let image = StarshipSprite.cgImage(named: element.sprite)
      let size = Self.spriteSize(width: element.size, image: image)
      layer.bounds = CGRect(origin: .zero, size: size)
      layer.contents = image
      layer.contentsGravity = .resizeAspect
    }
    layer.contentsScale = contentsScale
    layer.opacity = Float(element.opacity)
    layer.zPosition = Self.sceneryZPosition(element.layer)

    let start = element.localPoint(at: element.start, on: screen)
    let arrival = element.localPoint(at: element.start + element.duration, on: screen)
    let from = CGPoint(x: start.x, y: start.y)
    let to = CGPoint(x: arrival.x, y: arrival.y)
    let flight = CABasicAnimation(keyPath: "position")
    flight.fromValue = from
    flight.toValue = to
    flight.beginTime = mediaBeginTime
    flight.duration = element.duration
    flight.timingFunction = CAMediaTimingFunction(name: .linear)
    flight.fillMode = .backwards
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    layer.position = to
    CATransaction.commit()
    layer.add(flight, forKey: "flight")
    return layer
  }

  /// Planètes, puis astéroïdes, devant le ciel (`skyboxFront` à 1) et derrière les cibles (10)
  /// et le vaisseau (20). Le trait passe devant eux, sous les explosions (30) et la jauge (40).
  /// C’est un calque : le clic reste sur la vue de la scène.
  private static func sceneryZPosition(_ layer: StarshipSceneryLayer) -> CGFloat {
    switch layer {
    case .planet: 2
    case .farAsteroid: 3
    case .nearAsteroid: 4
    case .speedStreak: 25
    }
  }

  private func targetSprite(named name: String, kind: StarshipTargetKind, heading: Double) -> CALayer {
    let image = StarshipSprite.cgImage(named: name)
    let size = Self.spriteSize(width: tuning.targetWidth, image: image)
    let sprite = CALayer()
    sprite.bounds = CGRect(origin: .zero, size: size)
    sprite.contents = image
    sprite.contentsGravity = .resizeAspect
    sprite.contentsScale = contentsScale
    if kind == .enemy {
      sprite.setValue(heading + .pi / 2, forKeyPath: "transform.rotation.z")
    }
    return sprite
  }

  private func glyphLayer(_ label: String, at point: CGPoint) -> CATextLayer {
    let size = CGFloat(tuning.glyphFontSize)
    let font = Self.roundedBlackFont(size: size)
    let attributed = NSAttributedString(string: label, attributes: [
      .font: font,
      .foregroundColor: NSColor.white,
      .strokeColor: NSColor.black,
      .strokeWidth: -4.0,
    ])
    let measured = attributed.size()
    let height = size * 1.25
    let width = max(ceil(measured.width) + 8, height)
    let layer = CATextLayer()
    layer.string = attributed
    layer.alignmentMode = .center
    layer.contentsScale = contentsScale
    layer.isWrapped = false
    layer.bounds = CGRect(x: 0, y: 0, width: width, height: height)
    layer.position = point
    layer.zPosition = 1
    return layer
  }

  private func burst(at point: CGPoint) -> CALayer {
    let layer = CALayer()
    layer.contents = StarshipSprite.cgImage(named: StarshipCatalog.explosionSprite)
    layer.bounds = CGRect(x: 0, y: 0, width: Self.burstSide, height: Self.burstSide)
    layer.position = point
    layer.zPosition = 30
    layer.contentsGravity = .resizeAspect
    layer.contentsScale = contentsScale
    layer.setValue(Double.random(in: 0..<(2 * .pi)), forKeyPath: "transform.rotation.z")
    layer.opacity = 0
    layer.add(Self.burstAnimation(duration: tuning.explosionDuration), forKey: "burst")
    return layer
  }

  private func debris(kind: StarshipTargetKind, from point: CGPoint) -> CALayer? {
    let names = StarshipCatalog.debrisSprites.filter { name in
      kind == .meteor ? name.hasPrefix("meteor") : name.hasPrefix("star")
    }
    guard let name = names.randomElement() else { return nil }
    let layer = CALayer()
    layer.contents = StarshipSprite.cgImage(named: name)
    layer.bounds = CGRect(x: 0, y: 0, width: Self.debrisSide, height: Self.debrisSide)
    layer.zPosition = 30
    layer.contentsGravity = .resizeAspect
    layer.contentsScale = contentsScale
    layer.opacity = 0
    let angle = Double.random(in: 0..<(2 * .pi))
    let distance = CGFloat.random(in: 60...120)
    let end = CGPoint(
      x: point.x + CGFloat(cos(angle)) * distance,
      y: point.y + CGFloat(sin(angle)) * distance
    )
    layer.position = end
    layer.add(Self.debrisFlight(from: point, to: end), forKey: "debris")
    return layer
  }

  private static func meteorSpin() -> CABasicAnimation {
    let spin = CABasicAnimation(keyPath: "transform.rotation.z")
    spin.fromValue = 0
    spin.toValue = (Bool.random() ? 1.0 : -1.0) * 2 * Double.pi
    spin.duration = Double.random(in: 3...7)
    spin.repeatCount = .infinity
    spin.timingFunction = CAMediaTimingFunction(name: .linear)
    return spin
  }

  private static func burstAnimation(duration: Double) -> CAAnimationGroup {
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 0.3
    scale.toValue = 1.3
    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1
    fade.toValue = 0
    let group = CAAnimationGroup()
    group.animations = [scale, fade]
    group.duration = duration
    group.fillMode = .both
    group.isRemovedOnCompletion = false
    return group
  }

  private static func debrisFlight(from start: CGPoint, to end: CGPoint) -> CAAnimationGroup {
    let move = CABasicAnimation(keyPath: "position")
    move.fromValue = start
    move.toValue = end
    let spin = CABasicAnimation(keyPath: "transform.rotation.z")
    spin.fromValue = 0
    spin.toValue = (Bool.random() ? 1.0 : -1.0) * 2 * Double.pi
    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1
    fade.toValue = 0
    let group = CAAnimationGroup()
    group.animations = [move, spin, fade]
    group.duration = debrisLifetime
    group.fillMode = .both
    group.isRemovedOnCompletion = false
    return group
  }

  private static func glyphPop() -> CAAnimationGroup {
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 1
    scale.toValue = 1.6
    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1
    fade.toValue = 0
    let group = CAAnimationGroup()
    group.animations = [scale, fade]
    group.duration = glyphPopDuration
    group.fillMode = .both
    group.isRemovedOnCompletion = false
    return group
  }

  private static func roundedBlackFont(size: CGFloat) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: .black)
    guard let descriptor = base.fontDescriptor.withDesign(.rounded),
      let rounded = NSFont(descriptor: descriptor, size: size)
    else { return base }
    return rounded
  }

  private func beamLayer(from start: CGPoint, to end: CGPoint, delay: Double, duration: Double) -> CALayer {
    let offsetX = Double(end.x - start.x)
    let offsetY = Double(end.y - start.y)
    let angle = atan2(offsetY, offsetX)
    let beam = CALayer()
    beam.contents = StarshipSprite.cgImage(named: StarshipCatalog.beamSprite)
    beam.contentsGravity = .resize
    beam.contentsScale = contentsScale
    beam.anchorPoint = CGPoint(x: 0.5, y: 0)
    beam.bounds = CGRect(x: 0, y: 0, width: Self.boltSize.width, height: hypot(offsetX, offsetY))
    beam.position = start
    beam.zPosition = 15
    beam.opacity = 0
    beam.setValue(angle - .pi / 2, forKeyPath: "transform.rotation.z")

    let flash = CAKeyframeAnimation(keyPath: "opacity")
    flash.values = [1, 1, 0]
    flash.keyTimes = [0, 0.3, 1]
    flash.beginTime = CACurrentMediaTime() + delay
    flash.duration = duration
    flash.fillMode = .removed
    beam.add(flash, forKey: "beam")
    return beam
  }

  private func boltLayer(
    from start: CGPoint,
    to end: CGPoint,
    angle: Double,
    duration: Double,
    departsAt: CFTimeInterval
  ) -> CALayer {
    let bolt = CALayer()
    bolt.contents = StarshipSprite.cgImage(named: StarshipCatalog.beamSprite)
    bolt.bounds = CGRect(origin: .zero, size: Self.boltSize)
    bolt.zPosition = 15
    bolt.contentsGravity = .resize
    bolt.contentsScale = contentsScale
    bolt.setValue(angle - .pi / 2, forKeyPath: "transform.rotation.z")

    let flight = CABasicAnimation(keyPath: "position")
    flight.fromValue = start
    flight.toValue = end
    flight.beginTime = departsAt
    flight.duration = duration
    flight.fillMode = .backwards
    flight.timingFunction = CAMediaTimingFunction(name: .linear)
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    bolt.position = end
    CATransaction.commit()
    bolt.add(flight, forKey: "flight")
    return bolt
  }

  /// Éclair `star1` au nez, invisible jusqu’au départ du tir.
  private func muzzleFlash(at point: CGPoint, departsAt: CFTimeInterval) -> CALayer {
    let flash = CALayer()
    flash.contents = StarshipSprite.cgImage(named: "star1")
    flash.bounds = CGRect(x: 0, y: 0, width: Self.muzzleSide, height: Self.muzzleSide)
    flash.zPosition = 16
    flash.contentsGravity = .resize
    flash.contentsScale = contentsScale
    flash.opacity = 0
    flash.position = point

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1
    fade.toValue = 0
    fade.duration = Self.muzzleDuration
    let grow = CABasicAnimation(keyPath: "transform.scale")
    grow.fromValue = 0.6
    grow.toValue = 1.4
    grow.duration = Self.muzzleDuration
    let burst = CAAnimationGroup()
    burst.animations = [fade, grow]
    burst.duration = Self.muzzleDuration
    burst.beginTime = departsAt
    flash.add(burst, forKey: "muzzle")
    return flash
  }

  private func installGauge() {
    gaugeTrack.bounds = CGRect(origin: .zero, size: Self.gaugeSize)
    gaugeTrack.cornerRadius = Self.gaugeCornerRadius
    gaugeTrack.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
    gaugeTrack.borderWidth = 2
    gaugeTrack.borderColor = NSColor.white.withAlphaComponent(0.40).cgColor
    gaugeTrack.zPosition = 40
    gaugeTrack.isHidden = true
    gaugeTrack.shadowColor = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1).cgColor
    gaugeTrack.shadowRadius = 12
    gaugeTrack.shadowOffset = .zero
    gaugeTrack.shadowOpacity = 0
    gaugeTrack.shadowPath = CGPath(
      roundedRect: CGRect(origin: .zero, size: Self.gaugeSize),
      cornerWidth: Self.gaugeCornerRadius,
      cornerHeight: Self.gaugeCornerRadius,
      transform: nil
    )
    gaugeFill.cornerRadius = Self.gaugeFillCornerRadius
    gaugeFill.frame = CGRect(
      x: Self.gaugeFillOrigin.x,
      y: Self.gaugeFillOrigin.y,
      width: Self.gaugeFillWidth,
      height: 0
    )
    gaugeTrack.addSublayer(gaugeFill)
  }

  private static func gaugePulse() -> CABasicAnimation {
    let pulse = CABasicAnimation(keyPath: "transform.scale")
    pulse.fromValue = 1.0
    pulse.toValue = 1.08
    pulse.duration = 0.35
    pulse.autoreverses = true
    pulse.repeatCount = .infinity
    return pulse
  }

  private static func cgColor(_ color: StarshipRGB) -> CGColor {
    NSColor(srgbRed: color.red, green: color.green, blue: color.blue, alpha: 1).cgColor
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
    let size = Self.spriteSize(width: tuning.shipWidth, image: image)
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

  private static func spriteSize(width: Double, image: CGImage?) -> CGSize {
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

