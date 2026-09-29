import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Si l’idle est atteint tout de suite, le filet ne force rien")
func adultExitPipelineSkipsFallbackWhenPerformReachesIdle() {
  let idle = IdleFlag()
  let forced = Counter()
  let scheduledFallback = IdleFlag()

  AdultExitPipeline().complete(
    perform: { idle.value = true },
    isIdle: { idle.value },
    forceIdle: { forced.value += 1 },
    scheduleFallback: { _ in scheduledFallback.value = true }
  )

  #expect(idle.value)
  #expect(forced.value == 0)
  #expect(!scheduledFallback.value)
}

@Test("Si perform n’atteint pas l’idle, le filet force l’idle")
func adultExitPipelineFallbackForcesIdleWhenPerformDoesNot() {
  let idle = IdleFlag()
  let forced = Counter()
  let scheduledWork = WorkBox()

  AdultExitPipeline().complete(
    perform: {},
    isIdle: { idle.value },
    forceIdle: {
      forced.value += 1
      idle.value = true
    },
    scheduleFallback: { work in scheduledWork.value = work }
  )

  #expect(!idle.value)
  #expect(forced.value == 0)
  #expect(scheduledWork.value != nil)

  scheduledWork.value?()

  #expect(idle.value)
  #expect(forced.value == 1)
}

@Test("Le filet est no-op si l’idle arrive avant qu’il s’exécute")
func adultExitPipelineFallbackIsNoOpOnceIdle() {
  let idle = IdleFlag()
  let forced = Counter()
  let scheduledWork = WorkBox()

  AdultExitPipeline().complete(
    perform: {},
    isIdle: { idle.value },
    forceIdle: { forced.value += 1 },
    scheduleFallback: { work in scheduledWork.value = work }
  )

  idle.value = true
  scheduledWork.value?()

  #expect(forced.value == 0)
}

@Test("Le filet force .configuration via le store, sans rappeler perform")
func fallbackForcesStoreIdleWithoutCallingPerform() {
  let store = KioskSessionStore()
  store.replace(KioskSessionState(phase: .active))
  let performCount = Counter()
  let scheduledWork = WorkBox()
  let log = LifecycleLogRecorder()

  AdultExitPipeline().complete(
    perform: { performCount.value += 1 },
    isIdle: { store.isIdle() },
    forceIdle: {
      _ = store.forceConfiguration(exitKind: .passphrase, log: log)
    },
    scheduleFallback: { work in scheduledWork.value = work }
  )

  #expect(!store.isIdle())
  #expect(performCount.value == 1)

  scheduledWork.value?()

  #expect(store.isIdle())
  #expect(store.current().phase == .configuration)
  #expect(performCount.value == 1)
}

@Test("Le hop MainActor n’exécute pas en ligne")
func mainActorHopDoesNotRunInline() {
  let ran = IdleFlag()
  MainActorHop.run {
    ran.value = true
  }
  #expect(!ran.value)
}

private final class IdleFlag: @unchecked Sendable {
  var value = false
}

private final class Counter: @unchecked Sendable {
  var value = 0
}

private final class WorkBox: @unchecked Sendable {
  var value: (@Sendable () -> Void)?
}
