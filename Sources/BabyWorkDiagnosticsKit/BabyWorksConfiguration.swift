import Foundation

/// Configuration JSON de BabyWorks : mode de jeu et lancement à l’ouverture.
/// Schéma versionné ; l’I/O disque n’est pas dans ce type.
public struct BabyWorksConfiguration: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 1

  public let schemaVersion: Int
  public let mode: KioskPlayModeID
  public let launchAtLogin: Bool

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
    self.init(
      schemaVersion: try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        ?? defaults.schemaVersion,
      mode: try container.decodeIfPresent(KioskPlayModeID.self, forKey: .mode) ?? defaults.mode,
      launchAtLogin: try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin)
        ?? defaults.launchAtLogin
    )
  }
}
