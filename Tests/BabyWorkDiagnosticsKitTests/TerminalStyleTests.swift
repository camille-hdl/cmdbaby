import Testing

@testable import BabyWorkDiagnosticsKit

@Test("TerminalStyle reprend la palette Matrix, la lueur et les polices du prompt")
func terminalStyleMatchesMatrixPalette() {
  #expect(matches(TerminalStyle.background, hex: 0x0D0208))
  #expect(matches(TerminalStyle.trail, hex: 0x00FF41))
  #expect(matches(TerminalStyle.trailEnd, hex: 0x008F11))
  #expect(matches(TerminalStyle.head, hex: 0xD7FFD9))
  #expect(matches(TerminalStyle.headGlow, hex: 0xA8FFB0))
  #expect(matches(TerminalStyle.prompt, hex: 0x00FF41))
  #expect(TerminalStyle.promptFontNames == ["Courier-Bold", "CourierNewPS-BoldMT", "Menlo-Bold"])
  #expect(TerminalStyle.promptFontSize == 64)
  #expect(TerminalStyle.glowBlur == 6)
  #expect(TerminalStyle.headGlowBlur == 10)
  #expect(TerminalStyle.cellHeight == 28)
  #expect(TerminalStyle.cellWidth == 17)
}

@Test("TerminalStyle fixe l’effet CRT : balayage, vignettage et coins")
func terminalStyleDefinesCRTEffect() {
  #expect(TerminalStyle.crtEffectEnabled == true)
  #expect(TerminalStyle.scanlinePeriodPixels == 3)
  #expect(TerminalStyle.scanlineOpacity == 0.15)
  #expect(TerminalStyle.vignetteEdgeOpacity == 0.35)
  #expect(TerminalStyle.vignetteInnerRadius == 0.6)
  #expect(TerminalStyle.crtCornerRadius == 48)
}

@Test("snapToGrid aligne un x positif ou négatif sur le bord gauche de la cellule")
func terminalStyleSnapsXToGlobalGrid() {
  #expect(TerminalStyle.snapToGrid(x: 0) == 0)
  #expect(TerminalStyle.snapToGrid(x: 16.9) == 0)
  #expect(TerminalStyle.snapToGrid(x: 17) == 17)
  #expect(TerminalStyle.snapToGrid(x: 34) == 34)
  #expect(TerminalStyle.snapToGrid(x: -0.1) == -17)
  #expect(TerminalStyle.snapToGrid(x: -17) == -17)
  #expect(TerminalStyle.snapToGrid(x: -17.1) == -34)
}

private func matches(_ color: TerminalStyle.SRGB, hex: UInt32) -> Bool {
  let expected = srgb(hex)
  return color.red == expected.red && color.green == expected.green && color.blue == expected.blue
}

/// Conversion indépendante des constantes : `#RRGGBB` → composantes sRGB.
private func srgb(_ hex: UInt32) -> (red: Double, green: Double, blue: Double) {
  (
    red: Double((hex >> 16) & 0xFF) / 255,
    green: Double((hex >> 8) & 0xFF) / 255,
    blue: Double(hex & 0xFF) / 255
  )
}
