import Testing

@testable import CmdBabyKit

@Test("Un roll parcourt le bord haut, à margin au-dessus, sur toute la largeur")
func starshipSpawnRollsAcrossTheTopEdge() {
  expectPoint(
    StarshipSpawn.topEdgePoint(width: 1440, height: 900, margin: 60, roll: 0),
    0,
    960
  )
  expectPoint(
    StarshipSpawn.topEdgePoint(width: 1440, height: 900, margin: 60, roll: 0.25),
    360,
    960
  )
  expectPoint(
    StarshipSpawn.topEdgePoint(width: 1440, height: 900, margin: 60, roll: 0.5),
    720,
    960
  )
  expectPoint(
    StarshipSpawn.topEdgePoint(width: 1000, height: 400, margin: 25, roll: 0.8),
    800,
    425
  )
}

@Test("Mille rolls sur le bord haut restent à margin au-dessus et couvrent la largeur")
func starshipSpawnKeepsTopEdgeRollsAboveTheScreen() {
  let width = 800.0
  let height = 500.0
  let margin = 40.0
  var minX = Double.greatestFiniteMagnitude
  var maxX = -Double.greatestFiniteMagnitude
  for step in 0..<1_000 {
    let point = StarshipSpawn.topEdgePoint(
      width: width,
      height: height,
      margin: margin,
      roll: Double(step) / 1_000
    )
    #expect(abs(point.y - 540) < 1e-6)
    #expect(point.x >= -1e-6)
    #expect(point.x < width)
    minX = min(minX, point.x)
    maxX = max(maxX, point.x)
  }
  #expect(abs(minX) < 1e-6)
  #expect(maxX > width - 1)
}

@Test("Un roll hors de [0, 1) reste sur le bord haut, à margin")
func starshipSpawnClampsTopEdgeRollAboveTheScreen() {
  let above = 960.0
  for roll in [1.0, -0.5, 2.0] {
    let point = StarshipSpawn.topEdgePoint(width: 1440, height: 900, margin: 60, roll: roll)
    #expect(abs(point.y - above) < 1e-6)
    #expect(point.x >= -1e-6)
    #expect(point.x <= 1440)
  }
}

private func expectPoint(_ point: StarshipPoint, _ x: Double, _ y: Double) {
  #expect(abs(point.x - x) < 1e-6)
  #expect(abs(point.y - y) < 1e-6)
}
