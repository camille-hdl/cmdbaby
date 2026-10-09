import Foundation
import Testing

@testable import CmdBabyKit

private let calendar: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(identifier: "UTC")!
  return calendar
}()

private let today = calendar.date(from: DateComponents(year: 2026, month: 10, day: 20))!

@Test("Les journaux de plus de 14 jours sont purgés")
func logsOlderThanFourteenDaysArePurged() {
  let files = [
    LogFileInfo(name: "cmdbaby-20261005.log", size: 10),
    LogFileInfo(name: "cmdbaby-20261005-2.log", size: 10),
    LogFileInfo(name: "cmdbaby-20261006.log", size: 10),
    LogFileInfo(name: "cmdbaby-20261020.log", size: 10),
  ]
  #expect(
    LifecycleLogRetention.filesToDelete(files, today: today, calendar: calendar)
      == ["cmdbaby-20261005.log", "cmdbaby-20261005-2.log"]
  )
}

@Test("Au-delà de 20 Mo, les plus anciens partent d’abord, jamais le plus récent")
func logFolderIsCappedOldestFirst() {
  let mb = 1024 * 1024
  let files = [
    LogFileInfo(name: "cmdbaby-20261019.log", size: 8 * mb),
    LogFileInfo(name: "cmdbaby-20261018.log", size: 8 * mb),
    LogFileInfo(name: "cmdbaby-20261020.log", size: 8 * mb),
    LogFileInfo(name: "cmdbaby-20261019-2.log", size: 2 * mb),
  ]
  #expect(
    LifecycleLogRetention.filesToDelete(files, today: today, calendar: calendar)
      == ["cmdbaby-20261018.log"]
  )
  let huge = [LogFileInfo(name: "cmdbaby-20261020.log", size: 30 * mb)]
  #expect(LifecycleLogRetention.filesToDelete(huge, today: today, calendar: calendar).isEmpty)
}

@Test("Un fichier qui n’est pas un journal n’est jamais supprimé")
func foreignFilesAreKept() {
  let files = [
    LogFileInfo(name: "notes.txt", size: 50 * 1024 * 1024),
    LogFileInfo(name: "babywork-20200101.log", size: 10),
  ]
  #expect(LifecycleLogRetention.filesToDelete(files, today: today, calendar: calendar).isEmpty)
}

@Test("Les chemins journalisés remplacent le dossier personnel par ~")
func loggedPathsHideTheHomeFolder() {
  let home = NSHomeDirectory()
  #expect(LifecycleLog.displayPath(home + "/Applications/CmdBaby.app") == "~/Applications/CmdBaby.app")
  #expect(LifecycleLog.displayPath("/Applications/CmdBaby.app") == "/Applications/CmdBaby.app")
}

/// Règle : aucun événement ne porte de caractère tapé, de keycode ni de phrase.
/// Ce `switch` exhaustif force à relire la règle à chaque nouvel événement.
@Test("Aucun événement du journal ne porte de donnée clavier")
func lifecycleEventsCarryNoKeyboardData() {
  let samples: [LifecycleLogEvent] = [
    .statusItemCreate, .activationPolicy(before: "a", after: "b"), .sessionStart(origin: .shortcuts),
    .sessionPhase(from: .configuration, to: .active), .sessionStop(kind: .adultExit),
    .teardownBegin(shouldQuit: false, coverCount: 1, caller: .swift),
    .teardownDone(shouldQuit: false, coverCount: 1, caller: .swift),
    .tapCreate, .tapEnable, .tapDisable(reason: "stop"), .tapFail(reason: "creation"),
    .tapReenable(reason: "timeout"), .settingsShowRequest,
    .settingsOrderFront(isVisible: true, isKeyWindow: true, outcome: .success, retry: 0),
    .coversKey(isKey: true, outcome: .success, retry: 0), .terminateRequest,
    .applicationShouldTerminate(reply: .now), .statusItemAlive(true),
    .sessionActivationFail(reason: "noScreens", binaryPath: "~/CmdBaby.app"),
    .coversFollowScreens(added: 1, removed: 0, reframed: 0), .displaySleepAssertion(taken: true),
    .guardTapLost, .guardSecureInput, .guardRefocus, .statusIconMissing,
    .resourceBundleMissing(name: "CmdBaby_CmdBabyKit.bundle"),
  ]
  for event in samples {
    switch event {
    case .statusItemCreate, .activationPolicy, .sessionStart(_), .sessionPhase, .sessionStop,
      .teardownBegin, .teardownDone, .tapCreate, .tapEnable, .tapDisable, .tapFail, .tapReenable,
      .settingsShowRequest, .settingsOrderFront, .coversKey, .terminateRequest,
      .applicationShouldTerminate, .statusItemAlive, .sessionActivationFail, .coversFollowScreens,
      .displaySleepAssertion, .guardTapLost, .guardSecureInput, .guardRefocus, .statusIconMissing,
      .resourceBundleMissing:
      break
    }
    for child in Mirror(reflecting: event).children {
      for field in Mirror(reflecting: child.value).children.map(\.value) + [child.value] {
        #expect(!(field is Character), "Caractère dans \(event)")
        #expect(!(field is Set<Character>), "Lettres dans \(event)")
        #expect(!(field is [Character]), "Lettres dans \(event)")
        #expect(!(field is UInt16), "Keycode possible dans \(event)")
      }
    }
  }
}
