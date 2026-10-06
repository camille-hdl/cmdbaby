import Foundation
import Testing

@testable import CmdBabyKit

@Test("Un échec Accessibilité explique sans jargon et ouvre Permissions")
func accessibilityFailureAlertOpensPermissionsWithoutJargon() {
  let alert = SessionActivationAlert.forFailedActivation(
    .filterUnavailable("tap créé mais inactif"),
    table: .language("fr")
  )

  #expect(alert.title == "La session n’a pas pu démarrer")
  #expect(
    alert.informativeText
      == "CmdBaby a besoin de l’autorisation Accessibilité pour protéger le Mac pendant la session. Ouvrez Réglages › Permissions pour la vérifier."
  )
  #expect(alert.actions == [.openAppSettings(.permissions), .dismiss])
  expectNoTechnicalJargon(alert.title)
  expectNoTechnicalJargon(alert.informativeText)
  #expect(
    SessionActivationAlert.accessibilitySettingsURLCandidates == [
      "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
      "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
    ]
  )
}

@Test("Un échec Accessibilité dit la même chose en anglais")
func accessibilityFailureAlertSpeaksEnglish() {
  let alert = SessionActivationAlert.forFailedActivation(
    .filterUnavailable("tap inactive"),
    table: .language("en")
  )

  #expect(alert.title == "The session couldn't start")
  #expect(
    alert.informativeText
      == "CmdBaby needs the Accessibility permission to protect the Mac during a session. Open Settings › Permissions to check it."
  )
  #expect(alert.actions == [.openAppSettings(.permissions), .dismiss])
  #expect(alert.actions.map { $0.title(in: .language("en")) } == ["Settings…", "OK"])
  #expect(alert.actions.map { $0.title(in: .language("fr")) } == ["Réglages…", "OK"])
}

@Test("Une phrase intapable nomme les lettres absentes et propose les Réglages")
func passphraseNotTypableAlertNamesTheMissingLetters() {
  let alert = SessionActivationAlert.forFailedActivation(
    .passphraseNotTypable(["é", "ü"]),
    table: .language("fr")
  )

  #expect(alert.title == "La session n’a pas pu démarrer")
  #expect(
    alert.informativeText
      == "La phrase de sortie ne peut pas être tapée avec la disposition clavier active (lettres absentes : é ü). Changez de phrase ou activez Maj-Échap."
  )
  #expect(alert.actions == [.openAppSettings(.exits), .dismiss])
}

@Test("Un échec d’activation oriente vers Réglages, pas vers les outils parents")
func activationFailureAlertDoesNotPresentDiagnostics() {
  let alert = SessionActivationAlert.forFailedActivation(.noScreens, table: .language("fr"))

  #expect(alert.title == "La session n’a pas pu démarrer")
  #expect(alert.informativeText.contains("écran"))
  #expect(!alert.title.contains("Outils parents"))
  #expect(!alert.informativeText.contains("Outils parents"))
  #expect(!alert.informativeText.localizedCaseInsensitiveContains("défaillance"))
  #expect(alert.actions == [.openAppSettings(.mode), .dismiss])
}

@Test("Les autres échecs gardent leur sens et ouvrent le Mode de jeu")
func otherActivationFailuresOpenTheModeSection() {
  let frenchNoScreens = SessionActivationAlert.forFailedActivation(.noScreens, table: .language("fr"))
  let englishNoScreens = SessionActivationAlert.forFailedActivation(.noScreens, table: .language("en"))
  #expect(frenchNoScreens.informativeText == "Aucun écran n’est disponible pour la couverture.")
  #expect(englishNoScreens.informativeText == "No screen is available for the cover.")
  #expect(frenchNoScreens.actions == [.openAppSettings(.mode), .dismiss])
  #expect(englishNoScreens.actions == [.openAppSettings(.mode), .dismiss])
  expectNoTechnicalJargon(frenchNoScreens.informativeText)
  expectNoTechnicalJargon(englishNoScreens.informativeText)

  let frenchRejected = SessionActivationAlert.forFailedActivation(
    .presentationRejected,
    table: .language("fr")
  )
  let englishRejected = SessionActivationAlert.forFailedActivation(
    .presentationRejected,
    table: .language("en")
  )
  #expect(
    frenchRejected.informativeText
      == "Les options de présentation kiosque ont été refusées. Relancez l’application et réessayez."
  )
  #expect(
    englishRejected.informativeText
      == "The kiosk presentation options were refused. Relaunch the app and try again."
  )
  #expect(frenchRejected.actions == [.openAppSettings(.mode), .dismiss])
  #expect(englishRejected.actions == [.openAppSettings(.mode), .dismiss])

  let frenchInjected = SessionActivationAlert.forFailedActivation(
    .injectedFailure(.startInputFilter),
    table: .language("fr")
  )
  let englishInjected = SessionActivationAlert.forFailedActivation(
    .injectedFailure(.startInputFilter),
    table: .language("en")
  )
  #expect(
    frenchInjected.informativeText == "La session n’a pas pu démarrer. Réessayez depuis le menu."
  )
  #expect(englishInjected.informativeText == "The session couldn't start. Try again from the menu.")
  #expect(frenchInjected.actions == [.openAppSettings(.mode), .dismiss])
  #expect(englishInjected.actions == [.openAppSettings(.mode), .dismiss])
  #expect(!frenchInjected.informativeText.localizedCaseInsensitiveContains("défaillance"))
  #expect(!englishInjected.informativeText.localizedCaseInsensitiveContains("failure"))
}

@Test("L’échec Accessibilité journalise le motif et le chemin du binaire")
func accessibilityFailureLogRecordsTheTechnicalReasonAndBinaryPath() {
  let event = SessionActivationAlert.activationFailureLog(
    .filterUnavailable("tap créé mais inactif"),
    binaryPath: "/Applications/CmdBaby.app"
  )

  #expect(
    event.message
      == "session.activation.fail reason=tap créé mais inactif binary=/Applications/CmdBaby.app"
  )
  #expect(event.category == .session)
}

@Test("Le journal d’une phrase intapable ne contient ni la phrase ni ses lettres")
func passphraseFailureLogOmitsThePhrase() {
  let event = SessionActivationAlert.activationFailureLog(
    .passphraseNotTypable(["é", "ü"]),
    binaryPath: "/Applications/CmdBaby.app"
  )

  #expect(
    event.message
      == "session.activation.fail reason=passphraseNotTypable binary=/Applications/CmdBaby.app"
  )
}

private func expectNoTechnicalJargon(_ text: String, sourceLocation: SourceLocation = #_sourceLocation) {
  #expect(!text.localizedCaseInsensitiveContains("ad hoc"), sourceLocation: sourceLocation)
  #expect(!text.localizedCaseInsensitiveContains("TCC"), sourceLocation: sourceLocation)
  #expect(!text.localizedCaseInsensitiveContains("rebuild"), sourceLocation: sourceLocation)
  #expect(!text.contains("/"), sourceLocation: sourceLocation)
}
