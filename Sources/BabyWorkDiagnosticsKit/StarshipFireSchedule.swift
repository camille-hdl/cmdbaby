import Foundation

/// Calendrier du tir automatique : secondes entre l’apparition d’une cible et le rayon.
public enum StarshipFireSchedule: Sendable {
  /// Secondes entre l’apparition de la cible et le tir automatique.
  public static func delay(for flight: StarshipFlight, tuning: StarshipTuning, roll: Double) -> Double {
    let clamped = min(max(roll, 0), 1)
    let span = tuning.fireDelayRange.upperBound - tuning.fireDelayRange.lowerBound
    let desired = tuning.fireDelayRange.lowerBound + clamped * span
    let travel = max(0, flight.totalDistance - tuning.shieldRadius - tuning.fireSafetyMargin)
    let latest = flight.time(toTravel: travel)
    return max(tuning.minimumFireDelay, min(desired, latest))
  }
}
