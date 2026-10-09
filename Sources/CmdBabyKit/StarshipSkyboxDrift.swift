import Foundation

/// Aller unique du ciel. `y` augmente : le ciel visible descend.
/// Pas de retour : il ferait remonter le ciel. Pas de répétition : elle ramènerait `y` d’un coup.
public struct StarshipSkyboxDrift: Equatable, Sendable {
  public var from: StarshipUnitRect
  public var to: StarshipUnitRect
  public var duration: Double
  public var reverses: Bool
  public var repeatCount: Double
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
      reverses: false,
      repeatCount: 0,
      repeatDuration: 0
    )
  }
}
