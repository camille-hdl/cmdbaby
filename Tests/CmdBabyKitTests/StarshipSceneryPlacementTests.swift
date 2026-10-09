import Foundation
import Testing

@testable import CmdBabyKit

@Test("Un écran déplacé rejoue le décor en vol au bon endroit, avec le même beginTime")
func movedScreenReplaysFlyingSceneryWithoutMovingTheOthers() {
  let asteroid = sceneryElement(id: 7, x: 400)
  let planet = sceneryElement(id: 8, x: 100)
  let parked = TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 600)
  let neighbour = TerminalScreen(index: 1, x: 800, y: 0, width: 800, height: 600)
  let moved = TerminalScreen(index: 0, x: 150, y: 200, width: 800, height: 600)
  let begin = 42.5

  var here = StarshipSceneryPlacement()
  var there = StarshipSceneryPlacement()
  let placedAsteroid = here.install(asteroid, on: parked, mediaBeginTime: begin)
  let placedPlanet = here.install(planet, on: parked, mediaBeginTime: begin)
  let placedNextDoor = there.install(asteroid, on: neighbour, mediaBeginTime: begin)

  #expect(placedAsteroid.droppedIDs.isEmpty)
  #expect(placedAsteroid.flight == flight(id: 7, fromX: 400, fromY: 620, toX: 400, toY: -20, begin: begin))
  #expect(placedPlanet.flight == flight(id: 8, fromX: 100, fromY: 620, toX: 100, toY: -20, begin: begin))
  #expect(placedNextDoor.flight == flight(id: 7, fromX: -400, fromY: 620, toX: -400, toY: -20, begin: begin))

  // L’animation posée sur l’ancien cadre. Après le déplacement, la garder laisse l’astéroïde 200 pt trop haut.
  let stale = asteroid.localPoint(at: asteroid.start, on: parked)
  #expect(stale == StarshipPoint(x: 400, y: 620))

  let again = here.install(asteroid, on: parked, mediaBeginTime: begin)
  #expect(again.flight == nil)
  #expect(again.droppedIDs.isEmpty)

  let replayed = here.install(asteroid, on: moved, mediaBeginTime: begin)
  #expect(replayed.droppedIDs == Set([7, 8]))
  #expect(replayed.flight == flight(id: 7, fromX: 250, fromY: 420, toX: 250, toY: -220, begin: begin))

  let planetAgain = here.install(planet, on: moved, mediaBeginTime: begin)
  #expect(planetAgain.droppedIDs.isEmpty)
  #expect(planetAgain.flight == flight(id: 8, fromX: -50, fromY: 420, toX: -50, toY: -220, begin: begin))

  let neighbourAgain = there.install(asteroid, on: neighbour, mediaBeginTime: begin)
  #expect(neighbourAgain.flight == nil)
  #expect(neighbourAgain.droppedIDs.isEmpty)

  let stacked = here.install(asteroid, on: moved, mediaBeginTime: begin)
  #expect(stacked.flight == nil)
  #expect(stacked.droppedIDs.isEmpty)
}

@Test("Un écran seulement redimensionné rejoue son décor, sans décaler les autres")
func resizedScreenReplaysFlyingSceneryWithoutMovingTheOthers() {
  let asteroid = sceneryElement(id: 7, x: 400)
  let planet = sceneryElement(id: 8, x: 100)
  let parked = TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 600)
  let neighbour = TerminalScreen(index: 1, x: 800, y: 0, width: 800, height: 600)
  let resized = TerminalScreen(index: 0, x: 0, y: 0, width: 1_024, height: 768)
  let begin = 42.5

  var here = StarshipSceneryPlacement()
  var there = StarshipSceneryPlacement()
  _ = here.install(asteroid, on: parked, mediaBeginTime: begin)
  _ = here.install(planet, on: parked, mediaBeginTime: begin)
  _ = there.install(asteroid, on: neighbour, mediaBeginTime: begin)

  let replayed = here.install(asteroid, on: resized, mediaBeginTime: begin)
  #expect(replayed.droppedIDs == Set([7, 8]))
  #expect(replayed.flight == flight(id: 7, fromX: 400, fromY: 620, toX: 400, toY: -20, begin: begin))

  let planetAgain = here.install(planet, on: resized, mediaBeginTime: begin)
  #expect(planetAgain.droppedIDs.isEmpty)
  #expect(planetAgain.flight == flight(id: 8, fromX: 100, fromY: 620, toX: 100, toY: -20, begin: begin))

  let neighbourAgain = there.install(asteroid, on: neighbour, mediaBeginTime: begin)
  #expect(neighbourAgain.flight == nil)
  #expect(neighbourAgain.droppedIDs.isEmpty)
}

@Test("Un élément sorti peut être reposé sans retirer ceux qui restent")
func forgottenElementCanBePlacedAgain() {
  let asteroid = sceneryElement(id: 7, x: 400)
  let planet = sceneryElement(id: 8, x: 100)
  let parked = TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 600)
  let begin = 42.5

  var here = StarshipSceneryPlacement()
  _ = here.install(asteroid, on: parked, mediaBeginTime: begin)
  _ = here.install(planet, on: parked, mediaBeginTime: begin)

  here.forget(7)

  let again = here.install(asteroid, on: parked, mediaBeginTime: begin)
  #expect(again.droppedIDs.isEmpty)
  #expect(again.flight == flight(id: 7, fromX: 400, fromY: 620, toX: 400, toY: -20, begin: begin))

  let planetStill = here.install(planet, on: parked, mediaBeginTime: begin)
  #expect(planetStill.flight == nil)
  #expect(planetStill.droppedIDs.isEmpty)
}

@Test("La remise à zéro oublie le décor, même si l’écran a bougé")
func resetForgetsPlacedScenery() {
  let asteroid = sceneryElement(id: 7, x: 400)
  let planet = sceneryElement(id: 8, x: 100)
  let parked = TerminalScreen(index: 0, x: 0, y: 0, width: 800, height: 600)
  let moved = TerminalScreen(index: 0, x: 150, y: 200, width: 800, height: 600)
  let begin = 42.5

  var here = StarshipSceneryPlacement()
  _ = here.install(asteroid, on: parked, mediaBeginTime: begin)
  _ = here.install(planet, on: parked, mediaBeginTime: begin)

  here.reset()

  let again = here.install(asteroid, on: moved, mediaBeginTime: begin)
  #expect(again.droppedIDs.isEmpty)
  #expect(again.flight == flight(id: 7, fromX: 250, fromY: 420, toX: 250, toY: -220, begin: begin))
}

private func sceneryElement(id: Int, x: Double) -> StarshipSceneryElement {
  StarshipSceneryElement(
    id: id,
    layer: .farAsteroid,
    sprite: "asteroid",
    x: x,
    startY: 620,
    endY: -20,
    size: 40,
    width: 40,
    opacity: 0.4,
    start: 0,
    duration: 12.8
  )
}

private func flight(
  id: Int,
  fromX: Double,
  fromY: Double,
  toX: Double,
  toY: Double,
  begin: TimeInterval
) -> StarshipSceneryPlacement.Flight {
  StarshipSceneryPlacement.Flight(
    elementID: id,
    from: StarshipPoint(x: fromX, y: fromY),
    to: StarshipPoint(x: toX, y: toY),
    mediaBeginTime: begin
  )
}
