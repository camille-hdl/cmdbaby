import Foundation
import Testing

@testable import CmdBabyKit

@Test("Un fichier de config absent se lit comme les défauts")
func missingConfigurationFileLoadsDefaults() {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  #expect(store.load() == CmdBabyConfiguration())
}

@Test("Une config enregistrée se relit à l’identique")
func savedConfigurationRoundTripsThroughTheFile() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  let original = CmdBabyConfiguration(mode: .starship, launchAtLogin: true)
  try store.save(original)
  #expect(store.load() == original)
}

@Test("Un fichier de config invalide se lit comme les défauts")
func invalidConfigurationFileLoadsDefaults() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data("ceci n'est pas du json".utf8).write(to: file.fileURL)

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  #expect(store.load() == CmdBabyConfiguration())
}

@Test("Un mode inconnu dans le fichier replie sur Océan et conserve le reste")
func unknownModeInConfigurationFileFallsBackToOcean() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data(#"{"mode":"leaf","launchAtLogin":true}"#.utf8).write(to: file.fileURL)

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  #expect(store.load() == CmdBabyConfiguration(mode: .ocean, launchAtLogin: true))
}

@Test("Aucune configuration n’est enregistrée avant le premier save, et elle l’est après")
func hasSavedConfigurationIsFalseUntilTheFileIsWritten() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  #expect(store.hasSavedConfiguration == false)

  try store.save(CmdBabyConfiguration())
  #expect(store.hasSavedConfiguration == true)
}

@Test("Le chemin par défaut est Application Support/CmdBaby/config.json")
func defaultConfigurationPathIsApplicationSupport() {
  let url = CmdBabyConfigurationStore.defaultFileURL
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
  let saved = CmdBabyConfiguration(mode: .starship, launchAtLogin: true)
  try CmdBabyConfigurationStore(fileURL: legacy.fileURL).save(saved)

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
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
  try CmdBabyConfigurationStore(fileURL: legacy.fileURL)
    .save(CmdBabyConfiguration(mode: .starship, launchAtLogin: true))
  let current = CmdBabyConfiguration(mode: .ocean, launchAtLogin: false)
  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  try store.save(current)

  store.migrateLegacyConfiguration(from: legacy.fileURL)

  #expect(store.load() == current)
}

@Test("Sans ancienne config, la migration ne crée rien")
func missingLegacyConfigurationCreatesNothing() {
  let legacy = TemporaryConfigurationFile()
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  store.migrateLegacyConfiguration(from: legacy.fileURL)

  #expect(store.hasSavedConfiguration == false)
}

@Test("L’ancienne config est Application Support/BabyWorks/config.json")
func legacyConfigurationPathIsTheBabyWorksFolder() {
  let url = CmdBabyConfigurationStore.legacyFileURL
  #expect(url.lastPathComponent == "config.json")
  #expect(url.deletingLastPathComponent().lastPathComponent == "BabyWorks")
}

@Test("Une config illisible est signalée, puis copiée en .corrupt avant d’être réécrite")
func unreadableConfigurationIsPreservedBeforeSave() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data("{".utf8).write(to: file.fileURL)

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  #expect(store.read() == .unreadable(.invalid))
  #expect(store.load() == CmdBabyConfiguration())

  let saved = CmdBabyConfiguration(mode: .terminal, launchAtLogin: true)
  try store.save(saved)

  let names = try FileManager.default.contentsOfDirectory(atPath: file.directory.path)
  let corrupt = try #require(names.first { $0.hasPrefix("config.json.corrupt-") })
  #expect(try Data(contentsOf: file.directory.appendingPathComponent(corrupt)) == Data("{".utf8))
  #expect(store.read() == .loaded(saved))
}

@Test("Un champ de mauvais type rend la config illisible")
func wrongFieldTypeIsUnreadable() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data(#"{"launchAtLogin":"oui"}"#.utf8).write(to: file.fileURL)
  #expect(CmdBabyConfigurationStore(fileURL: file.fileURL).read() == .unreadable(.invalid))
}

@Test("Un schemaVersion futur est refusé et le fichier n’est jamais écrasé")
func futureSchemaIsRefusedWithoutOverwrite() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  let future = Data(#"{"schemaVersion":99,"mode":"ocean"}"#.utf8)
  try future.write(to: file.fileURL)

  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  #expect(store.read() == .unreadable(.newerSchema))
  #expect(throws: CmdBabyConfigurationStore.SaveError.newerSchema) {
    try store.save(CmdBabyConfiguration())
  }
  #expect(try Data(contentsOf: file.fileURL) == future)
}

@Test("Un fichier de plus de 1 Mo n’est pas lu")
func oversizedConfigurationIsUnreadable() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data(repeating: 0x20, count: 1024 * 1024 + 1).write(to: file.fileURL)
  #expect(CmdBabyConfigurationStore(fileURL: file.fileURL).read() == .unreadable(.tooLarge))
}

@Test("Après un enregistrement : fichier en 600, dossier en 700")
func savedConfigurationIsPrivate() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try CmdBabyConfigurationStore(fileURL: file.fileURL).save(CmdBabyConfiguration())
  let fileMode = try FileManager.default.attributesOfItem(atPath: file.fileURL.path)[.posixPermissions] as? Int
  let folderMode = try FileManager.default.attributesOfItem(atPath: file.directory.path)[.posixPermissions] as? Int
  #expect(fileMode == 0o600)
  #expect(folderMode == 0o700)
}

private struct TemporaryConfigurationFile {
  let directory: URL
  let fileURL: URL

  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "CmdBabyConfigurationTests-\(UUID().uuidString)",
      isDirectory: true
    )
    fileURL = directory.appendingPathComponent("config.json")
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}
