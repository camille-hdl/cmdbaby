import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Accessibilité accordée : une vérification ok, sans action, rien à corriger")
func grantedAccessibilityNeedsNothing() throws {
  let checklist = SetupChecklist(facts: SetupFacts(accessibilityGranted: true))

  #expect(checklist.needsAttention == false)
  let check = try #require(checklist.checks.first)
  #expect(checklist.checks.count == 1)
  #expect(check.id == .accessibility)
  #expect(check.state == .ok)
  #expect(check.actions.isEmpty)
}

@Test("Accessibilité refusée : attention, demander l’accès et ouvrir Réglages Système")
func deniedAccessibilityNeedsBothActions() throws {
  let checklist = SetupChecklist(facts: SetupFacts(accessibilityGranted: false))

  #expect(checklist.needsAttention == true)
  let check = try #require(checklist.checks.first)
  #expect(checklist.checks.count == 1)
  #expect(check.id == .accessibility)
  #expect(check.state == .attention)
  #expect(check.actions == [.requestAccessibility, .openAccessibilitySettings])
}

@Test("Chaque titre et détail de la liste existe en français et en anglais")
func checklistKeysExistInBothLanguages() {
  let lists = [
    SetupChecklist(facts: SetupFacts(accessibilityGranted: true)),
    SetupChecklist(facts: SetupFacts(accessibilityGranted: false)),
  ]
  for checklist in lists {
    for check in checklist.checks {
      for code in ["fr", "en"] {
        let table = L10nTable.language(code)
        #expect(table(check.titleKey) != check.titleKey)
        #expect(table(check.detailKey) != check.detailKey)
      }
    }
  }
}
