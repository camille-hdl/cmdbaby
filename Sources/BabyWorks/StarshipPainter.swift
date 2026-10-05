import AppKit
import BabyWorkDiagnosticsKit
import QuartzCore

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
  /// Fin de la file de tours, dans le temps local de `shipSpin`.
  private var spinQueue = StarshipSpinQueue()
  /// Fin du fondu en cours. `nil` quand le ciel du dessous est le ciel courant.
  private var skyboxFadeEndsAt: TimeInterval?
  /// Rotation z déjà posée sur `shipAim`. 0 : nez vers le haut.
  private var currentAimRotation = 0.0
  private var contentsScale: CGFloat

  private static let warpKey = "warp"
  private static let skyboxFadeKey = "skyboxFade"
  /// Sprite 9 × 54 px agrandi 1,6 fois.
  private static let boltSize = CGSize(width: 14, height: 86)
  private static let muzzleSide: CGFloat = 28
  private static let muzzleDuration = 0.12

  init(tuning: StarshipTuning, scale: CGFloat) {
    self.tuning = tuning
    contentsScale = scale
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
    contentsScale = scale
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

  /// Un tour complet sur `shipSpin`, sens horaire. Les tours s’enchaînent :
  /// un nouvel appui allonge la toupie, il ne la remplace pas et ne l’accélère pas.
  func spin(duration: Double) {
    let now = shipSpin.convertTime(CACurrentMediaTime(), from: nil)
    let start = spinQueue.addTurn(now: now, duration: duration)
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

