import Testing

@testable import CmdBabyKit

@Test("Le rayon vers une cible étire le sprite, sans calque de la hauteur du tir")
func beamStretchesTheSpriteInsteadOfAScreenTallLayer() {
  let placement = StarshipBeam.placement(
    from: StarshipPoint(x: 120, y: 80),
    to: StarshipPoint(x: 120, y: 940)
  )

  #expect(abs(StarshipBeam.spriteWidth - 14) < 1e-6)
  #expect(abs(StarshipBeam.spriteHeight - 86) < 1e-6)
  #expect(abs(placement.origin.x - 120) < 1e-6)
  #expect(abs(placement.origin.y - 80) < 1e-6)
  #expect(abs(placement.length - 860) < 1e-6)
  #expect(abs(placement.scaleY - 10) < 1e-6)
  #expect(abs(placement.angle - 0) < 1e-6)
}

@Test("Le rayon part du vaisseau et aboutit sur l’ennemi, vers le haut, le bas et les côtés")
func beamReachesTheEnemyInEveryDirection() {
  let up = StarshipBeam.placement(
    from: StarshipPoint(x: 200, y: 160),
    to: StarshipPoint(x: 200, y: 720)
  )
  expectBeam(up, originX: 200, originY: 160, endX: 200, endY: 720, angle: 0)

  let down = StarshipBeam.placement(
    from: StarshipPoint(x: 200, y: 640),
    to: StarshipPoint(x: 200, y: 80)
  )
  expectBeam(down, originX: 200, originY: 640, endX: 200, endY: 80, angle: -.pi)

  let right = StarshipBeam.placement(
    from: StarshipPoint(x: 180, y: 240),
    to: StarshipPoint(x: 860, y: 240)
  )
  expectBeam(right, originX: 180, originY: 240, endX: 860, endY: 240, angle: -.pi / 2)

  let diagonal = StarshipBeam.placement(
    from: StarshipPoint(x: 700, y: 500),
    to: StarshipPoint(x: 140, y: 120)
  )
  expectBeam(
    diagonal,
    originX: 700,
    originY: 500,
    endX: 140,
    endY: 120,
    angle: -4.1161898391
  )
}

private func expectBeam(
  _ placement: StarshipBeam.Placement,
  originX: Double,
  originY: Double,
  endX: Double,
  endY: Double,
  angle: Double
) {
  #expect(abs(placement.origin.x - originX) < 1e-6)
  #expect(abs(placement.origin.y - originY) < 1e-6)
  #expect(abs(placement.end.x - endX) < 1e-6)
  #expect(abs(placement.end.y - endY) < 1e-6)
  #expect(abs(placement.angle - angle) < 1e-6)
}
