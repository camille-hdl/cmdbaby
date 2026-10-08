import Foundation

/// Position du vaisseau sur l’écran où il se tient.
public enum StarshipShip: Sendable {
  /// Centre du vaisseau : milieu de la largeur, à `fractionFromBottom` de la hauteur depuis le bas.
  /// 0 pose le centre sur le bord bas, 1 sur le bord haut.
  public static func center(width: Double, height: Double, fractionFromBottom: Double) -> StarshipPoint {
    StarshipPoint(x: width / 2, y: height * fractionFromBottom)
  }
}
