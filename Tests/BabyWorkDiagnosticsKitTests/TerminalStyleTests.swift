import Testing

@testable import BabyWorkDiagnosticsKit

@Test("TerminalStyle reprend la palette Matrix, la lueur et les polices du prompt")
func terminalStyleMatchesMatrixPalette() {
  #expect(matches(TerminalStyle.background, hex: 0x0D0208))
  #expect(matches(TerminalStyle.trail, hex: 0x00FF41))
  #expect(matches(TerminalStyle.trailEnd, hex: 0x008F11))
  #expect(matches(TerminalStyle.head, hex: 0xD7FFD9))
  #expect(matches(TerminalStyle.prompt, hex: 0x00FF41))
  #expect(TerminalStyle.promptFontNames == ["Courier-Bold", "CourierNewPS-BoldMT", "Menlo-Bold"])
  #expect(TerminalStyle.promptFontSize == 64)
  #expect(TerminalStyle.glowBlur == 6)
  #expect(TerminalStyle.headGlowBlur == 10)
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
