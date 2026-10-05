import Foundation

/// Point d’apparition d’une cible, juste à l’extérieur d’un bord de l’écran du vaisseau.
public enum StarshipSpawn: Sendable {
  /// Point juste à l’extérieur du rectangle `[0, width] × [0, height]`, à `margin` du bord.
  /// `roll` dans `[0, 1)` parcourt le périmètre à vitesse constante, en partant du coin bas-gauche,
  /// dans l’ordre : bord bas (gauche → droite), bord droit (bas → haut), bord haut (droite → gauche), bord gauche (haut → bas).
  public static func edgePoint(width: Double, height: Double, margin: Double, roll: Double) -> StarshipPoint {
    let clamped = min(max(roll, 0), 0.999_999)
    let distance = clamped * 2 * (width + height)
    if distance < width {
      return StarshipPoint(x: distance, y: -margin)
    }
    if distance < width + height {
      return StarshipPoint(x: width + margin, y: distance - width)
    }
    if distance < 2 * width + height {
      return StarshipPoint(x: width - (distance - width - height), y: height + margin)
    }
    return StarshipPoint(x: -margin, y: height - (distance - 2 * width - height))
  }
}
