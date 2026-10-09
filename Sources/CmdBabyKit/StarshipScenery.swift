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
/// le plus haut en `planetMaxCrossing` secondes, sans atteindre la vitesse d’un astéroïde.
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
  /// Nom d’image. `nil` pour un trait : pas de sprite, le painter pose une couleur unie.
  public let sprite: String?
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
  /// Ceux déjà en vol gardent les coordonnées de l’union où ils sont nés, jusqu’à leur sortie.
  /// Brancher ou débrancher un écran ne les recalcule pas : les écrans déjà là ne sautent pas.
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
  /// Leurs coordonnées sont celles de l’union d’origine. `localPoint` les rejoue sur un écran
  /// branché ensuite, à la même hauteur que sur un écran déjà là.
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
    let plan = LayerPlan.plan(for: layer)
    var speed = crossingSpeed(
      plan.travel, tuning: tuning, tallestHeight: union.tallestHeight, depth: layerTuning.depth
    )
    guard speed > 0, layerTuning.meanInterval > 0 else { return nil }
    let due = nextAppearance[layer] ?? -.infinity
    let flying = elements.filter { $0.layer == layer }.count
    guard now >= due, flying < layerTuning.ceiling else { return nil }
    if plan.abscissa == .outsideCorridor, shipAbscissa == nil { return nil }

    let size = drawnSize(layerTuning, union: union, rng: &rng)
    guard size > 0 else { return nil }
    if plan.travel == .clearWithinOneSecond {
      speed = speedStreakSpeed(nominal: speed, tallestHeight: union.tallestHeight, length: size)
    }
    let width = switch plan.picture {
    case .color: tuning.speedStreakWidth
    case .sprites: size
    }
    guard width > 0 else { return nil }
    guard let x = abscissa(
      plan.abscissa,
      union: union,
      shipAbscissa: shipAbscissa,
      corridorWidth: tuning.speedStreakCorridorWidth,
      streakWidth: width,
      rng: &rng
    ) else { return nil }
    guard let drawn = drawnPicture(plan.picture, rng: &rng) else { return nil }
    let sprite: String? = switch drawn {
    case .color: nil
    case .sprite(let name): name
    }
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
    _ rule: LayerPlan.Abscissa,
    union: Union,
    shipAbscissa: Double?,
    corridorWidth: Double,
    streakWidth: Double,
    rng: inout R
  ) -> Double? {
    guard rule == .outsideCorridor, let shipAbscissa else {
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
  /// `nil` si la liste de sprites est vide : l’élément ne part pas.
  private mutating func drawnPicture<R: RandomNumberGenerator>(
    _ picture: LayerPlan.Picture,
    rng: inout R
  ) -> DrawnPicture? {
    switch picture {
    case .color:
      return .color
    case .sprites(let names, let avoidRepeat):
      guard !names.isEmpty else { return nil }
      let pool = avoidRepeat ? choicesSkippingPrevious(names) : names
      let sprite = pool[Int.random(in: 0..<pool.count, using: &rng)]
      if avoidRepeat {
        lastPlanetSprite = sprite
      }
      return .sprite(sprite)
    }
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
  /// Le centre d’une planète traverse la hauteur de l’écran le plus haut
  /// en `planetMaxCrossing` secondes au plus, le bout lent de la bande,
  /// et reste strictement plus lent que les astéroïdes.
  /// Si tenir ce délai rattrapait un astéroïde, la vitesse nominale reste : plus lent, en cas de doute.
  private func crossingSpeed(
    _ travel: LayerPlan.Travel,
    tuning: StarshipTuning,
    tallestHeight: Double,
    depth: Double
  ) -> Double {
    let nominal = tuning.sceneryReferenceSpeed / depth
    guard travel == .planetCap,
      tuning.planetMaxCrossing > 0,
      tuning.farAsteroidScenery.depth > 0,
      tuning.nearAsteroidScenery.depth > 0
    else { return nominal }
    let slowestAsteroid = min(
      tuning.sceneryReferenceSpeed / tuning.farAsteroidScenery.depth,
      tuning.sceneryReferenceSpeed / tuning.nearAsteroidScenery.depth
    )
    let speedToMeetTheCap = tallestHeight / tuning.planetMaxCrossing
    let raised = max(nominal, speedToMeetTheCap)
    guard raised < slowestAsteroid else { return nominal }
    return raised
  }

  /// La planète qui vient de partir sort du tirage. Une liste d’une seule entrée reste tirable.
  private func choicesSkippingPrevious(_ sprites: [String]) -> [String] {
    guard let lastPlanetSprite else { return sprites }
    let others = sprites.filter { $0 != lastPlanetSprite }
    return others.isEmpty ? sprites : others
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

/// Image, abscisse et vitesse d’une couche. Ajouter une couche, c’est un cas de ce `switch`.
private struct LayerPlan {
  enum Picture {
    /// Trait : pas de sprite, épaisseur `speedStreakWidth`.
    case color
    /// Noms tirés au sort. `avoidRepeat` écarte le sprite précédent (planètes).
    case sprites([String], avoidRepeat: Bool)
  }

  enum Travel: Equatable {
    case nominal
    case planetCap
    case clearWithinOneSecond
  }

  enum Abscissa: Equatable {
    case anywhere
    case outsideCorridor
  }

  var picture: Picture
  var travel: Travel
  var abscissa: Abscissa

  static func plan(for layer: StarshipSceneryLayer) -> LayerPlan {
    switch layer {
    case .planet:
      LayerPlan(
        picture: .sprites(StarshipCatalog.planets, avoidRepeat: true),
        travel: .planetCap,
        abscissa: .anywhere
      )
    case .farAsteroid, .nearAsteroid:
      LayerPlan(
        picture: .sprites(StarshipCatalog.sprites(for: .meteor), avoidRepeat: false),
        travel: .nominal,
        abscissa: .anywhere
      )
    case .speedStreak:
      LayerPlan(
        picture: .color,
        travel: .clearWithinOneSecond,
        abscissa: .outsideCorridor
      )
    }
  }
}

/// Résultat d’un tirage d’image. `.color` : le trait, `sprite` reste `nil`.
private enum DrawnPicture {
  case color
  case sprite(String)
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
