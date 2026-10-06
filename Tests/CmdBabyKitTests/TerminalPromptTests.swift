import Testing

@testable import CmdBabyKit

@Test("Taper un caractère l’ajoute devant le curseur")
func terminalPromptTypeAppendsCharacter() {
  var prompt = TerminalPrompt()
  let rain = prompt.type("b")
  #expect(rain == nil)
  #expect(prompt.text == "b")
  #expect(prompt.keysSinceLastColumn == 1)
}

@Test("Retour arrière retire le dernier caractère sans toucher le compteur")
func terminalPromptDeleteBackwardDropsLastCharacter() {
  var prompt = TerminalPrompt()
  _ = prompt.type("a")
  _ = prompt.type("b")
  prompt.deleteBackward()
  #expect(prompt.text == "a")
  #expect(prompt.keysSinceLastColumn == 2)
}

@Test("Retour arrière sur un prompt vide ne change rien")
func terminalPromptDeleteBackwardOnEmptyIsIgnored() {
  var prompt = TerminalPrompt()
  prompt.deleteBackward()
  #expect(prompt.text == "")
  #expect(prompt.keysSinceLastColumn == 0)
}

@Test("Le dixième caractère demande une colonne et remet le compteur à zéro")
func terminalPromptTenthCharacterRequestsColumn() {
  var prompt = TerminalPrompt()
  var rains: [TerminalRainRequest?] = []
  for _ in 0..<TerminalPrompt.keysPerColumn {
    rains.append(prompt.type("a"))
  }
  #expect(rains == Array(repeating: nil, count: 9) + [.column])
  #expect(prompt.keysSinceLastColumn == 0)
  #expect(prompt.text == String(repeating: "a", count: 10))
}

@Test("Le vingtième caractère demande une nouvelle colonne")
func terminalPromptTwentiethCharacterRequestsAnotherColumn() {
  var prompt = TerminalPrompt()
  for _ in 0..<10 {
    _ = prompt.type("a")
  }
  var secondCycle: [TerminalRainRequest?] = []
  for _ in 0..<10 {
    secondCycle.append(prompt.type("b"))
  }
  #expect(secondCycle == Array(repeating: nil, count: 9) + [.column])
  #expect(prompt.keysSinceLastColumn == 0)
  #expect(prompt.text == String(repeating: "a", count: 10) + String(repeating: "b", count: 10))
}

@Test("Entrée vide la ligne, remet le compteur à zéro et demande une vague")
func terminalPromptSubmitClearsLineAndRequestsWave() {
  var prompt = TerminalPrompt()
  _ = prompt.type("b")
  _ = prompt.type("o")
  _ = prompt.type("n")
  let rain = prompt.submit()
  #expect(rain == .wave)
  #expect(prompt.text == "")
  #expect(prompt.keysSinceLastColumn == 0)
}

@Test("Entrée sur un prompt vide demande quand même une vague")
func terminalPromptSubmitOnEmptyRequestsWave() {
  var prompt = TerminalPrompt()
  let rain = prompt.submit()
  #expect(rain == .wave)
  #expect(prompt.text == "")
  #expect(prompt.keysSinceLastColumn == 0)
}

@Test("Le 161ᵉ caractère retire le plus ancien")
func terminalPromptDropsOldestCharacterPastMaximum() {
  var prompt = TerminalPrompt()
  _ = prompt.type("x")
  for _ in 0..<TerminalPrompt.maxCharacters {
    _ = prompt.type("y")
  }
  #expect(prompt.text == String(repeating: "y", count: 160))
  #expect(prompt.text.count == TerminalPrompt.maxCharacters)
}
