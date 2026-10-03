import Foundation

/// Réglages de sortie lus au lancement d’une session.
public struct AdultExitSettings: Codable, Equatable, Sendable {
  public static let timeLimitRange = 1...120
  public static let defaultTimeLimitMinutes = 20

  public var timeLimitMinutes: Int

  public init(timeLimitMinutes: Int = defaultTimeLimitMinutes) {
    self.timeLimitMinutes = timeLimitMinutes
  }

  private enum CodingKeys: String, CodingKey {
    case timeLimitMinutes
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let minutes = (try? container.decode(Int.self, forKey: .timeLimitMinutes))
      ?? Self.defaultTimeLimitMinutes
    self.init(timeLimitMinutes: Self.clamped(minutes))
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(timeLimitMinutes, forKey: .timeLimitMinutes)
  }

  private static func clamped(_ minutes: Int) -> Int {
    min(max(minutes, timeLimitRange.lowerBound), timeLimitRange.upperBound)
  }
}
