import Foundation
import Testing

@testable import CmdBabyKit

@Test("Les événements obligatoires produisent une ligne grepable")
func mandatoryEventsFormatToStableLines() {
  #expect(LifecycleLogEvent.statusItemCreate.message == "statusItem.create")
  #expect(LifecycleLogEvent.statusItemCreate.category == .lifecycle)

  #expect(
    LifecycleLogEvent.activationPolicy(before: "accessory", after: "regular").message
      == "activationPolicy before=accessory after=regular"
  )
  #expect(
    LifecycleLogEvent.activationPolicy(before: "accessory", after: "regular").category == .lifecycle
  )

  #expect(LifecycleLogEvent.sessionStart.message == "session.start")
  #expect(LifecycleLogEvent.sessionStart.category == .session)
  #expect(
    LifecycleLogEvent.sessionPhase(from: .configuration, to: .preparing).message
      == "session.phase from=configuration to=preparing"
  )
  #expect(
    LifecycleLogEvent.sessionStop(kind: .adultExit).message == "session.stop kind=adultExit"
  )
  #expect(
    LifecycleLogEvent.sessionStop(kind: .explicitQuit).message == "session.stop kind=explicitQuit"
  )
  #expect(LifecycleLogEvent.sessionStop(kind: .adultExit).category == .session)

  #expect(
    LifecycleLogEvent.teardownBegin(shouldQuit: false, coverCount: 2, caller: .swift).message
      == "teardown.begin should_quit=false cover_count=2 caller=swift"
  )
  #expect(
    LifecycleLogEvent.teardownDone(shouldQuit: true, coverCount: 0, caller: .swift).message
      == "teardown.done should_quit=true cover_count=0 caller=swift"
  )
  #expect(
    LifecycleLogEvent.teardownBegin(shouldQuit: false, coverCount: 2, caller: .swift).category
      == .kioskTeardown
  )

  #expect(LifecycleLogEvent.tapCreate.message == "tap.create")
  #expect(LifecycleLogEvent.tapEnable.message == "tap.enable")
  #expect(LifecycleLogEvent.tapDisable(reason: "stop").message == "tap.disable reason=stop")
  #expect(LifecycleLogEvent.tapFail(reason: "creation").message == "tap.fail reason=creation")
  #expect(
    LifecycleLogEvent.tapReenable(reason: "timeout").message == "tap.reenable reason=timeout"
  )
  #expect(LifecycleLogEvent.tapCreate.category == .inputFilter)

  #expect(LifecycleLogEvent.settingsShowRequest.message == "settings.show.request")
  #expect(
    LifecycleLogEvent.settingsOrderFront(
      isVisible: true,
      isKeyWindow: false,
      outcome: .fail,
      retry: 0
    ).message
      == "settings.orderFront isVisible=true isKeyWindow=false outcome=fail"
  )
  #expect(
    LifecycleLogEvent.settingsOrderFront(
      isVisible: true,
      isKeyWindow: true,
      outcome: .success,
      retry: 2
    ).message
      == "settings.orderFront isVisible=true isKeyWindow=true outcome=success retry=2"
  )
  #expect(LifecycleLogEvent.settingsShowRequest.category == .settings)

  #expect(
    LifecycleLogEvent.coversKey(isKey: true, outcome: .success, retry: 0).message
      == "covers.key isKey=true outcome=success"
  )
  #expect(
    LifecycleLogEvent.coversKey(isKey: false, outcome: .fail, retry: 1).message
      == "covers.key isKey=false outcome=fail retry=1"
  )
  #expect(LifecycleLogEvent.coversKey(isKey: true, outcome: .success, retry: 0).category == .session)

  #expect(LifecycleLogEvent.terminateRequest.message == "terminate.request")
  #expect(
    LifecycleLogEvent.applicationShouldTerminate(reply: .now).message
      == "applicationShouldTerminate reply=now"
  )
  #expect(
    LifecycleLogEvent.applicationShouldTerminate(reply: .cancel).message
      == "applicationShouldTerminate reply=cancel"
  )
  #expect(LifecycleLogEvent.terminateRequest.category == .lifecycle)

  #expect(LifecycleLogEvent.statusItemAlive(true).message == "statusItem.alive=true")
  #expect(LifecycleLogEvent.statusItemAlive(false).message == "statusItem.alive=false")
  #expect(LifecycleLogEvent.statusItemAlive(true).category == .lifecycle)
}

@Test("Le sous-système os_log est le bundle id")
func logSubsystemIsBundleIdentifier() {
  #expect(LifecycleLog.subsystem == "app.cmdbaby.CmdBaby")
}

@Test("Les lignes fichier portent horodatage, catégorie et message")
func fileLinesIncludeTimestampCategoryAndMessage() {
  let date = utcDate(year: 2026, month: 9, day: 29, hour: 8, minute: 14)
  let line = LifecycleLog.fileLine(for: .sessionStart, at: date)
  #expect(line == "2026-09-29T08:14:00Z [Session] session.start")
}

@Test("Le chemin par défaut est Application Support/CmdBaby/logs")
func defaultLogDirectoryIsApplicationSupportCmdBabyLogs() {
  let url = LifecycleLogFile.defaultDirectory
  #expect(url.lastPathComponent == "logs")
  #expect(url.deletingLastPathComponent().lastPathComponent == "CmdBaby")
  #expect(
    url.deletingLastPathComponent().deletingLastPathComponent().lastPathComponent
      == "Application Support"
  )
}

@Test("Le fichier du jour s’appelle cmdbaby-YYYYMMDD.log")
func datedLogFileUsesDayStamp() throws {
  let directory = TemporaryLogDirectory()
  defer { directory.remove() }
  let now = utcDate(year: 2026, month: 9, day: 29, hour: 10, minute: 12)
  let file = LifecycleLogFile(
    directory: directory.url,
    calendar: utcCalendar,
    now: { now }
  )

  file.write(.sessionStart)

  let logURL = directory.url.appendingPathComponent("cmdbaby-20260929.log")
  let contents = try String(contentsOf: logURL, encoding: .utf8)
  #expect(contents.contains("[Session] session.start"))
  #expect(contents.hasSuffix("\n"))
}

@Test("Un nouveau jour ouvre un nouveau fichier")
func newDayOpensANewFile() throws {
  let directory = TemporaryLogDirectory()
  defer { directory.remove() }
  let clock = ManualDateClock(utcDate(year: 2026, month: 9, day: 29, hour: 23, minute: 50))
  let file = LifecycleLogFile(
    directory: directory.url,
    calendar: utcCalendar,
    now: { clock.now }
  )

  file.write(.sessionStart)
  clock.now = utcDate(year: 2026, month: 9, day: 30, hour: 0, minute: 1)
  file.write(.sessionStop(kind: .adultExit))

  let day29 = try String(
    contentsOf: directory.url.appendingPathComponent("cmdbaby-20260929.log"),
    encoding: .utf8
  )
  let day30 = try String(
    contentsOf: directory.url.appendingPathComponent("cmdbaby-20260930.log"),
    encoding: .utf8
  )
  #expect(day29.contains("session.start"))
  #expect(!day29.contains("session.stop"))
  #expect(day30.contains("session.stop kind=adultExit"))
}

@Test("Un fichier trop gros passe à cmdbaby-YYYYMMDD-2.log")
func oversizedFileRotatesToNumberedSibling() throws {
  let directory = TemporaryLogDirectory()
  defer { directory.remove() }
  let now = utcDate(year: 2026, month: 9, day: 29, hour: 8, minute: 0)
  let file = LifecycleLogFile(
    directory: directory.url,
    calendar: utcCalendar,
    now: { now },
    maxBytes: 80
  )

  file.write(.sessionStart)
  file.write(.sessionStop(kind: .adultExit))

  let first = try String(
    contentsOf: directory.url.appendingPathComponent("cmdbaby-20260929.log"),
    encoding: .utf8
  )
  let second = try String(
    contentsOf: directory.url.appendingPathComponent("cmdbaby-20260929-2.log"),
    encoding: .utf8
  )
  #expect(first.contains("session.start"))
  #expect(!first.contains("session.stop"))
  #expect(second.contains("session.stop kind=adultExit"))
}

@Test("Idle → session → sortie adulte → session émet la séquence session")
@MainActor
func idleStartAdultExitStartEmitsSessionSequence() async {
  let sink = CapturingLifecycleLogSink()
  let log = LifecycleLogRecorder(sinks: [sink])
  let services = SequenceKioskServices()
  let controller = KioskSessionController(services: services, log: log)

  _ = await controller.activate()
  _ = controller.deactivate(.adultExit(.passphrase))
  _ = await controller.activate()

  #expect(
    sink.messages == [
      "session.start",
      "session.phase from=configuration to=preparing",
      "session.phase from=preparing to=activating",
      "session.phase from=activating to=active",
      "session.phase from=active to=stopping",
      "teardown.begin should_quit=false cover_count=1 caller=swift",
      "teardown.done should_quit=false cover_count=1 caller=swift",
      "session.stop kind=adultExit",
      "session.phase from=stopping to=configuration",
      "session.start",
      "session.phase from=configuration to=preparing",
      "session.phase from=preparing to=activating",
      "session.phase from=activating to=active",
    ]
  )
}

private let utcCalendar: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = TimeZone(secondsFromGMT: 0)!
  return calendar
}()

private func utcDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
  utcCalendar.date(
    from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
  )!
}

private final class ManualDateClock: @unchecked Sendable {
  var now: Date
  init(_ now: Date) {
    self.now = now
  }
}

private struct TemporaryLogDirectory {
  let url: URL

  init() {
    url = FileManager.default.temporaryDirectory.appendingPathComponent(
      "CmdBabyLogTests-\(UUID().uuidString)",
      isDirectory: true
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: url)
  }
}

private final class CapturingLifecycleLogSink: LifecycleLogSink, @unchecked Sendable {
  private let lock = NSLock()
  private var collected: [String] = []

  var messages: [String] {
    lock.lock()
    defer { lock.unlock() }
    return collected
  }

  func write(_ event: LifecycleLogEvent) {
    lock.lock()
    collected.append(event.message)
    lock.unlock()
  }
}

@MainActor
private final class SequenceKioskServices: KioskSessionServices {
  func capturePresentation() throws -> PresentationOptionsSnapshot {
    PresentationOptionsSnapshot(rawValue: 0)
  }

  func createCoverWindows() throws -> [ScreenDescriptor] {
    [
      ScreenDescriptor(
        id: "built-in",
        name: "Built-in",
        originX: 0,
        originY: 0,
        width: 100,
        height: 100,
        scale: 1,
        isMain: true
      )
    ]
  }

  func applyKioskPresentation() async throws {}
  func startInputFilter() async throws {}
  func restorePresentation(_ snapshot: PresentationOptionsSnapshot) {}
  func closeCoverWindows() {}
  func stopInputFilter() {}
  func hideDiagnosticInterface() {}
}
