import Foundation

public enum AdultExitMethod: String, Codable, CaseIterable, Equatable, Sendable {
  case passphrase
  case shiftEscape
  case failsafeClick
}

/// Réglages de sortie lus au lancement d’une session.
public struct AdultExitSettings: Codable, Equatable, Sendable {
  public static let timeLimitRange = 1...120
  public static let defaultTimeLimitMinutes = 20
  public static let defaultEnabledMethods = Set(AdultExitMethod.allCases)

  public var timeLimitMinutes: Int
  public var enabledMethods: Set<AdultExitMethod>

  public init(
    timeLimitMinutes: Int = defaultTimeLimitMinutes,
    enabledMethods: Set<AdultExitMethod> = defaultEnabledMethods
  ) {
    self.timeLimitMinutes = timeLimitMinutes
    self.enabledMethods = enabledMethods
  }

  private enum CodingKeys: String, CodingKey {
    case timeLimitMinutes
    case enabledMethods
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let minutes = (try? container.decode(Int.self, forKey: .timeLimitMinutes))
      ?? Self.defaultTimeLimitMinutes
    self.init(
      timeLimitMinutes: Self.clamped(minutes),
      enabledMethods: Self.decodeEnabledMethods(from: container)
    )
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(timeLimitMinutes, forKey: .timeLimitMinutes)
    try container.encode(
      AdultExitMethod.allCases.filter { enabledMethods.contains($0) },
      forKey: .enabledMethods
    )
  }

  /// Absent, illisible, vide ou réduit aux valeurs inconnues : les trois méthodes.
  private static func decodeEnabledMethods(
    from container: KeyedDecodingContainer<CodingKeys>
  ) -> Set<AdultExitMethod> {
    guard let raw = try? container.decode([String].self, forKey: .enabledMethods) else {
      return defaultEnabledMethods
    }
    let known = Set(raw.compactMap(AdultExitMethod.init(rawValue:)))
    return known.isEmpty ? defaultEnabledMethods : known
  }

  private static func clamped(_ minutes: Int) -> Int {
    min(max(minutes, timeLimitRange.lowerBound), timeLimitRange.upperBound)
  }
}
