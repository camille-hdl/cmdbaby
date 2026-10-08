import Testing

@testable import CmdBabyKit

@Test("Un premier tour part tout de suite et finit 0,6 s plus tard")
func starshipSpinQueueFirstTurnStartsNow() {
  var queue = StarshipSpinQueue()
  let start = queue.addTurn(now: 10, duration: 0.6, maxBacklog: 10)
  #expect(abs((start ?? .nan) - 10) < 1e-6)
  #expect(abs(queue.endsAt - 10.6) < 1e-6)
}

@Test("Trois appuis rapprochés enchaînent trois tours, soit 1,8 s")
func starshipSpinQueueRapidPressesLastThreeTimesLonger() {
  var queue = StarshipSpinQueue()
  let first = queue.addTurn(now: 1_000, duration: 0.6, maxBacklog: 10)
  let second = queue.addTurn(now: 1_000.05, duration: 0.6, maxBacklog: 10)
  let third = queue.addTurn(now: 1_000.1, duration: 0.6, maxBacklog: 10)
  #expect(abs((first ?? .nan) - 1_000) < 1e-6)
  #expect(abs((second ?? .nan) - 1_000.6) < 1e-6)
  #expect(abs((third ?? .nan) - 1_001.2) < 1e-6)
  #expect(abs(queue.endsAt - 1_001.8) < 1e-6)
}

@Test("Un tour demandé après la fin de file repart tout de suite")
func starshipSpinQueueRestartsOnceEarlierTurnsHaveFinished() {
  var queue = StarshipSpinQueue()
  _ = queue.addTurn(now: 10, duration: 0.6, maxBacklog: 10)
  let start = queue.addTurn(now: 12, duration: 0.6, maxBacklog: 10)
  #expect(abs((start ?? .nan) - 12) < 1e-6)
  #expect(abs(queue.endsAt - 12.6) < 1e-6)
}

@Test("Une rafale de trente appuis ne met pas plus de 1,8 s de tours en attente")
func starshipSpinQueueBurstIsBounded() {
  var queue = StarshipSpinQueue()
  for press in 0..<30 {
    queue.addTurn(now: 100 + Double(press) * 0.1, duration: 0.6, maxBacklog: 1.8)
  }
  #expect(queue.endsAt - 102.9 <= 1.8 + 1e-6)
}

@Test("Un appui refusé par la file pleine ne lance aucun tour")
func starshipSpinQueueRefusesTurnWhenFull() {
  var queue = StarshipSpinQueue()
  let accepted = (0..<3).compactMap { _ in queue.addTurn(now: 0, duration: 0.6, maxBacklog: 1.8) }
  let refused = queue.addTurn(now: 0, duration: 0.6, maxBacklog: 1.8)
  #expect(accepted.count == 3)
  #expect(refused == nil)
  #expect(abs(queue.endsAt - 1.8) < 1e-6)
}
