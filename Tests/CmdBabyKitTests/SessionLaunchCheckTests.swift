import Testing

@testable import CmdBabyKit

@Test("Seule la phrase, intapable, bloque le lancement")
func onlyUntypablePassphraseBlocksLaunch() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.passphrase]),
    typability: PassphraseTypability(missingLetters: ["é"]),
    secureInputActive: false
  )

  #expect(decision == .blocked(.passphraseNotTypable(["é"])))
}

@Test("La phrase et Maj-Échap, même intapable, autorisent le lancement")
func passphraseAndShiftEscapeAllowLaunchWhenUntypable() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.passphrase, .shiftEscape]),
    typability: PassphraseTypability(missingLetters: ["é"]),
    secureInputActive: false
  )

  #expect(decision == .allowed)
}

@Test("Seule la phrase, tapable, autorise le lancement")
func onlyTypablePassphraseAllowsLaunch() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.passphrase]),
    typability: PassphraseTypability(missingLetters: []),
    secureInputActive: false
  )

  #expect(decision == .allowed)
}

@Test("Une phrase désactivée autorise le lancement même si elle est intapable")
func disabledPassphraseAllowsLaunchWhenUntypable() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.shiftEscape, .failsafeClick]),
    typability: PassphraseTypability(missingLetters: ["é"]),
    secureInputActive: false
  )

  #expect(decision == .allowed)
}

@Test("Une autre app qui protège la saisie bloque le lancement")
func secureInputBlocksLaunch() {
  let decision = SessionLaunchCheck.evaluate(
    exits: AdultExitSettings(enabledMethods: [.passphrase, .shiftEscape]),
    typability: PassphraseTypability(missingLetters: []),
    secureInputActive: true
  )

  #expect(decision == .blocked(.secureInputActive))
}
