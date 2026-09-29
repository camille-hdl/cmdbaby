import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Réglages visibles : l’app n’est plus un agent accessory")
func settingsWindowUsesRegularActivationWhileVisible() {
  #expect(SettingsWindowPresentation.visibleActivationPolicy == .regular)
}

@Test("Fermer Réglages sans autre UI parent : retour idle sans Dock")
func hidingSettingsWithoutOtherParentUIRestoresIdleActivation() {
  #expect(
    SettingsWindowPresentation.activationPolicyAfterHiding(otherParentUIVisible: false)
      == MenuBarAgent.activationPolicy
  )
  #expect(MenuBarAgent.activationPolicy == .accessory)
}

@Test("Fermer Réglages avec une autre UI parent ouverte : rester regular")
func hidingSettingsWithOtherParentUIKeepsRegularActivation() {
  #expect(
    SettingsWindowPresentation.activationPolicyAfterHiding(otherParentUIVisible: true)
      == .regular
  )
}

@Test("Depuis le status item, l’ordre front attend la fermeture du menu")
func showingSettingsFromStatusItemDefersOrderingFront() {
  #expect(
    SettingsWindowPresentation.orderFrontTiming(fromStatusItemMenu: true)
      == .afterStatusItemMenuDismisses
  )
}

@Test("Hors menu status, Réglages s’ordonne tout de suite")
func showingSettingsOutsideStatusItemOrdersFrontImmediately() {
  #expect(
    SettingsWindowPresentation.orderFrontTiming(fromStatusItemMenu: false) == .immediate
  )
}
