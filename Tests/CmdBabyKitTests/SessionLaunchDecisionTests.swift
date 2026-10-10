import Foundation
import Testing

@testable import CmdBabyKit

@Test("Au repos, un contrôle autorisé décide de lancer", arguments: [
  KioskSessionPhase.configuration,
  KioskSessionPhase.failed,
])
func restingPhaseLaunchesWhenTheCheckAllows(_ phase: KioskSessionPhase) {
  let decision = SessionLaunchDecision.evaluate(
    request: SessionLaunchRequest(origin: .menu),
    phase: phase,
    check: .allowed,
    linkLaunchAllowed: true
  )

  #expect(decision == .launch)
}

@Test(
  "Une phase occupée répond déjà en cours, même si le contrôle bloquerait",
  arguments: [
    KioskSessionPhase.preparing,
    KioskSessionPhase.activating,
    KioskSessionPhase.active,
    KioskSessionPhase.stopping,
  ]
)
func busyPhaseIsAlreadyInProgress(_ phase: KioskSessionPhase) {
  let allowed = SessionLaunchDecision.evaluate(
    request: SessionLaunchRequest(origin: .shortcuts),
    phase: phase,
    check: .allowed,
    linkLaunchAllowed: true
  )
  let blockedBySecureInput = SessionLaunchDecision.evaluate(
    request: SessionLaunchRequest(origin: .shortcuts),
    phase: phase,
    check: .blocked(.secureInputActive),
    linkLaunchAllowed: true
  )
  let blockedByPassphrase = SessionLaunchDecision.evaluate(
    request: SessionLaunchRequest(origin: .link),
    phase: phase,
    check: .blocked(.passphraseNotTypable(["é"])),
    linkLaunchAllowed: true
  )

  #expect(allowed == .alreadyInProgress)
  #expect(blockedBySecureInput == .alreadyInProgress)
  #expect(blockedByPassphrase == .alreadyInProgress)
}

@Test("Au repos, chaque motif de refus du contrôle est le motif renvoyé", arguments: [
  (KioskSessionPhase.configuration, KioskSessionError.secureInputActive),
  (.configuration, .passphraseNotTypable(["é"])),
  (.failed, .secureInputActive),
  (.failed, .passphraseNotTypable(["é"])),
])
func restingPhaseRefusesEachCheckReason(
  _ phase: KioskSessionPhase,
  _ error: KioskSessionError
) {
  let decision = SessionLaunchDecision.evaluate(
    request: SessionLaunchRequest(origin: .settings),
    phase: phase,
    check: .blocked(error),
    linkLaunchAllowed: true
  )

  #expect(decision == .refused(error))
}

@Test("La réponse dit session lancée, ou déjà en cours, en français et en anglais")
func launchReplySpeaksFrenchAndEnglish() {
  #expect(SessionLaunchDecision.launch.message(in: .language("fr")) == "Session lancée")
  #expect(SessionLaunchDecision.launch.message(in: .language("en")) == "Session started")
  #expect(
    SessionLaunchDecision.alreadyInProgress.message(in: .language("fr"))
      == "Une session est déjà en cours"
  )
  #expect(
    SessionLaunchDecision.alreadyInProgress.message(in: .language("en"))
      == "A session is already in progress"
  )
  #expect(
    SessionLaunchDecision.invalidParameter.message(in: .language("fr"))
      == "La durée doit être comprise entre 1 et 120 minutes."
  )
  #expect(
    SessionLaunchDecision.invalidParameter.message(in: .language("en"))
      == "The duration must be between 1 and 120 minutes."
  )
}

@Test("Un refus explique le motif, en français et en anglais")
func refusalReplyExplainsTheReasonInFrenchAndEnglish() {
  let secureInput = SessionLaunchDecision.refused(.secureInputActive)
  #expect(
    secureInput.message(in: .language("fr"))
      == "Une autre app protège la saisie (mot de passe, Terminal…). Fermez-la ou quittez son champ, puis relancez."
  )
  #expect(
    secureInput.message(in: .language("en"))
      == "Another app is protecting keyboard input (password, Terminal…). Close it or leave its field, then try again."
  )

  let passphrase = SessionLaunchDecision.refused(.passphraseNotTypable(["é", "ü"]))
  #expect(
    passphrase.message(in: .language("fr"))
      == "La phrase de sortie ne peut pas être tapée avec la disposition clavier active. Changez de phrase ou activez Maj-Échap."
  )
  #expect(
    passphrase.message(in: .language("en"))
      == "The exit phrase can't be typed with the active keyboard layout. Change the phrase or turn on Shift-Escape."
  )
  #expect(!passphrase.message(in: .language("fr")).contains("ü"))
  #expect(!passphrase.message(in: .language("en")).contains("ü"))
  #expect(!passphrase.message(in: .language("fr")).contains("lettres absentes"))
  #expect(!passphrase.message(in: .language("en")).contains("missing letters"))

  let accessibility = SessionLaunchDecision.refused(.filterUnavailable("tap créé mais inactif"))
  #expect(
    accessibility.message(in: .language("fr"))
      == "CmdBaby a besoin de l’autorisation Accessibilité pour protéger le Mac pendant la session. Ouvrez Réglages › Permissions pour la vérifier."
  )
  #expect(
    accessibility.message(in: .language("en"))
      == "CmdBaby needs the Accessibility permission to protect the Mac during a session. Open Settings › Permissions to check it."
  )
  #expect(!accessibility.message(in: .language("fr")).contains("tap créé"))

  let noScreens = SessionLaunchDecision.refused(.noScreens)
  #expect(
    noScreens.message(in: .language("fr")) == "Aucun écran n’est disponible pour la couverture."
  )
  #expect(noScreens.message(in: .language("en")) == "No screen is available for the cover.")
}

@Test("Un lien non autorisé, même mal formé, est refusé avant l’erreur de format")
func unauthorizedMalformedLinkIsRefusedBeforeTheFormatError() {
  let malformed = URL(string: "cmdbaby://session/stop")!

  #expect(
    SessionLaunchDecision.reply(to: malformed, phase: .configuration, linkLaunchAllowed: false)
      == .notAllowed
  )
  #expect(
    SessionLaunchDecision.reply(to: malformed, phase: .failed, linkLaunchAllowed: false)
      == .notAllowed
  )
  #expect(
    SessionLaunchDecision.reply(to: malformed, phase: .active, linkLaunchAllowed: false)
      == .ignored
  )
  #expect(
    SessionLaunchDecision.reply(
      to: URL(string: "cmdbaby://session/start")!,
      phase: .configuration,
      linkLaunchAllowed: true
    ) == .proceed(SessionLaunchRequest(origin: .link))
  )
  #expect(
    SessionLaunchDecision.reply(to: malformed, phase: .configuration, linkLaunchAllowed: true)
      == .invalid(.unknownPath)
  )
}

@Test("Un lien non autorisé est refusé ; autorisé, il lance avec les surcharges")
func unauthorizedLinkIsRefusedAndAnAuthorizedLinkLaunchesWithOverrides() throws {
  let request = SessionLaunchRequest(origin: .link, mode: .starship, durationMinutes: 10)
  let saved = CmdBabyConfiguration(
    mode: .ocean,
    launchAtLogin: true,
    exits: AdultExitSettings(timeLimitMinutes: 45)
  )

  #expect(
    SessionLaunchDecision.evaluate(
      request: request,
      phase: .configuration,
      check: .allowed,
      linkLaunchAllowed: false
    ) == .linkNotAllowed
  )
  #expect(
    SessionLaunchDecision.evaluate(
      request: request,
      phase: .active,
      check: .allowed,
      linkLaunchAllowed: false
    ) == .alreadyInProgress
  )
  #expect(
    SessionLaunchDecision.evaluate(
      request: SessionLaunchRequest(origin: .shortcuts, mode: .starship, durationMinutes: 10),
      phase: .configuration,
      check: .allowed,
      linkLaunchAllowed: false
    ) == .launch
  )

  #expect(
    SessionLaunchDecision.evaluate(
      request: request,
      phase: .configuration,
      check: .allowed,
      linkLaunchAllowed: true
    ) == .launch
  )
  let effective = try #require(readyConfiguration(request.effectiveConfiguration(from: saved)))
  #expect(effective.mode == .starship)
  #expect(effective.exits.timeLimitMinutes == 10)
  #expect(effective.launchAtLogin == true)
  #expect(saved.linkLaunchAllowed == false)
}

private func readyConfiguration(
  _ result: SessionLaunchConfiguration
) -> CmdBabyConfiguration? {
  if case .ready(let configuration) = result { return configuration }
  return nil
}
