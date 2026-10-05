import Testing

@testable import BabyWorkDiagnosticsKit

@Test("« été » se tape sur une disposition qui a e, t et é")
func eteIsTypableWhenTheLayoutHasThoseLetters() throws {
  let phrase = try ExitPassphrase.parse("été")
  let azerty: [UInt16: Set<Character>] = [
    0: ["e"],
    1: ["t"],
    2: ["é"],
  ]

  let typability = PassphraseTypability.check(phrase, layoutLetters: azerty)

  #expect(typability.isTypable)
}

@Test("« été » sur une disposition U.S. manque é")
func eteOnUsLayoutIsMissingEAcute() throws {
  let phrase = try ExitPassphrase.parse("été")
  let us: [UInt16: Set<Character>] = [
    0: ["e"],
    1: ["t"],
    2: ["a"],
  ]

  let typability = PassphraseTypability.check(phrase, layoutLetters: us)

  #expect(typability.missingLetters == ["é"])
  #expect(!typability.isTypable)
}

@Test("« parent » sur une disposition russe manque p a r e n t")
func parentOnRussianLayoutIsMissingEveryLetter() throws {
  let phrase = try ExitPassphrase.parse("parent")
  let russian: [UInt16: Set<Character>] = [
    0: ["й"],
    1: ["ц"],
    2: ["у"],
  ]

  let typability = PassphraseTypability.check(phrase, layoutLetters: russian)

  #expect(typability.missingLetters == ["p", "a", "r", "e", "n", "t"])
  #expect(!typability.isTypable)
}

@Test("Une table vide ne permet de taper aucune phrase")
func emptyLayoutIsNotTypable() throws {
  let phrase = try ExitPassphrase.parse("parent")

  let typability = PassphraseTypability.check(phrase, layoutLetters: [:])

  #expect(typability.missingLetters == ["p", "a", "r", "e", "n", "t"])
  #expect(!typability.isTypable)
}

@Test("« papa » sur une disposition russe manque p puis a, une seule fois")
func duplicateLettersStayInPhraseOrderWithoutRepeating() throws {
  let phrase = try ExitPassphrase.parse("papa")
  let russian: [UInt16: Set<Character>] = [
    0: ["й"],
    1: ["ц"],
    2: ["у"],
  ]

  let typability = PassphraseTypability.check(phrase, layoutLetters: russian)

  #expect(typability.missingLetters == ["p", "a"])
}

@Test("Une lettre majuscule ou décomposée de la disposition compte comme sa minuscule NFC")
func layoutLettersMatchThePhraseInLowercaseNFC() throws {
  let phrase = try ExitPassphrase.parse("été")
  let decomposedAcute = try #require("e\u{0301}".first)
  let layout: [UInt16: Set<Character>] = [
    0: ["E"],
    1: ["T"],
    2: [decomposedAcute],
  ]

  let typability = PassphraseTypability.check(phrase, layoutLetters: layout)

  #expect(typability.isTypable)
}
