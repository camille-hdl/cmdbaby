import Foundation

/// Vitesse, densité et plafonds de la pluie. Le director ne lit que cette valeur.
public struct TerminalRainTuning: Equatable, Sendable {
  /// Intervalle entre deux cellules d’une colonne (s). Plus petit = plus rapide.
  public var stepIntervalRange: ClosedRange<Double>
  /// Multiplicateur global de vitesse : 1 = valeur du film ; 2 = deux fois plus rapide.
  public var speedMultiplier: Double {
    didSet { speedMultiplier = Self.clampedSpeed(speedMultiplier) }
  }

  /// Durée de vie d’une cellule de traîne (s), tirée par colonne.
  public var trailLifetimeRange: ClosedRange<Double>
  public var flickerProbabilityPerTick: Double
  public var waveColumnRange: ClosedRange<Int>
  public var maxActiveColumns: Int
  public var maxLiveCellsPerScreen: Int

  public static let standard = TerminalRainTuning()

  public init(
    stepIntervalRange: ClosedRange<Double> = (1.0 / 24)...(1.0 / 14),
    speedMultiplier: Double = 1,
    trailLifetimeRange: ClosedRange<Double> = 1.2...2.0,
    flickerProbabilityPerTick: Double = 0.02,
    waveColumnRange: ClosedRange<Int> = 3...6,
    maxActiveColumns: Int = 400,
    maxLiveCellsPerScreen: Int = 20_000
  ) {
    self.stepIntervalRange = stepIntervalRange
    self.speedMultiplier = Self.clampedSpeed(speedMultiplier)
    self.trailLifetimeRange = trailLifetimeRange
    self.flickerProbabilityPerTick = flickerProbabilityPerTick
    self.waveColumnRange = waveColumnRange
    self.maxActiveColumns = maxActiveColumns
    self.maxLiveCellsPerScreen = maxLiveCellsPerScreen
  }

  /// Intervalle effectif d’une colonne. `roll` est dans `[0, 1)`.
  public func stepInterval(roll: Double) -> Double {
    interpolated(stepIntervalRange, roll: roll) / speedMultiplier
  }

  /// Durée de vie d’une cellule, tirée dans `trailLifetimeRange`. `roll` est dans `[0, 1)`.
  public func trailLifetime(roll: Double) -> Double {
    interpolated(trailLifetimeRange, roll: roll)
  }

  private func interpolated(_ range: ClosedRange<Double>, roll: Double) -> Double {
    let unit = min(max(roll, 0), 1)
    return range.lowerBound + unit * (range.upperBound - range.lowerBound)
  }

  private static func clampedSpeed(_ speed: Double) -> Double {
    min(max(speed, 0.25), 4)
  }
}
