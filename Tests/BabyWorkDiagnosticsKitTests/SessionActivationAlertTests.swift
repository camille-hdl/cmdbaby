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
