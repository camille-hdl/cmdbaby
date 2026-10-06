import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Un fichier de config absent se lit comme les défauts")
func missingConfigurationFileLoadsDefaults() {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  #expect(store.load() == BabyWorksConfiguration())
}

@Test("Une config enregistrée se relit à l’identique")
func savedConfigurationRoundTripsThroughTheFile() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  let original = BabyWorksConfiguration(mode: .starship, launchAtLogin: true)
  try store.save(original)
  #expect(store.load() == original)
}

@Test("Un fichier de config invalide se lit comme les défauts")
func invalidConfigurationFileLoadsDefaults() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data("ceci n'est pas du json".utf8).write(to: file.fileURL)

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  #expect(store.load() == BabyWorksConfiguration())
}

@Test("Un mode inconnu dans le fichier replie sur Océan et conserve le reste")
func unknownModeInConfigurationFileFallsBackToOcean() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data(#"{"mode":"leaf","launchAtLogin":true}"#.utf8).write(to: file.fileURL)

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  #expect(store.load() == BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
}

@Test("Aucune configuration n’est enregistrée avant le premier save, et elle l’est après")
func hasSavedConfigurationIsFalseUntilTheFileIsWritten() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  #expect(store.hasSavedConfiguration == false)

  try store.save(BabyWorksConfiguration())
  #expect(store.hasSavedConfiguration == true)
}

@Test("Le chemin par défaut est Application Support/CmdBaby/config.json")
func defaultConfigurationPathIsApplicationSupport() {
  let url = BabyWorksConfigurationStore.defaultFileURL
  #expect(url.lastPathComponent == "config.json")
  #expect(url.deletingLastPathComponent().lastPathComponent == "CmdBaby")
  #expect(
    url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
      == "Application Support"
  )
}

@Test("La migration copie l’ancienne config quand la nouvelle manque")
func legacyConfigurationIsCopiedWhenTheNewOneIsMissing() throws {
  let legacy = TemporaryConfigurationFile()
  let file = TemporaryConfigurationFile()
  defer {
    legacy.remove()
    file.remove()
  }
  let saved = BabyWorksConfiguration(mode: .starship, launchAtLogin: true)
  try BabyWorksConfigurationStore(fileURL: legacy.fileURL).save(saved)

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  store.migrateLegacyConfiguration(from: legacy.fileURL)

  #expect(store.load() == saved)
  #expect(FileManager.default.fileExists(atPath: legacy.fileURL.path))
}

@Test("La migration ne remplace pas une config déjà là")
func legacyConfigurationIsIgnoredWhenTheNewOneExists() throws {
  let legacy = TemporaryConfigurationFile()
  let file = TemporaryConfigurationFile()
  defer {
    legacy.remove()
    file.remove()
  }
  try BabyWorksConfigurationStore(fileURL: legacy.fileURL)
    .save(BabyWorksConfiguration(mode: .starship, launchAtLogin: true))
  let current = BabyWorksConfiguration(mode: .ocean, launchAtLogin: false)
  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(current)

  store.migrateLegacyConfiguration(from: legacy.fileURL)

  #expect(store.load() == current)
}

@Test("Sans ancienne config, la migration ne crée rien")
func missingLegacyConfigurationCreatesNothing() {
  let legacy = TemporaryConfigurationFile()
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  store.migrateLegacyConfiguration(from: legacy.fileURL)

  #expect(store.hasSavedConfiguration == false)
}

@Test("L’ancienne config est Application Support/BabyWorks/config.json")
func legacyConfigurationPathIsTheBabyWorksFolder() {
  let url = BabyWorksConfigurationStore.legacyFileURL
  #expect(url.lastPathComponent == "config.json")
  #expect(url.deletingLastPathComponent().lastPathComponent == "BabyWorks")
}

private struct TemporaryConfigurationFile {
  let directory: URL
  let fileURL: URL

  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "BabyWorksConfigurationTests-\(UUID().uuidString)",
      isDirectory: true
    )
    fileURL = directory.appendingPathComponent("config.json")
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}
