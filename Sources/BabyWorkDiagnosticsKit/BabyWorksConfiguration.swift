import Foundation

/// Configuration JSON de BabyWorks : mode de jeu et lancement à l’ouverture.
/// Schéma versionné ; l’I/O disque n’est pas dans ce type.
public struct BabyWorksConfiguration: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 1

  public var schemaVersion: Int
  public var mode: KioskPlayModeID
  public var launchAtLogin: Bool

  public init(
    schemaVersion: Int = currentSchemaVersion,
    mode: KioskPlayModeID = KioskPlayModeCatalog.default,
    launchAtLogin: Bool = false
  ) {
    self.schemaVersion = schemaVersion
    self.mode = mode
    self.launchAtLogin = launchAtLogin
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case mode
    case launchAtLogin
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = BabyWorksConfiguration()
    let rawMode = try container.decodeIfPresent(String.self, forKey: .mode)
    self.init(
      schemaVersion: try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        ?? defaults.schemaVersion,
      mode: rawMode.map(KioskPlayModeCatalog.sessionMode(fromRawID:)) ?? defaults.mode,
      launchAtLogin: try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin)
        ?? defaults.launchAtLogin
    )
  }
}
