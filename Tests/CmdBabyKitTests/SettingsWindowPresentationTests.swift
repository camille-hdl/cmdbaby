import Testing

@testable import CmdBabyKit

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
        retry: 0
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
        retry: 0
      )
  )
  #expect(!sequence.shouldOrderFront)
  #expect(sequence.finishedOutcome == .success)
}

@Test("Deuxième orderFront pas key : encore un retry")
func secondFailedOrderFrontStillRetries() {
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
        retry: 1
      )
  )
  #expect(sequence.shouldOrderFront)
  #expect(sequence.orderFrontIsRetry)
  #expect(sequence.finishedOutcome == nil)
}

@Test("Après 5 retries toujours pas key : échec journalisé, terminé")
func exhaustedRetriesFinishWithFail() {
  var sequence = SettingsShowSequence(fromStatusItemMenu: true)
  sequence.menuTrackingDidEnd()
  for _ in 1...5 {
    _ = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
    #expect(sequence.shouldOrderFront)
  }
  let event = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
  #expect(
    event
      == .settingsOrderFront(
        isVisible: true,
        isKeyWindow: false,
        outcome: .fail,
        retry: 5
      )
  )
  #expect(!sequence.shouldOrderFront)
  #expect(sequence.finishedOutcome == .fail)
}

@Test("Retry devenu key : succès journalisé retry=N")
func successfulRetryFinishesWithSuccess() {
  var sequence = SettingsShowSequence(fromStatusItemMenu: true)
  sequence.menuTrackingDidEnd()
  _ = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
  _ = sequence.recordOrderFront(isVisible: true, isKeyWindow: false)
  let event = sequence.recordOrderFront(isVisible: true, isKeyWindow: true)
  #expect(
    event
      == .settingsOrderFront(
        isVisible: true,
        isKeyWindow: true,
        outcome: .success,
        retry: 2
      )
  )
  #expect(sequence.finishedOutcome == .success)
}

@Test("Le délai de retry reste dans 50–100 ms")
func orderFrontRetryDelayIsBounded() {
  #expect(SettingsWindowPresentation.orderFrontRetryDelay >= 0.05)
  #expect(SettingsWindowPresentation.orderFrontRetryDelay <= 0.1)
}
