import Foundation

/// Impact : la lettre déjà dessinée grossit là où elle est. On n’en pose pas une autre.
public enum StarshipExplosion: Sendable {
  public struct GlyphPop: Equatable, Sendable {
    public var scaleFrom: Double
    public var scaleTo: Double
  }

  /// 1 → 1,6. Pas de déplacement : la lettre ne part pas du bord.
  public static let glyphPop = GlyphPop(scaleFrom: 1, scaleTo: 1.6)

  /// Position de la lettre dans la scène. Elle est dans le repère de la cible
  /// (origine en bas à gauche, ancre de la cible au centre). Au centre de la cible,
  /// elle reste sur l’ennemi : on ne la laisse pas à son point local, au bord.
  public static func glyphScenePosition(
    targetAt target: StarshipPoint,
    glyphAtLocal local: StarshipPoint,
    targetWidth: Double,
    targetHeight: Double
  ) -> StarshipPoint {
    StarshipPoint(
      x: target.x + (local.x - targetWidth / 2),
      y: target.y + (local.y - targetHeight / 2)
    )
  }
}
