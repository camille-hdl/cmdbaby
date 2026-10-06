import Testing

@testable import CmdBabyKit

@Test("Tout va bien : rien à faire")
func healthySessionNeedsNothing() {
  #expect(
    SessionGuard.evaluate(tapEnabled: true, accessibilityTrusted: true, secureInputActive: false, appActive: true)
      == []
  )
}

@Test("Tap coupé, Accessibilité accordée : le réactiver")
func disabledTapWithAccessibilityIsReenabled() {
  #expect(
    SessionGuard.evaluate(tapEnabled: false, accessibilityTrusted: true, secureInputActive: false, appActive: true)
      == [.reenableTap]
  )
}

@Test("Tap coupé, Accessibilité révoquée : prévenir l’adulte, sans réactiver")
func revokedAccessibilityWarnsTheParent() {
  #expect(
    SessionGuard.evaluate(tapEnabled: false, accessibilityTrusted: false, secureInputActive: false, appActive: true)
      == [.warnParent(.accessibilityLost)]
  )
}

@Test("Saisie protégée par une autre app : prévenir l’adulte")
func secureInputWarnsTheParent() {
  #expect(
    SessionGuard.evaluate(tapEnabled: true, accessibilityTrusted: true, secureInputActive: true, appActive: true)
      == [.warnParent(.secureInput)]
  )
}

@Test("App inactive : reprendre le focus")
func inactiveAppRefocusesCovers() {
  #expect(
    SessionGuard.evaluate(tapEnabled: true, accessibilityTrusted: true, secureInputActive: false, appActive: false)
      == [.refocusCovers]
  )
}

@Test("Tout à la fois : réactiver, reprendre le focus, puis prévenir")
func everythingWrongKeepsTheOrder() {
  #expect(
    SessionGuard.evaluate(tapEnabled: false, accessibilityTrusted: false, secureInputActive: true, appActive: false)
      == [.refocusCovers, .warnParent(.accessibilityLost), .warnParent(.secureInput)]
  )
  #expect(
    SessionGuard.evaluate(tapEnabled: false, accessibilityTrusted: true, secureInputActive: true, appActive: false)
      == [.reenableTap, .refocusCovers, .warnParent(.secureInput)]
  )
}

@Test("Les événements du chien de garde ne contiennent aucune frappe")
func guardEventsAreLogged() {
  #expect(LifecycleLogEvent.guardTapLost.message == "guard.tapLost")
  #expect(LifecycleLogEvent.guardSecureInput.message == "guard.secureInput")
  #expect(LifecycleLogEvent.guardRefocus.message == "guard.refocus")
  #expect(LifecycleLogEvent.guardTapLost.category == .session)
}

@Test("Le bandeau et le refus au lancement sont traduits")
func guardStringsAreTranslated() {
  #expect(
    L10nTable.language("fr")("session.guard.warning")
      == "Protection du clavier interrompue — utilisez une sortie adulte"
  )
  #expect(
    L10nTable.language("en")("session.guard.warning")
      == "Keyboard protection interrupted — use an adult exit"
  )
  #expect(
    SessionActivationAlert.forFailedActivation(.secureInputActive, table: .language("fr")).informativeText
      == "Une autre app protège la saisie (mot de passe, Terminal…). Fermez-la ou quittez son champ, puis relancez."
  )
  #expect(
    SessionActivationAlert.forFailedActivation(.secureInputActive, table: .language("en")).informativeText
      == "Another app is protecting keyboard input (password, Terminal…). Close it or leave its field, then try again."
  )
}
