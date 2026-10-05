import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Une cible accélère jusqu’au plafond, puis file à vitesse constante sans dépasser le vaisseau")
func starshipFlightAcceleratesThenStopsAtTheShip() {
  let flight = StarshipFlight(
    start: StarshipPoint(x: 0, y: 0),
    goal: StarshipPoint(x: 2000, y: 0),
    initialSpeed: 100,
    acceleration: 200,
    maxSpeed: 600
  )

  #expect(abs(flight.distance(at: 0) - 0) < 1e-6)
  #expect(abs(flight.distance(at: 1) - 200) < 1e-6)
  #expect(abs(flight.distance(at: 2.5) - 875) < 1e-6)
  #expect(abs(flight.distance(at: 3) - 1175) < 1e-6)
  expectPoint(flight.position(at: 1), 200, 0)
  expectPoint(flight.position(at: 100), 2000, 0)
  #expect(abs(flight.remaining(at: 1) - 1800) < 1e-6)
  #expect(abs(flight.remaining(at: 100) - 0) < 1e-6)
  #expect(abs(flight.heading - 0) < 1e-6)
}

@Test("Une vitesse de départ déjà au plafond reste constante")
func starshipFlightAlreadyAtMaxSpeedStaysThere() {
  let flight = StarshipFlight(
    start: StarshipPoint(x: 0, y: 0),
    goal: StarshipPoint(x: 2000, y: 0),
    initialSpeed: 800,
    acceleration: 200,
    maxSpeed: 600
  )

  #expect(abs(flight.distance(at: 1) - 600) < 1e-6)
  #expect(abs(flight.distance(at: 2) - 1200) < 1e-6)
}

@Test("Un tirage de vitesse et d’accélération reste dans les bornes du réglage")
func starshipFlightRandomStaysInsideTheTuningRanges() {
  let tuning = StarshipTuning.standard
  let start = StarshipPoint(x: 0, y: 0)
  let goal = StarshipPoint(x: 100, y: 0)
  for (speedRoll, accelerationRoll) in [(0.0, 0.0), (0.999_999, 0.999_999)] {
    let flight = StarshipFlight.random(
      start: start,
      goal: goal,
      tuning: tuning,
      speedRoll: speedRoll,
      accelerationRoll: accelerationRoll
    )
    #expect(tuning.initialSpeedRange.contains(flight.initialSpeed))
    #expect(tuning.accelerationRange.contains(flight.acceleration))
    #expect(flight.maxSpeed == tuning.maxSpeed)
  }
}

@Test("Le temps pour parcourir une distance est l’inverse du vol, et zéro avant le départ")
func starshipFlightTimeToTravelInvertsDistance() {
  let flight = StarshipFlight(
    start: StarshipPoint(x: 0, y: 0),
    goal: StarshipPoint(x: 2000, y: 0),
    initialSpeed: 100,
    acceleration: 200,
    maxSpeed: 600
  )

  #expect(abs(flight.time(toTravel: 0) - 0) < 1e-6)
  #expect(abs(flight.time(toTravel: -10) - 0) < 1e-6)
  #expect(abs(flight.time(toTravel: 200) - 1) < 1e-6)
  #expect(abs(flight.time(toTravel: 875) - 2.5) < 1e-6)
  #expect(abs(flight.time(toTravel: 1175) - 3) < 1e-6)
  var elapsed = 0.0
  while elapsed <= 5 {
    let traveled = flight.distance(at: elapsed)
    #expect(abs(flight.time(toTravel: traveled) - elapsed) < 1e-6)
    elapsed += 0.25
  }
}

private func expectPoint(_ point: StarshipPoint, _ x: Double, _ y: Double) {
  #expect(abs(point.x - x) < 1e-6)
  #expect(abs(point.y - y) < 1e-6)
}
