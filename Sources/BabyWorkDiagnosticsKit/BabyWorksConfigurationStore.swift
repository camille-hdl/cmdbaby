import Foundation
import OSLog

private let configurationLogger = Logger(subsystem: "fr.camille.babywork", category: "Config")

/// Lecture et écriture de `BabyWorksConfiguration` dans Application Support.
public struct BabyWorksConfigurationStore: Sendable {
  public static let defaultFileURL = URL.applicationSupportDirectory
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

  public func load() -> BabyWorksConfiguration {
    do {
      let data = try Data(contentsOf: fileURL)
      return try JSONDecoder().decode(BabyWorksConfiguration.self, from: data)
    } catch {
      configurationLogger.error(
        "Config illisible à \(self.fileURL.path, privacy: .public) (\(error.localizedDescription, privacy: .public)) ; défauts utilisés."
      )
      return BabyWorksConfiguration()
    }
  }

  public func save(_ configuration: BabyWorksConfiguration) throws {
    let directory = fileURL.deletingLastPathComponent()
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(configuration)
    try data.write(to: fileURL, options: .atomic)
  }
}
