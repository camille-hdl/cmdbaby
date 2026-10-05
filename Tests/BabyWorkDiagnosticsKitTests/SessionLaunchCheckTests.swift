import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Seule la phrase, intapable, bloque le lancement")
func onlyUntypablePassphraseBlocksLaunch() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.passphrase]),
    typability: PassphraseTypability(missingLetters: ["é"])
  )

  #expect(decision == .blocked(missingLetters: ["é"]))
}

@Test("La phrase et Maj-Échap, même intapable, autorisent le lancement")
func passphraseAndShiftEscapeAllowLaunchWhenUntypable() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.passphrase, .shiftEscape]),
    typability: PassphraseTypability(missingLetters: ["é"])
  )

  #expect(decision == .allowed)
}

@Test("Seule la phrase, tapable, autorise le lancement")
func onlyTypablePassphraseAllowsLaunch() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.passphrase]),
    typability: PassphraseTypability(missingLetters: [])
  )

  #expect(decision == .allowed)
}

@Test("Une phrase désactivée autorise le lancement même si elle est intapable")
func disabledPassphraseAllowsLaunchWhenUntypable() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.shiftEscape, .failsafeClick]),
    typability: PassphraseTypability(missingLetters: ["é"])
  )

  #expect(decision == .allowed)
}
