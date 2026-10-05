import Foundation

public enum AdultExitMethod: String, Codable, CaseIterable, Equatable, Sendable {
  case passphrase
  case shiftEscape
  case failsafeClick
}

/// Réglages de sortie lus au lancement d’une session.
public struct AdultExitSettings: Codable, Equatable, Sendable {
  public static let timeLimitRange = 1...120
  public static let defaultTimeLimitMinutes = 3
  public static let defaultEnabledMethods = Set(AdultExitMethod.allCases)

  public var timeLimitMinutes: Int
  public var enabledMethods: Set<AdultExitMethod>
  public var passphrase: ExitPassphrase

  public init(
    timeLimitMinutes: Int = defaultTimeLimitMinutes,
    enabledMethods: Set<AdultExitMethod> = defaultEnabledMethods,
    passphrase: ExitPassphrase = .defaultValue
  ) {
    self.timeLimitMinutes = timeLimitMinutes
    self.enabledMethods = enabledMethods
    self.passphrase = passphrase
  }

  private enum CodingKeys: String, CodingKey {
    case timeLimitMinutes
    case enabledMethods
    case passphrase
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let minutes = (try? container.decode(Int.self, forKey: .timeLimitMinutes))
      ?? Self.defaultTimeLimitMinutes
    self.init(
      timeLimitMinutes: Self.clamped(minutes),
      enabledMethods: Self.decodeEnabledMethods(from: container),
      passphrase: Self.decodePassphrase(from: container)
    )
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(timeLimitMinutes, forKey: .timeLimitMinutes)
    try container.encode(
      AdultExitMethod.allCases.filter { enabledMethods.contains($0) },
      forKey: .enabledMethods
    )
    try container.encode(passphrase.value, forKey: .passphrase)
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

  /// Absente, illisible ou invalide : `parent`.
  private static func decodePassphrase(
    from container: KeyedDecodingContainer<CodingKeys>
  ) -> ExitPassphrase {
    guard let raw = try? container.decode(String.self, forKey: .passphrase),
      let parsed = try? ExitPassphrase.parse(raw)
    else {
      return .defaultValue
    }
    return parsed
  }

  private static func clamped(_ minutes: Int) -> Int {
    min(max(minutes, timeLimitRange.lowerBound), timeLimitRange.upperBound)
  }
}
