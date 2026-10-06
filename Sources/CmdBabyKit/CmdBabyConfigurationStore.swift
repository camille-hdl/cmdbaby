import Foundation
import OSLog

private let configurationLogger = Logger(subsystem: AppIdentity.logSubsystem, category: "Config")

/// Lecture et écriture de `CmdBabyConfiguration` dans Application Support.
/// Un fichier illisible n’est jamais perdu : il est copié en `.corrupt-…` avant d’être réécrit.
public struct CmdBabyConfigurationStore: Sendable {
  public static let defaultFileURL = AppIdentity.supportDirectory
    .appendingPathComponent("config.json", isDirectory: false)

  /// Config de l’époque où l’app s’appelait BabyWorks.
  public static let legacyFileURL = URL.applicationSupportDirectory
    .appendingPathComponent("BabyWorks", isDirectory: true)
    .appendingPathComponent("config.json", isDirectory: false)

  public static let maxFileBytes = 1024 * 1024

  public enum Unreadable: Equatable, Sendable {
    case invalid
    case tooLarge
    /// Écrit par une version plus récente de l’app : ne jamais l’écraser.
    case newerSchema
  }

  public enum Read: Equatable, Sendable {
    case missing
    case loaded(CmdBabyConfiguration)
    case unreadable(Unreadable)
  }

  public enum SaveError: Error, Equatable {
    case newerSchema
  }

  public let fileURL: URL

  public init(fileURL: URL = defaultFileURL) {
    self.fileURL = fileURL
  }

  /// Vrai dès que `config.json` existe, même s’il est illisible.
  public var hasSavedConfiguration: Bool {
    FileManager.default.fileExists(atPath: fileURL.path)
  }

  public var isUnreadable: Bool {
    if case .unreadable = read() { return true }
    return false
  }

  /// Copie l’ancienne config si la nouvelle n’existe pas encore. Sinon, ne fait rien.
  public func migrateLegacyConfiguration(from legacyURL: URL = legacyFileURL) {
    let fileManager = FileManager.default
    guard !hasSavedConfiguration, fileManager.fileExists(atPath: legacyURL.path) else { return }
    do {
      try createPrivateDirectory()
      try fileManager.copyItem(at: legacyURL, to: fileURL)
      try restrictFile()
    } catch {
      configurationLogger.error(
        "Migration de \(LifecycleLog.displayPath(legacyURL.path), privacy: .public) impossible (\(error.localizedDescription, privacy: .public))."
      )
    }
  }

  /// Au lancement : dossier en 700 et fichier en 600, même s’ils viennent d’une version précédente.
  public func restrictPermissions() {
    let fileManager = FileManager.default
    let directory = fileURL.deletingLastPathComponent()
    if fileManager.fileExists(atPath: directory.path) {
      try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
    }
    if hasSavedConfiguration {
      try? restrictFile()
    }
  }

  public func read() -> Read {
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: fileURL.path) else { return .missing }
    let size = (try? fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int) ?? 0
    guard size <= Self.maxFileBytes else { return .unreadable(.tooLarge) }
    do {
      let data = try Data(contentsOf: fileURL)
      let configuration = try JSONDecoder().decode(CmdBabyConfiguration.self, from: data)
      guard configuration.schemaVersion <= CmdBabyConfiguration.currentSchemaVersion else {
        return .unreadable(.newerSchema)
      }
      return .loaded(configuration)
    } catch {
      return .unreadable(.invalid)
    }
  }

  public func load() -> CmdBabyConfiguration {
    switch read() {
    case .loaded(let configuration):
      return configuration
    case .missing:
      return CmdBabyConfiguration()
    case .unreadable(let reason):
      configurationLogger.error(
        "Config illisible à \(LifecycleLog.displayPath(self.fileURL.path), privacy: .public) (\(String(describing: reason), privacy: .public)) ; défauts utilisés."
      )
      return CmdBabyConfiguration()
    }
  }

  public func save(_ configuration: CmdBabyConfiguration) throws {
    if case .unreadable(let reason) = read() {
      guard reason != .newerSchema else { throw SaveError.newerSchema }
      try preserveUnreadableFile()
    }
    try createPrivateDirectory()
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(configuration)
    try data.write(to: fileURL, options: .atomic)
    try restrictFile()
  }

  private func preserveUnreadableFile() throws {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withYear, .withMonth, .withDay, .withTime]
    let stamp = formatter.string(from: Date())
    let copy = fileURL.deletingLastPathComponent()
      .appendingPathComponent("\(fileURL.lastPathComponent).corrupt-\(stamp)")
    try? FileManager.default.removeItem(at: copy)
    try FileManager.default.copyItem(at: fileURL, to: copy)
    configurationLogger.error(
      "Config illisible conservée dans \(LifecycleLog.displayPath(copy.path), privacy: .public)."
    )
  }

  private func createPrivateDirectory() throws {
    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
  }

  private func restrictFile() throws {
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
  }
}
