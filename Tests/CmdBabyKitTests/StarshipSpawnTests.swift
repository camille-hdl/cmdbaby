import Testing

@testable import CmdBabyKit

@Test("Un roll parcourt le périmètre, en partant du coin bas-gauche")
func starshipSpawnWalksThePerimeter() {
  let width = 1440.0
  let height = 900.0
  let margin = 60.0

  expectPoint(StarshipSpawn.edgePoint(width: width, height: height, margin: margin, roll: 0), 0, -60)
  expectPoint(StarshipSpawn.edgePoint(width: width, height: height, margin: margin, roll: 0.1), 468, -60)
  expectPoint(StarshipSpawn.edgePoint(width: width, height: height, margin: margin, roll: 0.4), 1500, 432)
  expectPoint(StarshipSpawn.edgePoint(width: width, height: height, margin: margin, roll: 0.6), 972, 960)
  expectPoint(StarshipSpawn.edgePoint(width: width, height: height, margin: margin, roll: 0.9), -60, 468)
}

@Test("Un roll hors de [0, 1) reste sur le périmètre élargi")
func starshipSpawnClampsRollOntoThePerimeter() {
  let width = 1440.0
  let height = 900.0
  let margin = 60.0
  expectOnExpandedEdge(
    StarshipSpawn.edgePoint(width: width, height: height, margin: margin, roll: 1),
    width: width,
    height: height,
    margin: margin
  )
  expectOnExpandedEdge(
    StarshipSpawn.edgePoint(width: width, height: height, margin: margin, roll: -0.5),
    width: width,
    height: height,
    margin: margin
  )
}

@Test("Mille rolls réguliers posent chaque point juste à l’extérieur d’un bord")
func starshipSpawnKeepsRegularRollsJustOutsideAnEdge() {
  let width = 1440.0
  let height = 900.0
  let margin = 60.0
  for step in 0..<1_000 {
    let point = StarshipSpawn.edgePoint(
      width: width,
      height: height,
      margin: margin,
      roll: Double(step) / 1_000
    )
    expectOnExpandedEdge(point, width: width, height: height, margin: margin)
  }
}

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

/// À exactement `margin` en dehors d’un bord, et dans l’intervalle de ce bord.
private func expectOnExpandedEdge(
  _ point: StarshipPoint,
  width: Double,
  height: Double,
  margin: Double
) {
  let onBottom = abs(point.y - (-margin)) < 1e-6 && point.x >= -1e-6 && point.x <= width + 1e-6
  let onRight = abs(point.x - (width + margin)) < 1e-6 && point.y >= -1e-6 && point.y <= height + 1e-6
  let onTop = abs(point.y - (height + margin)) < 1e-6 && point.x >= -1e-6 && point.x <= width + 1e-6
  let onLeft = abs(point.x - (-margin)) < 1e-6 && point.y >= -1e-6 && point.y <= height + 1e-6
  #expect(onBottom || onRight || onTop || onLeft)
}
