import Testing

@testable import CmdBabyKit

@Test("Le vaisseau est centré, à une fraction de la hauteur depuis le bas")
func starshipShipSitsCenteredAFractionFromTheBottom() {
  expectPoint(
    StarshipShip.center(width: 1440, height: 900, fractionFromBottom: 0.18),
    720,
    162
  )
  expectPoint(
    StarshipShip.center(width: 800, height: 600, fractionFromBottom: 0.18),
    400,
    108
  )
  expectPoint(
    StarshipShip.center(width: 2560, height: 1440, fractionFromBottom: 0.25),
    1280,
    360
  )
}

private func expectPoint(_ point: StarshipPoint, _ x: Double, _ y: Double) {
  #expect(abs(point.x - x) < 1e-6)
  #expect(abs(point.y - y) < 1e-6)
}
