import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Activer le démarrage automatique enregistre le Login Item et écrit la config")
func enablingLaunchAtLoginRegistersLoginItemAndPersistsConfig() throws {
  let file = TemporaryLaunchAtLoginConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .galaxy, launchAtLogin: false))
  let loginItem = FakeLoginItemRegistration()

  let settings = SettingsLaunchAtLogin(store: store, loginItem: loginItem)
  #expect(!settings.isEnabled())

  try settings.setEnabled(true)

  #expect(loginItem.isRegistered)
  #expect(settings.isEnabled())
  #expect(store.load() == BabyWorksConfiguration(mode: .galaxy, launchAtLogin: true))
}

@Test("Désactiver le démarrage automatique désenregistre le Login Item et écrit la config")
func disablingLaunchAtLoginUnregistersLoginItemAndPersistsConfig() throws {
  let file = TemporaryLaunchAtLoginConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = SettingsLaunchAtLogin(store: store, loginItem: loginItem)
  try settings.setEnabled(false)

  #expect(!loginItem.isRegistered)
  #expect(!settings.isEnabled())
  #expect(store.load() == BabyWorksConfiguration(mode: .ocean, launchAtLogin: false))
}

@Test("L’état lu suit le Login Item et aligne la config si elle diverge")
func launchAtLoginStateFollowsLoginItemAndReconcilesConfig() throws {
  let file = TemporaryLaunchAtLoginConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .galaxy, launchAtLogin: false))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = SettingsLaunchAtLogin(store: store, loginItem: loginItem)

  #expect(settings.isEnabled())
  #expect(store.load() == BabyWorksConfiguration(mode: .galaxy, launchAtLogin: true))

  loginItem.isRegistered = false
  #expect(!settings.isEnabled())
  #expect(store.load() == BabyWorksConfiguration(mode: .galaxy, launchAtLogin: false))
}

@Test("Un échec d’enregistrement laisse le Login Item et la config inchangés")
func failedLoginItemRegistrationLeavesLoginItemAndConfigUnchanged() throws {
  let file = TemporaryLaunchAtLoginConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: false))
  let loginItem = FakeLoginItemRegistration()
  loginItem.registerError = LoginItemFailure()

  let settings = SettingsLaunchAtLogin(store: store, loginItem: loginItem)
  #expect(throws: LoginItemFailure.self) {
    try settings.setEnabled(true)
  }

  #expect(!loginItem.isRegistered)
  #expect(!settings.isEnabled())
  #expect(store.load() == BabyWorksConfiguration(mode: .ocean, launchAtLogin: false))
}

private struct LoginItemFailure: Error {}

private final class FakeLoginItemRegistration: LoginItemRegistration, @unchecked Sendable {
  var isRegistered = false
  var registerError: (any Error)?

  func register() throws {
    if let registerError {
      throw registerError
    }
    isRegistered = true
  }

  func unregister() throws {
    isRegistered = false
  }
}

private struct TemporaryLaunchAtLoginConfigurationFile {
  let directory: URL
  let fileURL: URL

  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "BabyWorksSettingsLaunchAtLoginTests-\(UUID().uuidString)",
      isDirectory: true
    )
    fileURL = directory.appendingPathComponent("config.json")
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}
