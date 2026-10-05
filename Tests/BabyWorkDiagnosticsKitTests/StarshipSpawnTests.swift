import Testing

@testable import BabyWorkDiagnosticsKit

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
