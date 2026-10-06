import Testing

@testable import CmdBabyKit

@Test("Le logo suit l’apparence : Nuit en sombre, Jour sinon")
func appLogoFollowsAppearance() {
  #expect(AppLogoVariant.for(colorSchemeIsDark: true) == .nuit)
  #expect(AppLogoVariant.for(colorSchemeIsDark: false) == .jour)
  #expect(AppLogoVariant.jour.resourceName == "AppLogo-jour")
  #expect(AppLogoVariant.nuit.resourceName == "AppLogo-nuit")
}

@Test("L’en-tête d’À propos se lit « nom, version … »")
func aboutHeaderAccessibilityLabel() {
  #expect(
    L10nTable.language("fr")("settings.about.header.accessibility", "CmdBaby", "0.1.0 (1)")
      == "CmdBaby, version 0.1.0 (1)"
  )
  #expect(
    L10nTable.language("en")("settings.about.header.accessibility", "CmdBaby", "0.1.0 (1)")
      == "CmdBaby, version 0.1.0 (1)"
  )
}
