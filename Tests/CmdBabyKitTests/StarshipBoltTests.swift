import Testing

@testable import CmdBabyKit

@Test("Le tir au clic file du nez jusqu’à la cible, sans retour")
func boltFliesFromTheNoseToTheTargetWithoutReversing() {
  let flight = StarshipBolt.flight(
    from: StarshipPoint(x: 80, y: 40),
    to: StarshipPoint(x: 80, y: 640)
  )

  #expect(abs(flight.from.x - 80) < 1e-6)
  #expect(abs(flight.from.y - 40) < 1e-6)
  #expect(abs(flight.to.x - 80) < 1e-6)
  #expect(abs(flight.to.y - 640) < 1e-6)
  #expect(flight.reverses == false)
  #expect(flight.repeatCount == 0)
}
