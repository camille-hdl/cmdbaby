import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Accessibilité accordée : une vérification ok, sans action, rien à corriger")
func grantedAccessibilityNeedsNothing() throws {
  let checklist = SetupChecklist(facts: facts(accessibilityGranted: true))

  #expect(checklist.needsAttention == false)
  let check = try #require(checklist.checks.first { $0.id == .accessibility })
  #expect(check.state == .ok)
  #expect(check.actions.isEmpty)
}

@Test("Accessibilité refusée : attention, demander l’accès et ouvrir Réglages Système")
func deniedAccessibilityNeedsBothActions() throws {
  let checklist = SetupChecklist(facts: facts(accessibilityGranted: false))

  #expect(checklist.needsAttention == true)
  let check = try #require(checklist.checks.first { $0.id == .accessibility })
  #expect(check.state == .attention)
  #expect(check.actions == [.requestAccessibility, .openAccessibilitySettings])
}

@Test("L’app dans /Applications ou dans Applications du dossier personnel : emplacement ok")
func applicationInApplicationsFolderIsOk() throws {
  let home = "/Users/ada"
  for bundlePath in [
    "/Applications/BabyWorks.app",
    "/Users/ada/Applications/BabyWorks.app",
  ] {
    let checklist = SetupChecklist(
      facts: facts(accessibilityGranted: true, bundlePath: bundlePath, homeDirectory: home)
    )
    let check = try #require(checklist.checks.first { $0.id == .location })
    #expect(check.state == .ok)
    #expect(check.actions.isEmpty)
    #expect(checklist.needsAttention == false)
  }
}

@Test("L’app dans Téléchargements ou transloquée : emplacement à corriger, affichée dans le Finder")
func applicationOutsideApplicationsNeedsRevealInFinder() throws {
  let home = "/Users/ada"
  let paths = [
    "/Users/ada/Downloads/BabyWorks.app",
    "/private/var/folders/ab/cd/T/AppTranslocation/E1E1E1E1-E1E1-E1E1-E1E1-E1E1E1E1E1E1/d/BabyWorks.app",
  ]
  for bundlePath in paths {
    let checklist = SetupChecklist(
      facts: facts(accessibilityGranted: true, bundlePath: bundlePath, homeDirectory: home)
    )
    #expect(checklist.needsAttention == true)
    let check = try #require(checklist.checks.first { $0.id == .location })
    #expect(check.state == .attention)
    #expect(check.actions == [.revealInFinder])
    #expect(
      L10nTable.language("fr")(check.detailKey)
        == "Déplacez BabyWorks dans le dossier Applications, puis rouvrez-la depuis là. L’autorisation Accessibilité est liée à cet emplacement."
    )
  }
}

@Test("Démarrage automatique non demandé : pas de vérification")
func launchAtLoginNotRequestedOmitsTheCheck() {
  let checklist = SetupChecklist(
    facts: facts(
      accessibilityGranted: true,
      launchAtLoginRequested: false,
      loginItemStatus: .requiresApproval
    )
  )
  #expect(checklist.checks.map(\.id) == [.accessibility, .location])
}

@Test("Démarrage automatique demandé et en attente d’accord : attention, ouvrir Ouverture")
func launchAtLoginRequiresApprovalOpensLoginItemsSettings() throws {
  let checklist = SetupChecklist(
    facts: facts(
      accessibilityGranted: true,
      launchAtLoginRequested: true,
      loginItemStatus: .requiresApproval
    )
  )
  #expect(checklist.checks.map(\.id) == [.accessibility, .location, .launchAtLogin])
  #expect(checklist.needsAttention == true)
  let check = try #require(checklist.checks.first { $0.id == .launchAtLogin })
  #expect(check.state == .attention)
  #expect(check.actions == [.openLoginItemsSettings])
  #expect(
    L10nTable.language("fr")(check.detailKey)
      == "macOS attend votre accord pour ouvrir BabyWorks à la connexion."
  )
}

@Test("Démarrage automatique demandé et actif : ok, sans action")
func launchAtLoginEnabledIsOk() throws {
  let checklist = SetupChecklist(
    facts: facts(
      accessibilityGranted: true,
      launchAtLoginRequested: true,
      loginItemStatus: .enabled
    )
  )
  #expect(checklist.checks.map(\.id) == [.accessibility, .location, .launchAtLogin])
  #expect(checklist.needsAttention == false)
  let check = try #require(checklist.checks.first { $0.id == .launchAtLogin })
  #expect(check.state == .ok)
  #expect(check.actions.isEmpty)
}

@Test("Démarrage automatique demandé mais introuvable ou non enregistré : attention, sans action")
func launchAtLoginMissingNeedsAttentionWithoutAction() throws {
  for status in [LoginItemStatus.notFound, .notRegistered] {
    let checklist = SetupChecklist(
      facts: facts(
        accessibilityGranted: true,
        launchAtLoginRequested: true,
        loginItemStatus: status
      )
    )
    #expect(checklist.needsAttention == true)
    let check = try #require(checklist.checks.first { $0.id == .launchAtLogin })
    #expect(check.state == .attention)
    #expect(check.actions.isEmpty)
    #expect(
      L10nTable.language("fr")(check.detailKey)
        == "Le démarrage automatique n’a pas pu être enregistré. Désactivez-le puis réactivez-le dans Général."
    )
  }
}

@Test("Chaque titre et détail de la liste existe en français et en anglais")
func checklistKeysExistInBothLanguages() {
  let lists = [
    SetupChecklist(facts: facts(accessibilityGranted: true)),
    SetupChecklist(facts: facts(accessibilityGranted: false, bundlePath: "/Users/ada/Downloads/BabyWorks.app")),
    SetupChecklist(
      facts: facts(accessibilityGranted: true, launchAtLoginRequested: true, loginItemStatus: .enabled)
    ),
    SetupChecklist(
      facts: facts(
        accessibilityGranted: true,
        launchAtLoginRequested: true,
        loginItemStatus: .requiresApproval
      )
    ),
    SetupChecklist(
      facts: facts(accessibilityGranted: true, launchAtLoginRequested: true, loginItemStatus: .notFound)
    ),
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

/// App dans /Applications, démarrage automatique non demandé : seules Accessibilité et l’emplacement varient.
private func facts(
  accessibilityGranted: Bool,
  bundlePath: String = "/Applications/BabyWorks.app",
  homeDirectory: String = "/Users/ada",
  launchAtLoginRequested: Bool = false,
  loginItemStatus: LoginItemStatus = .notRegistered
) -> SetupFacts {
  SetupFacts(
    accessibilityGranted: accessibilityGranted,
    bundlePath: bundlePath,
    homeDirectory: homeDirectory,
    launchAtLoginRequested: launchAtLoginRequested,
    loginItemStatus: loginItemStatus
  )
}
