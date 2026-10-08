import Foundation

/// Réglages numériques du mode Vaisseau. Le director ne lit que cette valeur.
public struct StarshipTuning: Equatable, Sendable {
  public static let standard = StarshipTuning()

  // Vaisseau
  public var shipWidth: Double = 140
  /// Fraction de la hauteur de l’écran, depuis le bas, où se tient le centre du vaisseau.
  /// 0 le pose sur le bord bas, 1 sur le bord haut. 0,18 le laisse au-dessus du bord
  /// et à gauche de la jauge, toupie comprise.
  public var shipCenterFromBottom: Double = 0.18
  public var shipWarpDuration: Double = 0.25
  /// Secondes de session avant d’autoriser un changement d’écran.
  /// Avant cela, le vaisseau reste sur le plus grand, sans warp.
  public var screenChangeDelay: Double = 3
  public var spinDuration: Double = 0.6
  /// Secondes de tours en attente au plus : trois tours. Les appuis au-delà sont ignorés.
  public var spinBacklog: Double = 1.8
  public var aimDuration: Double = 0.1

  // Cibles
  public var targetWidth: Double = 110
  public var glyphFontSize: Double = 56
  public var initialSpeedRange: ClosedRange<Double> = 60...140
  public var accelerationRange: ClosedRange<Double> = 80...220
  public var maxSpeed: Double = 600
  public var shieldRadius: Double = 120
  public var maxTargets: Int = 30

  // Tir
  public var fireDelayRange: ClosedRange<Double> = 2.0...2.6
  public var minimumFireDelay: Double = 2
  public var fireSafetyMargin: Double = 80
  public var boltSpeed: Double = 1800
  public var boltOvershoot: Double = 80
  public var beamDuration: Double = 0.15
  public var explosionDuration: Double = 0.35

  // Skybox
  public var skyboxInterval: Double = 60
  public var skyboxFadeDuration: Double = 2
  /// Marge verticale de la dérive, fraction de la hauteur de l’image. 0,08 : 8 %, entre 5 et 10 %.
  public var skyboxDriftMargin: Double = 0.08
  /// Durée d’un aller de la dérive, en secondes. 180 s : trois minutes, assez lent pour un bébé.
  /// Le retour dure autant ; le tick ne déplace pas le ciel.
  public var skyboxDriftDuration: Double = 180

  // Décor. Une profondeur plus grande est plus loin : la vitesse en découle.
  /// Vitesse d’une couche de profondeur 1, en points par seconde.
  public var sceneryReferenceSpeed: Double = 80
  public var farAsteroidScenery = StarshipSceneryLayerTuning(
    depth: 4,
    size: 56,
    opacity: 0.28,
    ceiling: 2,
    meanInterval: 18
  )
  public var nearAsteroidScenery = StarshipSceneryLayerTuning(
    depth: 2,
    size: 96,
    opacity: 0.5,
    ceiling: 2,
    meanInterval: 12
  )
  /// Profondeur 6 : 80 / 6 pt/s tant que le centre traverse l’écran en 90 s au plus (45 s sur 600 pt).
  /// Sur un écran plus haut, la vitesse monte juste assez (16 pt/s sur 1 440 pt) et reste sous les 20 pt/s
  /// des astéroïdes lointains. L’entrée-sortie, diamètre compris, peut dépasser 90 s.
  /// La taille est tirée entre 30 et 60 % de l’écran le plus haut. Au plus deux en vol, intervalle moyen de 90 s.
  public var planetScenery = StarshipSceneryLayerTuning(
    depth: 6,
    size: 0,
    opacity: 0.7,
    ceiling: 2,
    meanInterval: 90,
    sizeFractionOfTallestScreen: 0.30...0.60
  )
  /// Profondeur 1/16 : 1 280 pt/s. Un trait de 64 pt traverse 600 pt en 0,52 s, toujours plus vite que les astéroïdes.
  /// Au plus deux en vol, intervalle moyen de 3 s, opacité 0,2.
  public var speedStreakScenery = StarshipSceneryLayerTuning(
    depth: 0.0625,
    size: 64,
    opacity: 0.2,
    ceiling: 2,
    meanInterval: 3
  )
  /// Épaisseur du trait, en points. Entre 1 et 3.
  public var speedStreakWidth: Double = 2
  /// Couleur unie du trait. L’opacité faible est celle de la couche, pas un second alpha.
  public var speedStreakColor = StarshipRGB(hex: 0xFFFFFF)
  /// Largeur du couloir, autour de l’abscisse du vaisseau, où aucun trait ne passe.
  /// 200 pt dépasse le vaisseau (140 pt) : le trait file à côté, épaisseur comprise.
  public var speedStreakCorridorWidth: Double = 200

  // Jauge
  public var keyRateWindow: Double = 10
  public var keyRateCap: Double = 300

  public init() {}

  public func scenery(for layer: StarshipSceneryLayer) -> StarshipSceneryLayerTuning {
    switch layer {
    case .planet: planetScenery
    case .farAsteroid: farAsteroidScenery
    case .nearAsteroid: nearAsteroidScenery
    case .speedStreak: speedStreakScenery
    }
  }
}
