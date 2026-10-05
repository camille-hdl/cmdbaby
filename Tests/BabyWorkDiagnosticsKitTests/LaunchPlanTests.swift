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
