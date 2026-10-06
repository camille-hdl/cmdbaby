import Testing

@testable import CmdBabyKit

@Test("Un premier tour part tout de suite et finit 0,6 s plus tard")
func starshipSpinQueueFirstTurnStartsNow() {
  var queue = StarshipSpinQueue()
  let start = queue.addTurn(now: 10, duration: 0.6)
  #expect(abs(start - 10) < 1e-6)
  #expect(abs(queue.endsAt - 10.6) < 1e-6)
}

@Test("Trois appuis rapprochés enchaînent trois tours, soit 1,8 s")
func starshipSpinQueueRapidPressesLastThreeTimesLonger() {
  var queue = StarshipSpinQueue()
  let first = queue.addTurn(now: 1_000, duration: 0.6)
  let second = queue.addTurn(now: 1_000.05, duration: 0.6)
  let third = queue.addTurn(now: 1_000.1, duration: 0.6)
  #expect(abs(first - 1_000) < 1e-6)
  #expect(abs(second - 1_000.6) < 1e-6)
  #expect(abs(third - 1_001.2) < 1e-6)
  #expect(abs(queue.endsAt - 1_001.8) < 1e-6)
}

@Test("Un tour demandé après la fin de file repart tout de suite")
func starshipSpinQueueRestartsOnceEarlierTurnsHaveFinished() {
  var queue = StarshipSpinQueue()
  _ = queue.addTurn(now: 10, duration: 0.6)
  let start = queue.addTurn(now: 12, duration: 0.6)
  #expect(abs(start - 12) < 1e-6)
  #expect(abs(queue.endsAt - 12.6) < 1e-6)
}
