import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Forcer l’idle depuis n’importe quel fil pose .configuration et journalise session.stop")
func forceConfigurationSetsIdleAndLogsSessionStop() {
  let sink = CapturingStoreLogSink()
  let store = KioskSessionStore()
  store.replace(
    KioskSessionState(phase: .active, coveredScreens: [
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
    ])
  )

  let idle = store.forceConfiguration(
    exitKind: .passphrase,
    log: LifecycleLogRecorder(sinks: [sink])
  )

  #expect(idle.phase == .configuration)
  #expect(idle.lastExitKind == .passphrase)
  #expect(idle.coveredScreens.isEmpty)
  #expect(idle.lastError == nil)
  #expect(store.isIdle())
  #expect(store.current().phase == .configuration)
  #expect(sink.messages.contains("session.stop kind=adultExit"))
  #expect(sink.messages.contains("session.phase from=active to=configuration"))
}

@Test("Forcer l’idle déjà journalisé ne re-émet pas session.stop")
func forceConfigurationSkipsSessionStopWhenAlreadyLogged() {
  let sink = CapturingStoreLogSink()
  let log = LifecycleLogRecorder(sinks: [sink])
  let store = KioskSessionStore()
  store.replace(KioskSessionState(phase: .stopping))
  store.markSessionStopLogged()

  _ = store.forceConfiguration(exitKind: .failsafeClick, log: log)

  #expect(store.isIdle())
  #expect(!sink.messages.contains("session.stop kind=adultExit"))
  #expect(sink.messages.contains("session.phase from=stopping to=configuration"))
}

@Test("isIdle n’est vrai que pour .configuration")
func isIdleMatchesConfigurationPhaseOnly() {
  let store = KioskSessionStore()
  #expect(store.isIdle())

  store.replace(KioskSessionState(phase: .active))
  #expect(!store.isIdle())

  store.replace(KioskSessionState(phase: .stopping))
  #expect(!store.isIdle())

  store.replace(KioskSessionState(phase: .failed))
  #expect(!store.isIdle())

  store.replace(KioskSessionState(phase: .configuration))
  #expect(store.isIdle())
}

private final class CapturingStoreLogSink: LifecycleLogSink, @unchecked Sendable {
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
