import Foundation

/// Profondeur du décor, du plus lointain au plus proche.
/// Une couche plus lointaine est plus lente. Les planètes sont l’exception : lentes, mais immenses.
/// Les traits de vitesse sont les plus proches, et les plus rapides.
public enum StarshipSceneryLayer: Hashable, Sendable, CaseIterable {
  case planet
  case farAsteroid
  case nearAsteroid
  case speedStreak
}

/// Réglages d’une couche. La vitesse nominale vaut `sceneryReferenceSpeed / depth`.
/// Une planète peut aller plus vite pour que son centre traverse la hauteur de l’écran
/// le plus haut en 90 s, sans atteindre la vitesse d’un astéroïde.
public struct StarshipSceneryLayerTuning: Equatable, Sendable {
  public var depth: Double
  public var size: Double
  public var opacity: Double
  /// Nombre maximal d’éléments de cette couche en vol en même temps.
  public var ceiling: Int
  /// Secondes moyennes entre deux apparitions.
  public var meanInterval: Double
  /// Si posée, chaque élément tire sa taille dans cette fraction de la hauteur de l’écran le plus haut.
  /// `size` est alors ignorée.
  public var sizeFractionOfTallestScreen: ClosedRange<Double>?

  public init(
    depth: Double,
    size: Double,
    opacity: Double,
    ceiling: Int,
    meanInterval: Double,
    sizeFractionOfTallestScreen: ClosedRange<Double>? = nil
  ) {
    self.depth = depth
    self.size = size
    self.opacity = opacity
    self.ceiling = ceiling
    self.meanInterval = meanInterval
    self.sizeFractionOfTallestScreen = sizeFractionOfTallestScreen
  }
}

/// Élément de décor en coordonnées de l’union des écrans. L’ordonnée décroît de `startY` à `endY`.
/// `size` est le côté du sprite, ou la longueur du trait. `width` est l’épaisseur horizontale :
/// le même côté pour un sprite, 1 à 3 pt pour un trait.
public struct StarshipSceneryElement: Equatable, Sendable {
  public let id: Int
  public let layer: StarshipSceneryLayer
  public let sprite: String
  public let x: Double
  public let startY: Double
  public let endY: Double
  public let size: Double
  public let width: Double
  public let opacity: Double
  public let start: TimeInterval
  public let duration: TimeInterval

  public func ordinate(at time: TimeInterval) -> Double {
    guard duration > 0 else { return startY }
    let progress = min(1, max(0, (time - start) / duration))
    return startY + (endY - startY) * progress
  }

  /// Position sur `screen` : l’union, moins l’origine de l’écran.
  public func localPoint(at time: TimeInterval, on screen: TerminalScreen) -> StarshipPoint {
    StarshipPoint(x: x - screen.x, y: ordinate(at: time) - screen.y)
  }
}

/// Apparitions du décor, communes à tous les écrans. Le tick ne fait que demander les nouveaux éléments.
public struct StarshipScenery: Equatable, Sendable {
  private var elements: [StarshipSceneryElement] = []
  private var nextAppearance: [StarshipSceneryLayer: TimeInterval] = [:]
  private var nextID = 0
  /// Dernière planète partie, pour ne pas la tirer deux fois de suite.
  private var lastPlanetSprite: String?

  public init() {}

  /// Nouveaux éléments à lancer à `now`. Au plus un par couche, sous le plafond.
  public mutating func launch<R: RandomNumberGenerator>(
    screens: [TerminalScreen],
    now: TimeInterval,
    tuning: StarshipTuning,
    shipAbscissa: Double? = nil,
    rng: inout R
  ) -> [StarshipSceneryElement] {
    elements.removeAll { now >= $0.start + $0.duration }
    guard let union = Union(screens: screens) else { return [] }

    var launched: [StarshipSceneryElement] = []
    for layer in StarshipSceneryLayer.allCases {
      guard let element = spawn(
        layer, union: union, now: now, tuning: tuning, shipAbscissa: shipAbscissa, rng: &rng
      ) else { continue }
      elements.append(element)
      launched.append(element)
    }
    return launched
  }

  /// Éléments dont la traversée contient `time`, départ inclus, arrivée exclue.
  public func flying(at time: TimeInterval) -> [StarshipSceneryElement] {
    elements.filter { time >= $0.start && time < $0.start + $0.duration }
  }

  public mutating func reset() {
    elements.removeAll(keepingCapacity: false)
    nextAppearance.removeAll(keepingCapacity: false)
    nextID = 0
    lastPlanetSprite = nil
  }

  private mutating func spawn<R: RandomNumberGenerator>(
    _ layer: StarshipSceneryLayer,
    union: Union,
    now: TimeInterval,
    tuning: StarshipTuning,
    shipAbscissa: Double?,
    rng: inout R
  ) -> StarshipSceneryElement? {
    let layerTuning = tuning.scenery(for: layer)
    guard layerTuning.ceiling > 0, layerTuning.depth > 0 else { return nil }
    var speed = crossingSpeed(layer, tuning: tuning, tallestHeight: union.tallestHeight)
    guard speed > 0, layerTuning.meanInterval > 0 else { return nil }
    let due = nextAppearance[layer] ?? -.infinity
    let flying = elements.filter { $0.layer == layer }.count
    guard now >= due, flying < layerTuning.ceiling else { return nil }
    if layer == .speedStreak, shipAbscissa == nil { return nil }

    let size = drawnSize(layerTuning, union: union, rng: &rng)
    guard size > 0 else { return nil }
    if layer == .speedStreak {
      speed = speedStreakSpeed(nominal: speed, tallestHeight: union.tallestHeight, length: size)
    }
    let width = layer == .speedStreak ? tuning.speedStreakWidth : size
    guard width > 0 else { return nil }
    guard let x = abscissa(
      layer,
      union: union,
      shipAbscissa: shipAbscissa,
      corridorWidth: tuning.speedStreakCorridorWidth,
      streakWidth: width,
      rng: &rng
    ) else { return nil }
    let sprite = drawnSprite(layer, rng: &rng)
    guard let sprite else { return nil }
    let startY = union.maxY + size / 2
    let endY = union.minY - size / 2
    let id = nextID
    nextID += 1
    // Écart dans [0,5 ; 1,5] fois la moyenne : l’espérance reste le réglage, sans rafale.
    nextAppearance[layer] = now + layerTuning.meanInterval * Double.random(in: 0.5...1.5, using: &rng)
    return StarshipSceneryElement(
      id: id,
      layer: layer,
      sprite: sprite,
      x: x,
      startY: startY,
      endY: endY,
      size: size,
      width: width,
      opacity: layerTuning.opacity,
      start: now,
      duration: (startY - endY) / speed
    )
  }

  /// Abscisse dans l’union. Un trait reste hors du couloir, épaisseur comprise.
  /// `nil` si le couloir couvre toute la largeur : rien ne part.
  private func abscissa<R: RandomNumberGenerator>(
    _ layer: StarshipSceneryLayer,
    union: Union,
    shipAbscissa: Double?,
    corridorWidth: Double,
    streakWidth: Double,
    rng: inout R
  ) -> Double? {
    guard layer == .speedStreak, let shipAbscissa else {
      return Double.random(in: union.minX...union.maxX, using: &rng)
    }
    let half = corridorWidth / 2 + streakWidth / 2
    let leftEnd = min(union.maxX, shipAbscissa - half)
    let rightStart = max(union.minX, shipAbscissa + half)
    let left = max(0, leftEnd - union.minX)
    let right = max(0, union.maxX - rightStart)
    let total = left + right
    guard total > 0 else { return nil }
    let roll = Double.random(in: 0..<total, using: &rng)
    if roll < left {
      return union.minX + roll
    }
    return rightStart + (roll - left)
  }

  /// Un trait n’a pas d’image. Les autres couches tirent un sprite, sans répéter la planète précédente.
  private mutating func drawnSprite<R: RandomNumberGenerator>(
    _ layer: StarshipSceneryLayer,
    rng: inout R
  ) -> String? {
    if layer == .speedStreak { return "" }
    let sprites = sprites(for: layer)
    guard !sprites.isEmpty else { return nil }
    let pool = spriteChoices(sprites, layer: layer)
    let sprite = pool[Int.random(in: 0..<pool.count, using: &rng)]
    if layer == .planet {
      lastPlanetSprite = sprite
    }
    return sprite
  }

  /// Vitesse du trait : la nominale, relevée s’il le faut pour que l’écran le plus haut,
  /// longueur comprise, soit traversé en moins d’une seconde.
  private func speedStreakSpeed(nominal: Double, tallestHeight: Double, length: Double) -> Double {
    let passage = tallestHeight + max(0, length)
    guard passage > 0 else { return nominal }
    let speed = max(nominal, passage)
    // `passage / passage` vaut 1 : un cran au-dessus garde la traversée strictement sous la seconde.
    if passage / speed >= 1 {
      return speed.nextUp
    }
    return speed
  }

  /// Vitesse en points par seconde. Nominale : `sceneryReferenceSpeed / depth`.
  /// Le centre d’une planète traverse la hauteur de l’écran le plus haut en 90 s au plus,
  /// le bout lent de la bande, et reste strictement plus lent que les astéroïdes.
  /// Si tenir 90 s rattrapait un astéroïde, la vitesse nominale reste : plus lent, en cas de doute.
  private func crossingSpeed(
    _ layer: StarshipSceneryLayer,
    tuning: StarshipTuning,
    tallestHeight: Double
  ) -> Double {
    let nominal = tuning.sceneryReferenceSpeed / tuning.scenery(for: layer).depth
    guard layer == .planet,
      tuning.farAsteroidScenery.depth > 0,
      tuning.nearAsteroidScenery.depth > 0
    else { return nominal }
    let slowestAsteroid = min(
      tuning.sceneryReferenceSpeed / tuning.farAsteroidScenery.depth,
      tuning.sceneryReferenceSpeed / tuning.nearAsteroidScenery.depth
    )
    let neededToCrossInNinetySeconds = tallestHeight / 90
    let raised = max(nominal, neededToCrossInNinetySeconds)
    guard raised < slowestAsteroid else { return nominal }
    return raised
  }

  /// La planète qui vient de partir sort du tirage. Une liste d’une seule entrée reste tirable.
  private func spriteChoices(_ sprites: [String], layer: StarshipSceneryLayer) -> [String] {
    guard layer == .planet, let lastPlanetSprite else { return sprites }
    let others = sprites.filter { $0 != lastPlanetSprite }
    return others.isEmpty ? sprites : others
  }

  private func sprites(for layer: StarshipSceneryLayer) -> [String] {
    switch layer {
    case .planet:
      StarshipCatalog.planets
    case .farAsteroid, .nearAsteroid:
      StarshipCatalog.sprites(for: .meteor)
    case .speedStreak:
      []
    }
  }

  /// Taille fixe, ou fraction tirée de la hauteur de l’écran le plus haut.
  private func drawnSize<R: RandomNumberGenerator>(
    _ tuning: StarshipSceneryLayerTuning,
    union: Union,
    rng: inout R
  ) -> Double {
    guard let fraction = tuning.sizeFractionOfTallestScreen else { return tuning.size }
    guard fraction.lowerBound > 0 else { return 0 }
    return union.tallestHeight * Double.random(in: fraction, using: &rng)
  }
}

private struct Union {
  var minX: Double
  var maxX: Double
  var minY: Double
  var maxY: Double
  /// Hauteur du plus grand écran, pas celle de l’union : des écrans empilés ne grossissent pas les planètes.
  var tallestHeight: Double

  init?(screens: [TerminalScreen]) {
    guard let minX = screens.map(\.x).min(),
      let minY = screens.map(\.y).min(),
      let maxX = screens.map({ $0.x + $0.width }).max(),
      let maxY = screens.map({ $0.y + $0.height }).max(),
      let tallestHeight = screens.map(\.height).max(),
      maxX > minX,
      maxY > minY,
      tallestHeight > 0
    else { return nil }
    self.minX = minX
    self.maxX = maxX
    self.minY = minY
    self.maxY = maxY
    self.tallestHeight = tallestHeight
  }
}
