import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("L’angle d’un clic est l’angle vers ce point, ou rien si le clic est sur le vaisseau")
func starshipAimAnglePointsAtTheClickOrNilWhenTooClose() {
  let origin = StarshipPoint(x: 0, y: 0)
  let right = StarshipAim.angle(from: origin, to: StarshipPoint(x: 1, y: 0))
  let up = StarshipAim.angle(from: origin, to: StarshipPoint(x: 0, y: 1))
  let left = StarshipAim.angle(from: origin, to: StarshipPoint(x: -1, y: 0))
  let onShip = StarshipAim.angle(from: origin, to: StarshipPoint(x: 0.5, y: 0.5))

  #expect(right != nil && abs(right! - 0) < 1e-6)
  #expect(up != nil && abs(up! - Double.pi / 2) < 1e-6)
  #expect(left != nil && abs(left! - Double.pi) < 1e-6)
  #expect(onShip == nil)
}

@Test("Un tir partant du centre sort par le bord que vise l’angle")
func starshipAimRayFromCenterExitsTheFacingEdge() {
  let origin = StarshipPoint(x: 720, y: 450)
  let width = 1440.0
  let height = 900.0

  expectPoint(
    StarshipAim.rayExit(from: origin, angle: 0, width: width, height: height),
    1440, 450
  )
  expectPoint(
    StarshipAim.rayExit(from: origin, angle: .pi / 2, width: width, height: height),
    720, 900
  )
  expectPoint(
    StarshipAim.rayExit(from: origin, angle: .pi, width: width, height: height),
    0, 450
  )
  expectPoint(
    StarshipAim.rayExit(from: origin, angle: -.pi / 2, width: width, height: height),
    720, 0
  )
  expectPoint(
    StarshipAim.rayExit(from: origin, angle: .pi / 4, width: width, height: height),
    1170, 900
  )
  expectPoint(
    StarshipAim.rayExit(from: origin, angle: atan2(450, 720), width: width, height: height),
    1440, 900
  )
}

@Test("Un tir partant d’un point décentré sort par le bord visé, à la même hauteur")
func starshipAimRayFromOffCenterExitsTheFacingEdge() {
  let exit = StarshipAim.rayExit(
    from: StarshipPoint(x: 100, y: 100),
    angle: .pi,
    width: 1440,
    height: 900
  )
  expectPoint(exit, 0, 100)
}

@Test("La rotation vise l’angle équivalent le plus proche, sans faire un tour presque complet")
func starshipAimNearestEquivalentTakesTheShortWay() {
  let fullTurn = 2 * Double.pi
  expectAngle(StarshipAim.nearestEquivalent(of: 3 * .pi / 2, to: 0), -.pi / 2)
  expectAngle(StarshipAim.nearestEquivalent(of: 0, to: 2 * fullTurn), 2 * fullTurn)
  let degree = Double.pi / 180
  expectAngle(
    StarshipAim.nearestEquivalent(of: 10 * degree, to: 350 * degree),
    370 * degree
  )
  expectAngle(StarshipAim.nearestEquivalent(of: 1, to: 1), 1)
}

private func expectAngle(_ angle: Double, _ expected: Double) {
  #expect(abs(angle - expected) < 1e-6)
}

private func expectPoint(_ point: StarshipPoint, _ x: Double, _ y: Double) {
  #expect(abs(point.x - x) < 1e-6)
  #expect(abs(point.y - y) < 1e-6)
}
