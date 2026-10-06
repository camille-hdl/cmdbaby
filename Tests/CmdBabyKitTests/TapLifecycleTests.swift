import Testing

@testable import CmdBabyKit

@Test("Un arrêt demandé avant la création du port fait invalider le tap, sans l’activer")
func stopBeforePortCreationInvalidatesTheTap() {
  var lifecycle = TapLifecycle()
  #expect(lifecycle.requestStop() == .nothingToStop)
  #expect(lifecycle.portCreated() == .invalidate)
}

@Test("Un arrêt demandé après la création du port désactive le tap puis arrête la boucle")
func stopAfterPortCreationDisablesThenStopsTheLoop() {
  var lifecycle = TapLifecycle()
  #expect(lifecycle.portCreated() == .enable)
  #expect(lifecycle.requestStop() == .disableAndStopLoop)
}

@Test("Un second arrêt ne refait rien")
func secondStopDoesNothing() {
  var lifecycle = TapLifecycle()
  _ = lifecycle.portCreated()
  _ = lifecycle.requestStop()
  #expect(lifecycle.requestStop() == .nothingToStop)
}

@Test("Le kill switch d’un filtre arrêté reste engagé quand un autre filtre fait reset")
func killSwitchesAreIndependent() {
  let stopped = SessionInputKillSwitch()
  let next = SessionInputKillSwitch()
  stopped.engage()
  next.engage()

  next.reset()

  #expect(stopped.isEngaged)
  #expect(!next.isEngaged)
}
