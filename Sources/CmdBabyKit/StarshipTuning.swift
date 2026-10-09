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
  /// Secondes entre deux ciels. 30 s : un ciel reste moitié moins longtemps qu’à 60 s.
  public var skyboxInterval: Double = 30
  public var skyboxFadeDuration: Double = 2
  /// Marge verticale de la dérive, fraction de la hauteur de l’image.
  /// 0,40 : la moitié de 0,80, puisque le ciel ne reste que 30 s.
  /// La fenêtre garde 60 % de la hauteur (zoom ~1,7×), plus 40 % au-dessus pour un seul aller.
  public var skyboxDriftMargin: Double = 0.40
  /// Durée de l’aller unique pour la session par défaut (3 min), en secondes.
  /// Une autre limite d’adulte passe par `skyboxDriftDuration(timeLimitMinutes:)`.
  /// Sur un écran 1440 × 900, 0,40 / 0,60 × 900 pt = 600 pt. En 180 s, 10/3 pt/s,
  /// sous les 80 pt/s d’une planète. Une session plus longue descend encore plus lentement.
  /// Pas de retour : le ciel ne remonte pas. `y` augmente : le ciel visible descend.
  public var skyboxDriftDuration: Double = StarshipTuning.skyboxDriftDuration(
    timeLimitMinutes: AdultExitSettings.defaultTimeLimitMinutes
  )

  /// Durée de l’aller unique, en secondes : toute la limite de session.
  /// 10 min donne 600 s, donc après 180 s le ciel bouge encore. L’amplitude reste
  /// `skyboxDriftMargin`. Un seul aller : le ciel ne repart pas de zéro et ne remonte pas.
  public static func skyboxDriftDuration(timeLimitMinutes: Int) -> Double {
    Double(timeLimitMinutes) * 60
  }

  // Décor. Une profondeur plus grande est plus loin : la vitesse en découle.
  /// Vitesse d’une couche de profondeur 1, en points par seconde.
  public var sceneryReferenceSpeed: Double = 480
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
  /// Secondes au plus pour que le centre d’une planète traverse la hauteur de l’écran le plus haut.
  /// 90 s : le bout lent. Si ce délai rattrapait un astéroïde, la vitesse nominale reste.
  public var planetMaxCrossing: Double = 90
  /// Profondeur 6 : 480 / 6 = 80 pt/s. Le centre passe en 7,5 s sur 600 pt, en 18 s sur 1 440 pt,
  /// sous les 120 pt/s des astéroïdes lointains. L’entrée-sortie, diamètre compris, dure davantage.
  /// La taille est tirée entre 30 et 60 % de l’écran le plus haut. Au plus deux en vol, intervalle moyen de 90 s.
  public var planetScenery = StarshipSceneryLayerTuning(
    depth: 6,
    size: 0,
    opacity: 0.7,
    ceiling: 2,
    meanInterval: 90,
    sizeFractionOfTallestScreen: 0.30...0.60
  )
  /// Profondeur 0,375 : 480 / 0,375 = 1 280 pt/s. Un trait de 64 pt traverse 600 pt en 0,52 s,
  /// toujours plus vite que les astéroïdes, sans devenir un flash.
  /// Au plus huit en vol, intervalle moyen de 0,125 s : plusieurs traits pâles en même temps.
  /// Opacité 0,2.
  public var speedStreakScenery = StarshipSceneryLayerTuning(
    depth: 0.375,
    size: 64,
    opacity: 0.2,
    ceiling: 8,
    meanInterval: 0.125
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
