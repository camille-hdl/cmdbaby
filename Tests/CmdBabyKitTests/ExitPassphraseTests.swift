import Testing

@testable import CmdBabyKit

@Test("« Maman » entourée d’espaces devient maman")
func passphraseTrimsAndLowercases() throws {
  let passphrase = try ExitPassphrase.parse("  Maman ")
  #expect(passphrase.value == "maman")
}

@Test("« Éléphant » et une saisie décomposée deviennent éléphant en NFC")
func passphraseLowercasesAndComposesAccents() throws {
  let composed = try ExitPassphrase.parse("Éléphant")
  let decomposed = try ExitPassphrase.parse("E\u{301}le\u{301}phant")
  #expect(composed.value == "éléphant")
  #expect(decomposed.value == "éléphant")
}
