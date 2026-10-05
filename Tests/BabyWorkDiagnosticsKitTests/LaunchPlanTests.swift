import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Sans configuration enregistrée, le lancement ouvre les Réglages sur Sorties")
func launchWithoutSavedConfigurationOpensExits() {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  let plan = LaunchPlan.atLaunch(hasSavedConfiguration: store.hasSavedConfiguration)
  #expect(plan == .openSettings(.exits))
}

@Test("L’argument --open-settings general ouvre Général, même au premier lancement")
func launchArgumentOpensGeneralSettings() {
  let arguments = ["BabyWorks", "--open-settings", "general"]
  #expect(LaunchPlan.atLaunch(hasSavedConfiguration: true, arguments: arguments) == .openSettings(.general))
  #expect(LaunchPlan.atLaunch(hasSavedConfiguration: false, arguments: arguments) == .openSettings(.general))
}

@Test("Sans --open-settings general, le lancement ne change pas")
func launchWithoutLanguageArgumentKeepsTheExistingPlan() {
  #expect(LaunchPlan.atLaunch(hasSavedConfiguration: true, arguments: ["BabyWorks"]) == .idle)
  #expect(
    LaunchPlan.atLaunch(hasSavedConfiguration: false, arguments: ["BabyWorks", "--open-settings"])
      == .openSettings(.exits)
  )
  #expect(
    LaunchPlan.atLaunch(hasSavedConfiguration: true, arguments: ["BabyWorks", "--open-settings", "mode"])
      == .idle
  )
}

@Test("Une configuration présente, même illisible, laisse le lancement au repos")
func launchWithUnreadableConfigurationStaysIdle() throws {
  let file = TemporaryConfigurationFile()
  defer { file.remove() }
  try FileManager.default.createDirectory(at: file.directory, withIntermediateDirectories: true)
  try Data("ceci n'est pas du json".utf8).write(to: file.fileURL)

  let store = BabyWorksConfigurationStore(fileURL: file.fileURL)
  let plan = LaunchPlan.atLaunch(hasSavedConfiguration: store.hasSavedConfiguration)
  #expect(plan == .idle)
}

private struct TemporaryConfigurationFile {
  let directory: URL
  let fileURL: URL

  init() {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(
      "LaunchPlanTests-\(UUID().uuidString)",
      isDirectory: true
    )
    fileURL = directory.appendingPathComponent("config.json")
  }

  func remove() {
    try? FileManager.default.removeItem(at: directory)
  }
}
