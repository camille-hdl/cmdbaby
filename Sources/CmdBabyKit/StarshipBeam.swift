import Foundation

/// Rayon bleu : le sprite reste à sa taille, l’échelle Y le mène jusqu’à la cible.
public enum StarshipBeam: Sendable {
  /// Sprite Kenney 9 × 54 px, agrandi 1,6 fois, en points.
  public static let spriteWidth: Double = 14
  public static let spriteHeight: Double = 86

  public struct Placement: Equatable, Sendable {
    public var origin: StarshipPoint
    /// Extrémité côté cible. Au-delà d’un point, c’est la cible elle-même.
    public var end: StarshipPoint
    /// Longueur du trait, au moins 1 pt.
    public var length: Double
    /// Rotation du sprite. 0 = vers le haut.
    public var angle: Double
    public var scaleY: Double
  }

  /// Origine au départ, longueur et angle jusqu’à `end`.
  /// Le sprite pointe vers le haut : l’angle est celui du tir, moins π/2.
  public static func placement(from start: StarshipPoint, to end: StarshipPoint) -> Placement {
    let dx = end.x - start.x
    let dy = end.y - start.y
    let distance = hypot(dx, dy)
    let length = max(distance, 1)
    let shot = atan2(dy, dx)
    let arrival = distance >= 1
      ? end
      : StarshipPoint(x: start.x + cos(shot) * length, y: start.y + sin(shot) * length)
    return Placement(
      origin: start,
      end: arrival,
      length: length,
      angle: shot - .pi / 2,
      scaleY: length / spriteHeight
    )
  }
}
