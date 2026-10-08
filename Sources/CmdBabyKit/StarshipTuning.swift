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
  /// Profondeur 6 : 80 / 6 pt/s, tant que la traversée tient en 90 s.
  /// Au-delà, ce plafond prime et la planète accélère, même au-delà des astéroïdes lointains.
  /// La taille est tirée entre 30 et 60 % de l’écran le plus haut. Au plus deux en vol, intervalle moyen de 90 s.
  public var planetScenery = StarshipSceneryLayerTuning(
    depth: 6,
    size: 0,
    opacity: 0.7,
    ceiling: 2,
    meanInterval: 90,
    sizeFractionOfTallestScreen: 0.30...0.60,
    maximumCrossingDuration: 90
  )

  // Jauge
  public var keyRateWindow: Double = 10
  public var keyRateCap: Double = 300

  public init() {}

  public func scenery(for layer: StarshipSceneryLayer) -> StarshipSceneryLayerTuning {
    switch layer {
    case .planet: planetScenery
    case .farAsteroid: farAsteroidScenery
    case .nearAsteroid: nearAsteroidScenery
    }
  }
}
