import Foundation

/// Configuration JSON de CmdBaby : mode de jeu, lancement à l’ouverture et sorties.
/// Schéma versionné ; l’I/O disque n’est pas dans ce type.
public struct CmdBabyConfiguration: Codable, Equatable, Sendable {
  public static let currentSchemaVersion = 1

  public var schemaVersion: Int
  public var mode: KioskPlayModeID
  public var launchAtLogin: Bool
  /// Case Réglages › Général. Absente du JSON → refus du lien.
  public var linkLaunchAllowed: Bool
  public var exits: AdultExitSettings

  public init(
    schemaVersion: Int = currentSchemaVersion,
    mode: KioskPlayModeID = KioskPlayModeCatalog.default,
    launchAtLogin: Bool = false,
    linkLaunchAllowed: Bool = false,
    exits: AdultExitSettings = AdultExitSettings()
  ) {
    self.schemaVersion = schemaVersion
    self.mode = mode
    self.launchAtLogin = launchAtLogin
    self.linkLaunchAllowed = linkLaunchAllowed
    self.exits = exits
  }

  private enum CodingKeys: String, CodingKey {
    case schemaVersion
    case mode
    case launchAtLogin
    case linkLaunchAllowed
    case exits
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let defaults = CmdBabyConfiguration()
    let rawMode = try container.decodeIfPresent(String.self, forKey: .mode)
    self.init(
      schemaVersion: try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        ?? defaults.schemaVersion,
      mode: rawMode.map(KioskPlayModeCatalog.sessionMode(fromRawID:)) ?? defaults.mode,
      launchAtLogin: try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin)
        ?? defaults.launchAtLogin,
      linkLaunchAllowed: try container.decodeIfPresent(Bool.self, forKey: .linkLaunchAllowed)
        ?? defaults.linkLaunchAllowed,
      exits: Self.decodeExits(from: container) ?? defaults.exits
    )
  }

  /// Objet absent ou illisible : les sorties par défaut, sans faire échouer le reste.
  private static func decodeExits(
    from container: KeyedDecodingContainer<CodingKeys>
  ) -> AdultExitSettings? {
    guard container.contains(.exits) else { return nil }
    return try? container.decode(AdultExitSettings.self, forKey: .exits)
  }
}
