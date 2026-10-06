import Foundation
import OSLog

private let configurationLogger = Logger(subsystem: AppIdentity.logSubsystem, category: "Config")

/// Lecture et écriture de `CmdBabyConfiguration` dans Application Support.
public struct CmdBabyConfigurationStore: Sendable {
  public static let defaultFileURL = AppIdentity.supportDirectory
    .appendingPathComponent("config.json", isDirectory: false)

  /// Config de l’époque où l’app s’appelait BabyWorks.
  public static let legacyFileURL = URL.applicationSupportDirectory
    .appendingPathComponent("BabyWorks", isDirectory: true)
    .appendingPathComponent("config.json", isDirectory: false)

  public let fileURL: URL

  public init(fileURL: URL = defaultFileURL) {
    self.fileURL = fileURL
  }

  /// Vrai dès que `config.json` existe, même s’il est illisible.
  public var hasSavedConfiguration: Bool {
    FileManager.default.fileExists(atPath: fileURL.path)
  }

  /// Copie l’ancienne config si la nouvelle n’existe pas encore. Sinon, ne fait rien.
  public func migrateLegacyConfiguration(from legacyURL: URL = legacyFileURL) {
    let fileManager = FileManager.default
    guard !hasSavedConfiguration, fileManager.fileExists(atPath: legacyURL.path) else { return }
    do {
      try fileManager.createDirectory(
        at: fileURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      try fileManager.copyItem(at: legacyURL, to: fileURL)
    } catch {
      configurationLogger.error(
        "Migration de \(legacyURL.path, privacy: .public) impossible (\(error.localizedDescription, privacy: .public))."
      )
    }
  }

  public func load() -> CmdBabyConfiguration {
    do {
      let data = try Data(contentsOf: fileURL)
      return try JSONDecoder().decode(CmdBabyConfiguration.self, from: data)
    } catch {
      configurationLogger.error(
        "Config illisible à \(self.fileURL.path, privacy: .public) (\(error.localizedDescription, privacy: .public)) ; défauts utilisés."
      )
      return CmdBabyConfiguration()
    }
  }

  public func save(_ configuration: CmdBabyConfiguration) throws {
    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(configuration)
    try data.write(to: fileURL, options: .atomic)
  }
}
