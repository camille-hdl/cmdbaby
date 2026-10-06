import Testing

@testable import CmdBabyKit

@Test("La première cellule sort au premier pas")
func terminalRainColumnEmitsFirstCellOnFirstStep() {
  var column = makeColumn(topY: 280, floorY: 0, stepInterval: 0.05)
  #expect(column.advance(by: 0.04) == [])
  #expect(column.advance(by: 0.01) == [252])
  #expect(column.emittedCells == 1)
  #expect(column.elapsed == 0.05)
}

@Test("n pas émettent n cellules")
func terminalRainColumnEmitsOneCellPerStep() {
  var column = makeColumn(topY: 280, floorY: 0, stepInterval: 0.05)
  var bottoms: [Double] = []
  for _ in 0..<4 {
    bottoms.append(contentsOf: column.advance(by: 0.05))
  }
  #expect(bottoms == [252, 224, 196, 168])
  #expect(column.emittedCells == 4)
}

@Test("Un dt de trois pas émet trois cellules aux bons y")
func terminalRainColumnLargeStepEmitsEveryCell() {
  var column = makeColumn(topY: 280, floorY: 0, stepInterval: 0.05)
  #expect(column.advance(by: 0.15) == [252, 224, 196])
  #expect(column.emittedCells == 3)
}

@Test("La colonne s’arrête avant floorY et isFinished passe à true")
func terminalRainColumnStopsBeforeFloor() {
  var column = makeColumn(topY: 100, floorY: 50, stepInterval: 0.05)
  #expect(column.isFinished == false)
  #expect(column.advance(by: 1) == [72])
  #expect(column.isFinished)

  var touching = makeColumn(topY: 56, floorY: 28, stepInterval: 0.05)
  #expect(touching.advance(by: 1) == [28])
  #expect(touching.isFinished)
}

@Test("Aucune cellule ne sort deux fois")
func terminalRainColumnDoesNotEmitACellTwice() {
  var column = makeColumn(topY: 280, floorY: 200, stepInterval: 0.05)
  #expect(column.advance(by: 1) == [252, 224])
  #expect(column.advance(by: 1) == [])
  #expect(column.isFinished)
  #expect(column.emittedCells == 2)
}

private func makeColumn(topY: Double, floorY: Double, stepInterval: Double) -> TerminalRainColumn {
  TerminalRainColumn(
    x: 17,
    topY: topY,
    floorY: floorY,
    stepInterval: stepInterval,
    trailLifetime: 1.5
  )
}
