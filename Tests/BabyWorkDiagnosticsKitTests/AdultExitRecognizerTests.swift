import Testing

@testable import BabyWorkDiagnosticsKit

@Test("parent puis Entrée dans la fenêtre arrête la session")
func passphraseThenReturnWithinWindowExits() {
  let clock = ManualClock(now: 10)
  let recognizer = AdultExitRecognizer(clock: clock)

  for character in Array("parent") {
    #expect(recognizer.handleKeyDown(letter: character, isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letter: nil, isReturn: true) == .passphrase)
}

@Test("Une frappe hors préfixe réinitialise le tampon")
func wrongLetterResetsPassphraseBuffer() {
  let recognizer = AdultExitRecognizer(clock: ManualClock(now: 0))
  #expect(recognizer.handleKeyDown(letter: "p", isReturn: false) == nil)
  #expect(recognizer.handleKeyDown(letter: "x", isReturn: false) == nil)
  for character in Array("parent") {
    #expect(recognizer.handleKeyDown(letter: character, isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letter: nil, isReturn: true) == .passphrase)
}

@Test("L’expiration de la fenêtre empêche la sortie")
func passphraseWindowExpirationPreventsExit() {
  let clock = ManualClock(now: 0)
  let recognizer = AdultExitRecognizer(clock: clock)
  #expect(recognizer.handleKeyDown(letter: "p", isReturn: false) == nil)
  clock.now = 6
  #expect(recognizer.handleKeyDown(letter: "a", isReturn: false) == nil)
  for character in Array("rent") {
    #expect(recognizer.handleKeyDown(letter: character, isReturn: false) == nil)
  }
  clock.now = 7
  #expect(recognizer.handleKeyDown(letter: nil, isReturn: true) == nil)
}

@Test("Majuscule-Échap produit la sortie de secours")
func shiftEscapeExitsImmediately() {
  let recognizer = AdultExitRecognizer(clock: ManualClock(now: 0))
  #expect(
    recognizer.handleKeyDown(letter: nil, isReturn: false, isEscape: true, shiftDown: true)
      == .shiftEscape
  )
}

@Test("Échap sans Majuscule n’est pas une sortie")
func escapeWithoutShiftIsNotAnExit() {
  let recognizer = AdultExitRecognizer(clock: ManualClock(now: 0))
  #expect(
    recognizer.handleKeyDown(letter: nil, isReturn: false, isEscape: true, shiftDown: false) == nil
  )
}

@Test("Commande-Q n’est pas une sortie adulte")
func commandQIsNotAnAdultExit() {
  let recognizer = AdultExitRecognizer(clock: ManualClock())
  #expect(
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.ansiQ,
      modifiers: [.command],
      letter: "q"
    ) == .suppress(.commandQ)
  )
  #expect(recognizer.handleKeyDown(letter: "q", isReturn: false) == nil)
}
