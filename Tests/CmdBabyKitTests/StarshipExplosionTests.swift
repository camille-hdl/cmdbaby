import Testing

@testable import CmdBabyKit

@Test("L’explosion grossit le glyphe déjà à l’écran, sans en dessiner un autre")
func explosionPopsTheGlyphAlreadyOnScreen() {
  let pop = StarshipExplosion.glyphPop
  #expect(abs(pop.scaleFrom - 1) < 1e-6)
  #expect(abs(pop.scaleTo - 1.6) < 1e-6)
}

@Test("L’explosion laisse la lettre sur l’ennemi, sans la faire partir du bord")
func explosionKeepsTheLetterOnTheEnemy() {
  // Cible 110 × 96, lettre au centre (55, 48). Dans la scène elle est sur l’ennemi,
  // pas au point local qui la ferait partir du bord.
  let onEnemy = StarshipExplosion.glyphScenePosition(
    targetAt: StarshipPoint(x: 640, y: 420),
    glyphAtLocal: StarshipPoint(x: 55, y: 48),
    targetWidth: 110,
    targetHeight: 96
  )
  #expect(abs(onEnemy.x - 640) < 1e-6)
  #expect(abs(onEnemy.y - 420) < 1e-6)

  // Décalée de 10 pt à droite du centre : elle reste 10 pt à droite de l’ennemi.
  let offset = StarshipExplosion.glyphScenePosition(
    targetAt: StarshipPoint(x: 640, y: 420),
    glyphAtLocal: StarshipPoint(x: 65, y: 48),
    targetWidth: 110,
    targetHeight: 96
  )
  #expect(abs(offset.x - 650) < 1e-6)
  #expect(abs(offset.y - 420) < 1e-6)
}
