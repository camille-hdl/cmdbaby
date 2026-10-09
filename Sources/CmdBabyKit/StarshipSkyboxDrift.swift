import Foundation

/// Aller du ciel de `from` vers `to`. `y` augmente : le ciel visible descend.
public struct StarshipSkyboxDrift: Equatable, Sendable {
  public var from: StarshipUnitRect
  public var to: StarshipUnitRect
  public var duration: Double

  /// Un seul aller de `from` vers `to`.
  public static func once(
    from: StarshipUnitRect,
    to: StarshipUnitRect,
    duration: Double
  ) -> StarshipSkyboxDrift {
    StarshipSkyboxDrift(
      from: from,
      to: to,
      duration: duration
    )
  }
}
