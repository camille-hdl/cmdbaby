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

@Test("Depuis le status item, pas d’activation regular tant que le menu track")
func showingSettingsFromStatusItemWaitsForMenuBeforeActivation() {
  let sequence = SettingsShowSequence(fromStatusItemMenu: true)
  #expect(sequence.shouldWaitForMenuTracking)
  #expect(!sequence.shouldApplyVisibleActivationPolicy)
  #expect(!sequence.shouldOrderFront)
}

@Test("Après la fin du tracking menu, activation regular puis orderFront")
func endingMenuTrackingAppliesActivationThenOrdersFront() {
  var sequence = SettingsShowSequence(fromStatusItemMenu: true)
  sequence.menuTrackingDidEnd()
  #expect(!sequence.shouldWaitForMenuTracking)
  #expect(sequence.shouldApplyVisibleActivationPolicy)
  #expect(sequence.shouldOrderFront)
  #expect(!sequence.orderFrontIsRetry)
}

@Test("Hors menu status, activation regular et orderFront tout de suite")
func showingSettingsOutsideStatusItemAppliesActivationImmediately() {
  let sequence = SettingsShowSequence(fromStatusItemMenu: false)
  #expect(!sequence.shouldWaitForMenuTracking)
  #expect(sequence.shouldApplyVisibleActivationPolicy)
  #expect(sequence.shouldOrderFront)
}

@Test("Premier orderFront pas key : un retry")
func failedFirstOrderFrontSchedulesRetry() {
  var sequence = SettingsShowSequence(fromStatusItemMenu: true)
  sequence.menuTrackingDidEnd()
  let event = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
  #expect(
    event
      == .settingsOrderFront(
        isVisible: true,
        isKeyWindow: false,
        outcome: .fail,
        retry: false
      )
  )
  #expect(sequence.shouldOrderFront)
  #expect(sequence.orderFrontIsRetry)
  #expect(sequence.shouldApplyVisibleActivationPolicy)
}

@Test("OrderFront key : succès journalisé, terminé")
func successfulOrderFrontFinishesWithSuccess() {
  var sequence = SettingsShowSequence(fromStatusItemMenu: false)
  let event = sequence.recordOrderFront(isVisible: true, isKeyWindow: true)
  #expect(
    event
      == .settingsOrderFront(
        isVisible: true,
        isKeyWindow: true,
        outcome: .success,
        retry: false
      )
  )
  #expect(!sequence.shouldOrderFront)
  #expect(sequence.finishedOutcome == .success)
}

@Test("Retry toujours pas key : échec journalisé, terminé")
func failedRetryFinishesWithFail() {
  var sequence = SettingsShowSequence(fromStatusItemMenu: true)
  sequence.menuTrackingDidEnd()
  _ = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
  let event = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
  #expect(
    event
      == .settingsOrderFront(
        isVisible: true,
        isKeyWindow: false,
        outcome: .fail,
        retry: true
      )
  )
  #expect(!sequence.shouldOrderFront)
  #expect(sequence.finishedOutcome == .fail)
}

@Test("Retry devenu key : succès journalisé retry=true")
func successfulRetryFinishesWithSuccess() {
  var sequence = SettingsShowSequence(fromStatusItemMenu: true)
  sequence.menuTrackingDidEnd()
  _ = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
  let event = sequence.recordOrderFront(isVisible: true, isKeyWindow: true)
  #expect(
    event
      == .settingsOrderFront(
        isVisible: true,
        isKeyWindow: true,
        outcome: .success,
        retry: true
      )
  )
  #expect(sequence.finishedOutcome == .success)
}
