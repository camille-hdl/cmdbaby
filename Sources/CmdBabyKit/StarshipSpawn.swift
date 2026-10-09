import Foundation

/// Point d’apparition d’une cible, juste au-dessus du bord haut de l’écran du vaisseau.
public enum StarshipSpawn: Sendable {
  /// Point juste au-dessus du bord haut, à `margin`.
  /// `roll` dans `[0, 1)` parcourt la largeur de gauche à droite.
  public static func topEdgePoint(width: Double, height: Double, margin: Double, roll: Double) -> StarshipPoint {
    let clamped = min(max(roll, 0), 0.999_999)
    return StarshipPoint(x: clamped * width, y: height + margin)
  }
}
