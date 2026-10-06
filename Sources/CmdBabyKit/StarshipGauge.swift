import Foundation

/// Couleur de la jauge, composantes entre 0 et 1.
public struct StarshipRGB: Equatable, Sendable {
  public var red: Double
  public var green: Double
  public var blue: Double

  public init(hex: UInt32) {
    red = Double((hex >> 16) & 0xFF) / 255
    green = Double((hex >> 8) & 0xFF) / 255
    blue = Double(hex & 0xFF) / 255
  }

  public init(red: Double, green: Double, blue: Double) {
    self.red = red
    self.green = green
    self.blue = blue
  }
}

/// Niveau, couleur et inertie de la jauge de cadence.
public enum StarshipGauge: Sendable {
  /// Paliers de couleur, niveau → couleur.
  public static let stops: [(level: Double, color: StarshipRGB)] = [
    (0.0, StarshipRGB(hex: 0x2ECC71)),
    (0.5, StarshipRGB(hex: 0xF1C40F)),
    (0.8, StarshipRGB(hex: 0xFF8C00)),
    (1.0, StarshipRGB(hex: 0xFF0000)),
  ]

  /// `perMinute / cap`, borné à `0…1`.
  public static func level(perMinute: Double, cap: Double) -> Double {
    guard cap > 0 else { return 0 }
    return min(1, max(0, perMinute / cap))
  }

  /// Interpolation linéaire entre les deux paliers qui encadrent `level`.
  public static func color(level: Double) -> StarshipRGB {
    let level = min(1, max(0, level))
    for index in stops.indices.dropFirst() {
      let upper = stops[index]
      if level <= upper.level {
        let lower = stops[index - 1]
        let span = upper.level - lower.level
        guard span > 0 else { return upper.color }
        let t = (level - lower.level) / span
        if t <= 0 { return lower.color }
        if t >= 1 { return upper.color }
        return mix(lower.color, upper.color, t: t)
      }
    }
    return stops[stops.count - 1].color
  }

  /// Rapproche le niveau affiché du niveau visé. `dt` en secondes.
  public static func eased(current: Double, target: Double, dt: Double) -> Double {
    current + (target - current) * min(1, dt * 8)
  }

  private static func mix(_ from: StarshipRGB, _ to: StarshipRGB, t: Double) -> StarshipRGB {
    StarshipRGB(
      red: from.red + (to.red - from.red) * t,
      green: from.green + (to.green - from.green) * t,
      blue: from.blue + (to.blue - from.blue) * t
    )
  }
}
