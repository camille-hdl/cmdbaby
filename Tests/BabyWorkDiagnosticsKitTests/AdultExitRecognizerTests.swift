import Testing

@testable import BabyWorkDiagnosticsKit

/// Touches ЙЦУКЕН de « parent » : lettre cyrillique de la disposition, lettre latine ASCII.
private let russianAndLatinParentKeys: [Set<Character>] = [
  ["з", "p"],
  ["ф", "a"],
  ["к", "r"],
  ["у", "e"],
  ["т", "n"],
  ["е", "t"],
]

@Test("parent puis Entrée dans la fenêtre arrête la session")
func passphraseThenReturnWithinWindowExits() {
  let clock = ManualClock(now: 10)
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: clock)

  for character in Array("parent") {
    #expect(recognizer.handleKeyDown(letters: [character], isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == .passphrase)
}

@Test("Chaque touche cyrillique et latine reconnaît parent puis Entrée")
func cyrillicAndLatinLettersRecognizeParent() {
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: ManualClock(now: 0))
  for letters in russianAndLatinParentKeys {
    #expect(recognizer.handleKeyDown(letters: letters, isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == .passphrase)
}

@Test("Une frappe hors préfixe réinitialise le tampon")
func wrongLetterResetsPassphraseBuffer() {
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: ManualClock(now: 0))
  #expect(recognizer.handleKeyDown(letters: ["p"], isReturn: false) == nil)
  #expect(recognizer.handleKeyDown(letters: ["x"], isReturn: false) == nil)
  for character in Array("parent") {
    #expect(recognizer.handleKeyDown(letters: [character], isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == .passphrase)
}

@Test("Une touche dont aucune lettre n’est attendue vide le tampon")
func lettersOutsideTheExpectedOneClearTheBuffer() {
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: ManualClock(now: 0))
  #expect(recognizer.handleKeyDown(letters: ["з", "p"], isReturn: false) == nil)
  #expect(recognizer.prefixLength == 1)
  #expect(recognizer.handleKeyDown(letters: ["ы", "s"], isReturn: false) == nil)
  #expect(recognizer.prefixLength == 0)
  for letters in russianAndLatinParentKeys {
    #expect(recognizer.handleKeyDown(letters: letters, isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == .passphrase)
}

@Test("L’expiration de la fenêtre empêche la sortie")
func passphraseWindowExpirationPreventsExit() {
  let clock = ManualClock(now: 0)
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: clock)
  #expect(recognizer.handleKeyDown(letters: ["p"], isReturn: false) == nil)
  clock.now = 6
  #expect(recognizer.handleKeyDown(letters: ["a"], isReturn: false) == nil)
  for character in Array("rent") {
    #expect(recognizer.handleKeyDown(letters: [character], isReturn: false) == nil)
  }
  clock.now = 7
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == nil)
}

@Test("Majuscule-Échap produit la sortie de secours")
func shiftEscapeExitsImmediately() {
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: ManualClock(now: 0))
  #expect(
    recognizer.handleKeyDown(letters: [], isReturn: false, isEscape: true, shiftDown: true)
      == .shiftEscape
  )
}

@Test("Échap sans Majuscule n’est pas une sortie")
func escapeWithoutShiftIsNotAnExit() {
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: ManualClock(now: 0))
  #expect(
    recognizer.handleKeyDown(letters: [], isReturn: false, isEscape: true, shiftDown: false) == nil
  )
}

@Test("Commande-Q n’est pas une sortie adulte")
func commandQIsNotAnAdultExit() {
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: ManualClock())
  #expect(
    ShortcutSuppressionPolicy.decision(
      keyCode: MacVirtualKeyCode.ansiQ,
      modifiers: [.command],
      letter: "q"
    ) == .suppress(.commandQ)
  )
  #expect(recognizer.handleKeyDown(letters: ["q"], isReturn: false) == nil)
}

@Test("maman puis Entrée sort, parent puis Entrée ne sort pas")
func customPassphraseMatchesOnlyThatPhrase() throws {
  let recognizer = AdultExitRecognizer(
    settings: AdultExitSettings(passphrase: try ExitPassphrase.parse("maman")),
    clock: ManualClock(now: 0)
  )
  #expect(recognizer.prefixTarget == 5)

  for character in Array("parent") {
    #expect(recognizer.handleKeyDown(letters: [character], isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == nil)

  for character in Array("maman") {
    #expect(recognizer.handleKeyDown(letters: [character], isReturn: false) == nil)
  }
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == .passphrase)
}

@Test("Maj-Échap inactif ne sort pas")
func shiftEscapeWhenDisabledDoesNotExit() {
  let recognizer = AdultExitRecognizer(
    settings: AdultExitSettings(enabledMethods: [.passphrase, .failsafeClick]),
    clock: ManualClock(now: 0)
  )
  #expect(
    recognizer.handleKeyDown(letters: [], isReturn: false, isEscape: true, shiftDown: true) == nil
  )
}

@Test("Une phrase inactive ne se tamponne pas et Entrée ne sort pas")
func passphraseWhenDisabledDoesNotExit() {
  let recognizer = AdultExitRecognizer(
    settings: AdultExitSettings(enabledMethods: [.shiftEscape, .failsafeClick]),
    clock: ManualClock(now: 0)
  )
  for character in Array("parent") {
    #expect(recognizer.handleKeyDown(letters: [character], isReturn: false) == nil)
    #expect(recognizer.prefixLength == 0)
  }
  #expect(recognizer.handleKeyDown(letters: [], isReturn: true) == nil)
  #expect(recognizer.prefixTarget == 0)
}

@Test("Cinq clics en moins de trois secondes sortent")
func fiveFailsafeClicksWithinThreeSecondsExit() {
  let clock = ManualClock(now: 0)
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: clock)
  var exit: AdultExitKind?
  for step in 0..<5 {
    clock.now = Double(step) * 0.5
    exit = recognizer.handleFailsafeClick().exit
  }
  #expect(exit == .failsafeClick)
}

@Test("Quatre clics, une pause de plus de trois secondes, puis un clic ne sortent pas")
func failsafeClicksResetAfterThreeSeconds() {
  let clock = ManualClock(now: 0)
  let recognizer = AdultExitRecognizer(settings: AdultExitSettings(), clock: clock)
  for _ in 0..<4 {
    let result = recognizer.handleFailsafeClick()
    #expect(result.exit == nil)
  }
  clock.now = 3.1
  let last = recognizer.handleFailsafeClick()
  #expect(last.count == 1)
  #expect(last.exit == nil)
}

@Test("Des clics de secours inactifs ne comptent jamais")
func failsafeClicksWhenDisabledNeverCount() {
  let clock = ManualClock(now: 0)
  let recognizer = AdultExitRecognizer(
    settings: AdultExitSettings(enabledMethods: [.passphrase, .shiftEscape]),
    clock: clock
  )
  for step in 0..<6 {
    clock.now = Double(step) * 0.4
    let result = recognizer.handleFailsafeClick()
    #expect(result.count == 0)
    #expect(result.exit == nil)
  }
}
