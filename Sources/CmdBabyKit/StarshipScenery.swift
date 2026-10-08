import Foundation

/// Profondeur du décor, du plus lointain au plus proche.
/// Une couche plus lointaine est plus lente. Les planètes sont l’exception : lentes, mais immenses.
/// Les traits de vitesse s’ajoutent ici, comme un cas, quand leur ticket arrive.
public enum StarshipSceneryLayer: Hashable, Sendable, CaseIterable {
  case planet
  case farAsteroid
  case nearAsteroid
}

/// Réglages d’une couche : la vitesse vaut `sceneryReferenceSpeed / depth`.
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
  /// Si posée, la traversée dure au plus ce nombre de secondes. La vitesse augmente pour tenir ce plafond.
  public var maximumCrossingDuration: Double?

  public init(
    depth: Double,
    size: Double,
    opacity: Double,
    ceiling: Int,
    meanInterval: Double,
    sizeFractionOfTallestScreen: ClosedRange<Double>? = nil,
    maximumCrossingDuration: Double? = nil
  ) {
    self.depth = depth
    self.size = size
    self.opacity = opacity
    self.ceiling = ceiling
    self.meanInterval = meanInterval
    self.sizeFractionOfTallestScreen = sizeFractionOfTallestScreen
    self.maximumCrossingDuration = maximumCrossingDuration
  }
}

/// Élément de décor, planète ou astéroïde, en coordonnées de l’union des écrans. L’ordonnée décroît de `startY` à `endY`.
public struct StarshipSceneryElement: Equatable, Sendable {
  public let id: Int
  public let layer: StarshipSceneryLayer
  public let sprite: String
  public let x: Double
  public let startY: Double
  public let endY: Double
  public let size: Double
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
    rng: inout R
  ) -> [StarshipSceneryElement] {
    elements.removeAll { now >= $0.start + $0.duration }
    guard let union = Union(screens: screens) else { return [] }

    var launched: [StarshipSceneryElement] = []
    for layer in StarshipSceneryLayer.allCases {
      guard let element = spawn(layer, union: union, now: now, tuning: tuning, rng: &rng) else { continue }
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
    rng: inout R
  ) -> StarshipSceneryElement? {
    let layerTuning = tuning.scenery(for: layer)
    guard layerTuning.ceiling > 0, layerTuning.depth > 0 else { return nil }
    let speed = tuning.sceneryReferenceSpeed / layerTuning.depth
    guard speed > 0, layerTuning.meanInterval > 0 else { return nil }
    let due = nextAppearance[layer] ?? -.infinity
    let flying = elements.filter { $0.layer == layer }.count
    guard now >= due, flying < layerTuning.ceiling else { return nil }

    let sprites = sprites(for: layer)
    guard !sprites.isEmpty else { return nil }
    let size = drawnSize(layerTuning, union: union, rng: &rng)
    guard size > 0 else { return nil }
    let x = Double.random(in: union.minX...union.maxX, using: &rng)
    let pool = spriteChoices(sprites, layer: layer)
    let sprite = pool[Int.random(in: 0..<pool.count, using: &rng)]
    if layer == .planet {
      lastPlanetSprite = sprite
    }
    let startY = union.maxY + size / 2
    let endY = union.minY - size / 2
    let id = nextID
    nextID += 1
    // Écart dans [0,5 ; 1,5] fois la moyenne : l’espérance reste le réglage, sans rafale.
    nextAppearance[layer] = now + layerTuning.meanInterval * Double.random(in: 0.5...1.5, using: &rng)
    let travel = startY - endY
    var duration = travel / speed
    if let limit = layerTuning.maximumCrossingDuration, limit > 0 {
      duration = min(duration, limit)
    }
    return StarshipSceneryElement(
      id: id,
      layer: layer,
      sprite: sprite,
      x: x,
      startY: startY,
      endY: endY,
      size: size,
      opacity: layerTuning.opacity,
      start: now,
      duration: duration
    )
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
