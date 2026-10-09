import Foundation

/// Rayon bleu : le sprite reste à sa taille, l’échelle Y le mène jusqu’à la cible.
public enum StarshipBeam: Sendable {
  /// Sprite Kenney 9 × 54 px, agrandi 1,6 fois, en points.
  public static let spriteWidth: Double = 14
  public static let spriteHeight: Double = 86

  public struct Placement: Equatable, Sendable {
    /// Rotation du sprite. 0 = vers le haut.
    public var angle: Double
    public var scaleY: Double
  }

  /// Angle et échelle de `start` jusqu’à `end`.
  /// Le sprite pointe vers le haut : l’angle est celui du tir, moins π/2.
  /// L’échelle est la distance en sprites de 86 pt. En dessous d’un point, elle reste celle d’un point.
  public static func placement(from start: StarshipPoint, to end: StarshipPoint) -> Placement {
    let dx = end.x - start.x
    let dy = end.y - start.y
    let length = max(hypot(dx, dy), 1)
    return Placement(
      angle: atan2(dy, dx) - .pi / 2,
      scaleY: length / spriteHeight
    )
  }
}
