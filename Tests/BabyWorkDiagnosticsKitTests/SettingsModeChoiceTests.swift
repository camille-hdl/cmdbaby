import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Choisir Galaxie dans Réglages écrit le mode et conserve le reste de la config")
func selectingGalaxyPersistsModeInConfiguration() throws {
  let file = TemporarySettingsConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))

  let settings = SettingsModeChoice(store: store)
  #expect(settings.selectedMode() == .ocean)

  try settings.select(.galaxy)

  #expect(settings.selectedMode() == .galaxy)
  #expect(store.load() == BabyWorksConfiguration(mode: .galaxy, launchAtLogin: true))
}

@Test("Le sélecteur de mode liste Océan et Galaxie")
func settingsModeChoiceListsCatalogModes() {
  let file = TemporarySettingsConfigurationFile()
  defer { file.remove() }

  let settings = SettingsModeChoice(store: BabyWorksConfigurationStore(fileURL: file.fileURL))
  #expect(settings.options == [.ocean, .galaxy])
  #expect(settings.options.map(KioskPlayModeCatalog.displayName) == ["Océan", "Galaxie"])
}

private struct TemporarySettingsConfigurationFile {
  let directory: URL
  let fileURL: URL

  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "BabyWorksSettingsModeChoiceTests-\(UUID().uuidString)",
      isDirectory: true
    )
    fileURL = directory.appendingPathComponent("config.json")
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}
