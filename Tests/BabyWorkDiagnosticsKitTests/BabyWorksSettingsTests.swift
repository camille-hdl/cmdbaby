import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Changer le mode écrit le mode et conserve le démarrage automatique")
func changingModePersistsModeAndKeepsLaunchAtLogin() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  #expect(settings.current() == BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))

  let saved = try settings.apply(.mode(.starship))

  #expect(saved == BabyWorksConfiguration(mode: .starship, launchAtLogin: true))
  #expect(settings.current() == saved)
}

@Test("Régler le minuteur à 45 minutes persiste et conserve le mode et le démarrage")
func settingTimeLimitPersistsAndKeepsModeAndLaunchAtLogin() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  let saved = try settings.apply(.timeLimitMinutes(45))

  let expected = BabyWorksConfiguration(
    mode: .ocean,
    launchAtLogin: true,
    exits: AdultExitSettings(timeLimitMinutes: 45)
  )
  #expect(saved == expected)
  #expect(settings.current() == expected)
  #expect(store.load() == expected)
}

@Test("Désactiver Maj-Échap persiste et conserve le reste")
func disablingShiftEscapePersistsAndKeepsTheRest() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  let saved = try settings.apply(.exitMethod(.shiftEscape, enabled: false))

  let expected = BabyWorksConfiguration(
    mode: .ocean,
    launchAtLogin: true,
    exits: AdultExitSettings(
      enabledMethods: [.passphrase, .failsafeClick]
    )
  )
  #expect(saved == expected)
  #expect(settings.current() == expected)
  #expect(store.load() == expected)
}

@Test("Désactiver la troisième sortie manuelle est refusé et n’écrit rien")
func disablingTheLastManualExitLeavesFileUnchanged() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .starship, launchAtLogin: true))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  _ = try settings.apply(.exitMethod(.shiftEscape, enabled: false))
  let remaining = try settings.apply(.exitMethod(.failsafeClick, enabled: false))
  #expect(remaining.exits.enabledMethods == [.passphrase])

  #expect(throws: SettingsError.lastManualExit) {
    try settings.apply(.exitMethod(.passphrase, enabled: false))
  }
  #expect(store.load() == remaining)
}

@Test("Une phrase trop courte, trop longue ou mêlée d’autre chose est refusée et n’écrit rien")
func invalidPassphraseLeavesFileUnchanged() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  let original = BabyWorksConfiguration(mode: .starship, launchAtLogin: true)
  try store.save(original)
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true
  let settings = BabyWorksSettings(store: store, loginItem: loginItem)

  #expect(SettingsError.passphraseTooShort.errorDescription == "Au moins 3 lettres.")
  #expect(SettingsError.passphraseTooLong.errorDescription == "12 lettres au maximum.")
  #expect(
    SettingsError.passphraseInvalidCharacters.errorDescription
      == "Uniquement des lettres, sans espace ni chiffre."
  )

  #expect(throws: SettingsError.passphraseTooShort) {
    try settings.apply(.passphrase("ab"))
  }
  #expect(store.load() == original)

  #expect(throws: SettingsError.passphraseTooLong) {
    try settings.apply(.passphrase("abcdefghijklm"))
  }
  #expect(store.load() == original)

  #expect(throws: SettingsError.passphraseInvalidCharacters) {
    try settings.apply(.passphrase("papa 2"))
  }
  #expect(store.load() == original)

  #expect(throws: SettingsError.passphraseInvalidCharacters) {
    try settings.apply(.passphrase("pa-pa"))
  }
  #expect(store.load() == original)
}

@Test("Une phrase valide est enregistrée sous sa forme normalisée")
func validPassphrasePersistsNormalizedForm() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  let saved = try settings.apply(.passphrase("  Maman "))

  #expect(saved.exits.passphrase.value == "maman")
  #expect(settings.current().exits.passphrase.value == "maman")
  #expect(store.load().exits.passphrase.value == "maman")
  #expect(saved.mode == .ocean)
  #expect(saved.launchAtLogin == true)
}

@Test("Un minuteur hors bornes est refusé et n’écrit rien")
func timeLimitOutOfRangeLeavesFileUnchanged() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  let original = BabyWorksConfiguration(mode: .starship, launchAtLogin: true)
  try store.save(original)
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  #expect(throws: SettingsError.timeLimitOutOfRange) {
    try settings.apply(.timeLimitMinutes(0))
  }
  #expect(store.load() == original)
}

@Test("Activer le démarrage automatique enregistre le Login Item puis persiste")
func enablingLaunchAtLoginRegistersLoginItemThenPersists() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .starship, launchAtLogin: false))
  let loginItem = FakeLoginItemRegistration()

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  #expect(settings.current() == BabyWorksConfiguration(mode: .starship, launchAtLogin: false))

  let saved = try settings.apply(.launchAtLogin(true))

  #expect(loginItem.isRegistered)
  #expect(saved == BabyWorksConfiguration(mode: .starship, launchAtLogin: true))
  #expect(settings.current() == saved)
}

@Test("Désactiver le démarrage automatique désenregistre le Login Item puis persiste")
func disablingLaunchAtLoginUnregistersLoginItemThenPersists() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: true))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  let saved = try settings.apply(.launchAtLogin(false))

  #expect(!loginItem.isRegistered)
  #expect(saved == BabyWorksConfiguration(mode: .ocean, launchAtLogin: false))
  #expect(settings.current() == saved)
}

@Test("Un échec d’enregistrement du Login Item laisse le fichier inchangé")
func failedLoginItemRegistrationLeavesFileUnchanged() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .ocean, launchAtLogin: false))
  let loginItem = FakeLoginItemRegistration()
  loginItem.registerError = LoginItemFailure()

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)
  #expect(throws: LoginItemFailure.self) {
    try settings.apply(.launchAtLogin(true))
  }

  #expect(!loginItem.isRegistered)
  #expect(store.load() == BabyWorksConfiguration(mode: .ocean, launchAtLogin: false))
}

@Test("La config lue suit le Login Item modifié hors de l’app")
func currentReconcilesLaunchAtLoginChangedOutsideTheApp() throws {
  let file = TemporarySettingsFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  try store.save(BabyWorksConfiguration(mode: .starship, launchAtLogin: false))
  let loginItem = FakeLoginItemRegistration()
  loginItem.isRegistered = true

  let settings = BabyWorksSettings(store: store, loginItem: loginItem)

  #expect(settings.current() == BabyWorksConfiguration(mode: .starship, launchAtLogin: true))
  #expect(store.load() == BabyWorksConfiguration(mode: .starship, launchAtLogin: true))

  loginItem.isRegistered = false
  #expect(settings.current() == BabyWorksConfiguration(mode: .starship, launchAtLogin: false))
  #expect(store.load() == BabyWorksConfiguration(mode: .starship, launchAtLogin: false))
}

private struct LoginItemFailure: Error {}

private struct TemporarySettingsFile {
  let directory: URL
  let fileURL: URL

  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "BabyWorksSettingsTests-\(UUID().uuidString)",
      isDirectory: true
    )
    fileURL = directory.appendingPathComponent("config.json")
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}

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
