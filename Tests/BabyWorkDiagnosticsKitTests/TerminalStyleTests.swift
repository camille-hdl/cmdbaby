import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Le style Terminal expose le fond, la traîne, la traîne finale, la tête et le prompt")
func terminalStyleExposesPaletteFromSpec() {
  #expect(TerminalStyle.background == TerminalStyle.RGB(red: 13.0 / 255.0, green: 2.0 / 255.0, blue: 8.0 / 255.0))
  #expect(TerminalStyle.trail == TerminalStyle.RGB(red: 0, green: 1, blue: 65.0 / 255.0))
  #expect(TerminalStyle.fadingTrail == TerminalStyle.RGB(red: 0, green: 143.0 / 255.0, blue: 17.0 / 255.0))
  #expect(TerminalStyle.head == TerminalStyle.RGB(red: 215.0 / 255.0, green: 1, blue: 217.0 / 255.0))
  #expect(TerminalStyle.prompt == TerminalStyle.RGB(red: 0, green: 1, blue: 65.0 / 255.0))
}

@Test("Le style Terminal liste Courier, Courier New, puis Menlo pour le prompt")
func terminalStylePromptFontsAreCourierThenMenlo() {
  #expect(TerminalStyle.promptFontNames == ["Courier-Bold", "CourierNewPS-BoldMT", "Menlo-Bold"])
  #expect(TerminalStyle.promptFontSize == 64)
  #expect(TerminalStyle.glowBlur == 6)
  #expect(TerminalStyle.headGlowBlur == 10)
}
