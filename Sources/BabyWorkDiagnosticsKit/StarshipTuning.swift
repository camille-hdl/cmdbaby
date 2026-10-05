import Foundation

/// Réglages numériques du mode Vaisseau. Le director ne lit que cette valeur.
public struct StarshipTuning: Equatable, Sendable {
  public static let standard = StarshipTuning()

  // Vaisseau
  public var shipWidth: Double = 140
  public var shipWarpDuration: Double = 0.25
  public var spinDuration: Double = 0.6
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
  public var fireDelayRange: ClosedRange<Double> = 0.5...1.1
  public var minimumFireDelay: Double = 0.5
  public var fireSafetyMargin: Double = 80
  public var boltSpeed: Double = 1800
  public var boltOvershoot: Double = 80
  public var beamDuration: Double = 0.15
  public var explosionDuration: Double = 0.35

  // Skybox
  public var skyboxInterval: Double = 60
  public var skyboxFadeDuration: Double = 2

  // Jauge
  public var keyRateWindow: Double = 10
  public var keyRateCap: Double = 300

  public init() {}
}
