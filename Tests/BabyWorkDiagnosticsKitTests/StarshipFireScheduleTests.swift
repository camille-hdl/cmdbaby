import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Loin du vaisseau, le tir automatique attend 2 s, 2,3 s ou 2,6 s selon le tirage")
func starshipFireDelayFarFromTheShipFollowsTheRoll() {
  let flight = referenceFlight(goalX: 2000)
  let tuning = StarshipTuning.standard

  #expect(abs(StarshipFireSchedule.delay(for: flight, tuning: tuning, roll: 0) - 2) < 1e-6)
  #expect(abs(StarshipFireSchedule.delay(for: flight, tuning: tuning, roll: 0.5) - 2.3) < 1e-6)
  #expect(abs(StarshipFireSchedule.delay(for: flight, tuning: tuning, roll: 1) - 2.6) < 1e-6)
}

@Test("Une cible dont la dernière seconde sûre tombe dans la fourchette est abattue à cet instant, ici 2,3 s")
func starshipFireDelayNearTheShipUsesTheLatestSafeInstant() {
  let flight = referenceFlight(goalX: 959)
  let delay = StarshipFireSchedule.delay(for: flight, tuning: .standard, roll: 1)
  #expect(abs(delay - 2.3) < 1e-6)
}

@Test("Même si la cible va toucher le bouclier avant, le tir n’arrive jamais avant 2 s")
func starshipFireDelayNeverBeatsTheMinimum() {
  let flight = referenceFlight(goalX: 250)
  let tuning = StarshipTuning.standard

  #expect(abs(StarshipFireSchedule.delay(for: flight, tuning: tuning, roll: 0) - 2) < 1e-6)
  #expect(abs(StarshipFireSchedule.delay(for: flight, tuning: tuning, roll: 1) - 2) < 1e-6)
}

@Test("Une cible entrée dans le bouclier avant 2 s reste visible jusqu’au tir")
func starshipTargetInsideTheShieldStaysUntilTheShot() {
  let flight = referenceFlight(goalX: 250)
  let tuning = StarshipTuning.standard
  let delay = StarshipFireSchedule.delay(for: flight, tuning: tuning, roll: 0)
  #expect(abs(delay - 2) < 1e-6)

  let insideShield = 0.8
  #expect(flight.remaining(at: insideShield) < tuning.shieldRadius)
  #expect(
    StarshipFireSchedule.shieldDestroys(
      flight: flight,
      elapsed: insideShield,
      fireDelay: delay,
      tuning: tuning
    ) == false
  )
  #expect(flight.remaining(at: delay) == 0)
  #expect(
    StarshipFireSchedule.shieldDestroys(
      flight: flight,
      elapsed: delay - 0.001,
      fireDelay: delay,
      tuning: tuning
    ) == false
  )
}

@Test("Sur 500 vols au hasard, le tir attend au moins 2 s et part avant le bouclier quand c’est possible")
func starshipFireDelayOnALargeScreenStaysBeforeTheShield() {
  var rng = SplitMix64(seed: 1)
  let tuning = StarshipTuning.standard
  let width = 1440.0
  let height = 900.0
  let goal = StarshipPoint(x: width / 2, y: height / 2)

  for _ in 0..<500 {
    let start = StarshipSpawn.edgePoint(
      width: width,
      height: height,
      margin: 0,
      roll: Double.random(in: 0..<1, using: &rng)
    )
    let flight = StarshipFlight.random(
      start: start,
      goal: goal,
      tuning: tuning,
      speedRoll: Double.random(in: 0..<1, using: &rng),
      accelerationRoll: Double.random(in: 0..<1, using: &rng)
    )
    let delay = StarshipFireSchedule.delay(
      for: flight,
      tuning: tuning,
      roll: Double.random(in: 0..<1, using: &rng)
    )
    #expect(delay >= tuning.minimumFireDelay)
    let travel = max(0, flight.totalDistance - tuning.shieldRadius - tuning.fireSafetyMargin)
    let latest = flight.time(toTravel: travel)
    if latest >= tuning.minimumFireDelay {
      #expect(flight.remaining(at: delay) >= tuning.shieldRadius)
    }
  }
}

private struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}

private func referenceFlight(goalX: Double) -> StarshipFlight {
  StarshipFlight(
    start: StarshipPoint(x: 0, y: 0),
    goal: StarshipPoint(x: goalX, y: 0),
    initialSpeed: 100,
    acceleration: 200,
    maxSpeed: 600
  )
}
