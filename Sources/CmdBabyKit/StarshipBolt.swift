import Foundation

/// Projectile bleu : un aller du nez jusqu’à la cible, sans retour.
public enum StarshipBolt: Sendable {
  public struct Flight: Equatable, Sendable {
    public var from: StarshipPoint
    public var to: StarshipPoint
    /// Pas de retour : le projectile ne revient pas au nez.
    public var reverses: Bool
    /// 0 : une seule fois. Le rejouer le ramènerait au départ.
    public var repeatCount: Double
  }

  public static func flight(from start: StarshipPoint, to end: StarshipPoint) -> Flight {
    Flight(from: start, to: end, reverses: false, repeatCount: 0)
  }
}
