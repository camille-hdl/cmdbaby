import Foundation

/// File des tours du vaisseau. Chaque tour attend la fin du précédent,
/// pour que N appuis durent N fois `duration` au lieu de se superposer.
public struct StarshipSpinQueue: Equatable, Sendable {
  /// Instant où le dernier tour en file se termine.
  /// `0` tant qu’aucun tour n’a été ajouté.
  public private(set) var endsAt: Double = 0

  public init() {}

  /// Ajoute un tour de `duration` secondes.
  /// Il part à `now` si la file est vide ou déjà finie, sinon à `endsAt`.
  /// Retourne cet instant de début.
  @discardableResult
  public mutating func addTurn(now: Double, duration: Double) -> Double {
    let start = max(now, endsAt)
    endsAt = start + duration
    return start
  }
}
