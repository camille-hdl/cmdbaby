import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Un échec Accessibilité produit une alerte avec un chemin vers Réglages système")
func accessibilityFailureAlertOpensSystemSettings() {
  let alert = SessionActivationAlert.forFailedActivation(
    .filterUnavailable("Accessibilité refusée")
  )

  #expect(alert.title == "La session n’a pas pu démarrer")
  #expect(alert.informativeText.contains("Accessibilité refusée"))
  #expect(alert.informativeText.contains("Accordez Accessibilité"))
  #expect(alert.informativeText.contains("relance"))
  #expect(alert.actions == [
    .openAccessibilitySettings,
    .openAppSettings,
    .dismiss,
  ])
  #expect(SessionActivationAlert.Action.openAccessibilitySettings.title == "Ouvrir Accessibilité")
  #expect(SessionActivationAlert.Action.openAppSettings.title == "Réglages…")
  #expect(
    SessionActivationAlert.accessibilitySettingsURLCandidates == [
      "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
      "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
    ]
  )
}

@Test("Un échec Accessibilité identifie le binaire courant et guide le re-grant TCC")
func accessibilityFailureAlertIdentifiesRunningBinaryAndGuidesTCCRegrant() {
  let binary = URL(fileURLWithPath: "/Applications/BabyWorks.app")
  let alert = SessionActivationAlert.forFailedActivation(
    .filterUnavailable("Accessibilité manquante"),
    runningBinaryURL: binary
  )

  #expect(alert.informativeText.contains("/Applications/BabyWorks.app"))
  #expect(alert.informativeText.contains("Retirez les anciennes entrées"))
  #expect(alert.informativeText.contains("cette copie"))
  #expect(alert.informativeText.contains("ad hoc"))
  #expect(alert.informativeText.contains("rebuild"))
  #expect(alert.actions.contains(.openAccessibilitySettings))
}

@Test("Un échec d’activation oriente vers Réglages, pas vers les outils parents")
func activationFailureAlertDoesNotPresentDiagnostics() {
  let alert = SessionActivationAlert.forFailedActivation(.noScreens)

  #expect(alert.title == "La session n’a pas pu démarrer")
  #expect(alert.informativeText.contains("écran"))
  #expect(!alert.title.contains("Outils parents"))
  #expect(!alert.informativeText.contains("Outils parents"))
  #expect(!alert.informativeText.localizedCaseInsensitiveContains("défaillance"))
  #expect(alert.actions == [.openAppSettings, .dismiss])
}
