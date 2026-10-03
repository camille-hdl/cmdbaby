import Foundation

/// Durée maximale d’une session de jeu. Au-delà, la sortie de secours se déclenche.
public struct SessionTimeLimit: Equatable, Sendable {
  public let startedAt: TimeInterval
  public let duration: TimeInterval

  public init(startedAt: TimeInterval, duration: TimeInterval) {
    self.startedAt = startedAt
    self.duration = duration
  }

  public init(startedAt: TimeInterval, settings: AdultExitSettings) {
    self.init(
      startedAt: startedAt,
      duration: TimeInterval(settings.timeLimitMinutes) * 60
    )
  }

  /// Portion du contour déjà parcourue, de 0 à 1.
  public func progress(at now: TimeInterval) -> Double {
    guard duration > 0 else { return 1 }
    let elapsed = now - startedAt
    if elapsed <= 0 { return 0 }
    return min(1, elapsed / duration)
  }

  public func isComplete(at now: TimeInterval) -> Bool {
    guard duration > 0 else { return true }
    return now - startedAt >= duration
  }
}
