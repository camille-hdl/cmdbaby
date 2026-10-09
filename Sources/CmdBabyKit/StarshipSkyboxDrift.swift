import Foundation

/// Aller du ciel de `from` vers `to`. `y` augmente : le ciel visible descend.
public struct StarshipSkyboxDrift: Equatable, Sendable {
  public var from: StarshipUnitRect
  public var to: StarshipUnitRect
  public var duration: Double
  /// 0 : pas de répétition. Répéter ramènerait `y` au départ.
  public var repeatDuration: Double

  /// Un seul aller de `from` vers `to`.
  public static func once(
    from: StarshipUnitRect,
    to: StarshipUnitRect,
    duration: Double
  ) -> StarshipSkyboxDrift {
    StarshipSkyboxDrift(
      from: from,
      to: to,
      duration: duration,
      repeatDuration: 0
    )
  }
}
