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
  #expect(abs(placement.scaleY - 10) < 1e-6)
  #expect(abs(placement.angle - 0) < 1e-6)
}

@Test("Le rayon se tourne depuis le haut et s’étire d’un sprite par 86 pt, dans chaque direction")
func beamReachesTheEnemyInEveryDirection() {
  // 860 pt, soit dix sprites de 86. 0 = vers le haut.
  let up = StarshipBeam.placement(
    from: StarshipPoint(x: 200, y: 160),
    to: StarshipPoint(x: 200, y: 1020)
  )
  expectBeam(up, angle: 0, scaleY: 10)

  let down = StarshipBeam.placement(
    from: StarshipPoint(x: 200, y: 900),
    to: StarshipPoint(x: 200, y: 40)
  )
  expectBeam(down, angle: -.pi, scaleY: 10)

  let right = StarshipBeam.placement(
    from: StarshipPoint(x: 180, y: 240),
    to: StarshipPoint(x: 1040, y: 240)
  )
  expectBeam(right, angle: -.pi / 2, scaleY: 10)

  let left = StarshipBeam.placement(
    from: StarshipPoint(x: 1040, y: 240),
    to: StarshipPoint(x: 180, y: 240)
  )
  expectBeam(left, angle: .pi / 2, scaleY: 10)

  // 45° en haut à droite, un sprite sur chaque axe.
  // L’hypoténuse vaut 86√2, donc l’échelle est √2.
  // Depuis le haut, un huitième de tour vers la droite : −π/4.
  let diagonal = StarshipBeam.placement(
    from: StarshipPoint(x: 0, y: 0),
    to: StarshipPoint(x: 86, y: 86)
  )
  expectBeam(diagonal, angle: -.pi / 4, scaleY: 2.0.squareRoot())
}

private func expectBeam(
  _ placement: StarshipBeam.Placement,
  angle: Double,
  scaleY: Double
) {
  #expect(abs(placement.angle - angle) < 1e-9)
  #expect(abs(placement.scaleY - scaleY) < 1e-9)
}
