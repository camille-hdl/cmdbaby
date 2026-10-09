import Foundation
import Testing

@testable import CmdBabyKit

@Test("Sans surcharge, la session utilise la configuration enregistrée")
func launchWithoutOverridesUsesTheSavedConfiguration() {
  let saved = CmdBabyConfiguration(
    mode: .ocean,
    launchAtLogin: true,
    exits: AdultExitSettings(timeLimitMinutes: 45)
  )
  let request = SessionLaunchRequest(origin: .shortcuts)

  #expect(request.effectiveConfiguration(from: saved) == .ready(saved))
}

@Test("Le mode et la durée surchargés ne valent que pour cette session")
func modeAndDurationOverrideThisSessionOnly() throws {
  let saved = CmdBabyConfiguration(
    mode: .ocean,
    exits: AdultExitSettings(timeLimitMinutes: 45, enabledMethods: [.passphrase])
  )
  let request = SessionLaunchRequest(
    origin: .shortcuts,
    mode: .starship,
    durationMinutes: 10
  )

  let effective = try #require(readyConfiguration(request.effectiveConfiguration(from: saved)))
  #expect(effective.mode == .starship)
  #expect(effective.exits.timeLimitMinutes == 10)
  #expect(effective.exits.enabledMethods == [.passphrase])
  #expect(effective.launchAtLogin == saved.launchAtLogin)
  #expect(saved.mode == .ocean)
  #expect(saved.exits.timeLimitMinutes == 45)

  let limit = SessionTimeLimit(startedAt: 0, settings: effective.exits)
  #expect(!limit.isComplete(at: 10 * 60 - 1))
  #expect(limit.isComplete(at: 10 * 60))
}

@Test("Seule la durée surchargée change le minuteur, même s’il est la seule sortie")
func durationOverrideAppliesWhenTheTimerIsTheOnlyExit() throws {
  let saved = CmdBabyConfiguration(
    mode: .terminal,
    exits: AdultExitSettings(timeLimitMinutes: 45, enabledMethods: [])
  )
  let request = SessionLaunchRequest(origin: .menu, durationMinutes: 2)

  let effective = try #require(readyConfiguration(request.effectiveConfiguration(from: saved)))
  #expect(effective.mode == .terminal)
  let limit = SessionTimeLimit(startedAt: 0, settings: effective.exits)
  #expect(limit.isComplete(at: 2 * 60))
  #expect(!limit.isComplete(at: 2 * 60 - 1))
}

@Test("Une durée de 0 ou 121 minutes est un paramètre invalide")
func durationOutsideTheBoundsIsAnInvalidParameter() {
  let saved = CmdBabyConfiguration(mode: .ocean, exits: AdultExitSettings(timeLimitMinutes: 45))

  #expect(
    SessionLaunchRequest(origin: .shortcuts, durationMinutes: 0).effectiveConfiguration(from: saved)
      == .invalidParameter
  )
  #expect(
    SessionLaunchRequest(origin: .shortcuts, durationMinutes: 121)
      .effectiveConfiguration(from: saved) == .invalidParameter
  )
  #expect(
    SessionLaunchRequest(origin: .shortcuts, durationMinutes: 1).effectiveConfiguration(from: saved)
      != .invalidParameter
  )
  #expect(
    SessionLaunchRequest(origin: .shortcuts, durationMinutes: 120).effectiveConfiguration(from: saved)
      != .invalidParameter
  )
}

@Test("Un lancement surchargé n’écrit pas la configuration enregistrée")
func overriddenLaunchLeavesTheSavedFileUntouched() throws {
  let file = TemporaryOverrideConfigurationFile()
  defer { file.remove() }
  let store = CmdBabyConfigurationStore(fileURL: file.fileURL)
  let saved = CmdBabyConfiguration(mode: .ocean, exits: AdultExitSettings(timeLimitMinutes: 45))
  try store.save(saved)
  let before = try Data(contentsOf: file.fileURL)

  let request = SessionLaunchRequest(origin: .shortcuts, mode: .starship, durationMinutes: 10)
  let effective = try #require(readyConfiguration(request.effectiveConfiguration(from: store.load())))

  #expect(effective.mode == .starship)
  #expect(effective.exits.timeLimitMinutes == 10)
  #expect(store.load() == saved)
  #expect(try Data(contentsOf: file.fileURL) == before)
}

@Test("Les modes du raccourci sont ceux du catalogue, dans le même ordre")
func shortcutModesMatchThePlayModeCatalog() {
  #expect(SessionLaunchMode.playModes == KioskPlayModeCatalog.available)
  #expect(SessionLaunchMode.playModes == Array(KioskPlayModeID.allCases))
}

private func readyConfiguration(
  _ result: SessionLaunchConfiguration
) -> CmdBabyConfiguration? {
  if case .ready(let configuration) = result { return configuration }
  return nil
}

private struct TemporaryOverrideConfigurationFile {
  let directory: URL
  let fileURL: URL

  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "SessionLaunchOverrides-\(UUID().uuidString)",
      isDirectory: true
    )
    fileURL = directory.appendingPathComponent("config.json")
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}
