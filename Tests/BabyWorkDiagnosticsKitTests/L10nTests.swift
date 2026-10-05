import Foundation
import Testing

@testable import BabyWorkDiagnosticsKit

@Test("Réglages… en français, Settings… en anglais")
func settingsMenuTitleMatchesLanguage() {
  #expect(L10nTable.language("fr")("menu.settings") == "Réglages…")
  #expect(L10nTable.language("en")("menu.settings") == "Settings…")
}

@Test("Disposition clavier : aide si la phrase se tape, lettres manquantes sinon")
func keyboardLayoutExitCopy() {
  #expect(L10nTable.language("fr")("settings.exits.layout.label") == "Disposition clavier")
  #expect(L10nTable.language("en")("settings.exits.layout.label") == "Keyboard Layout")
  #expect(L10nTable.language("fr")("settings.exits.layout.ok") == "La phrase se tape avec cette disposition.")
  #expect(L10nTable.language("en")("settings.exits.layout.ok") == "The phrase is typed with this layout.")
  #expect(
    L10nTable.language("fr")("settings.exits.layout.missing", "p a")
      == "Lettres absentes de cette disposition : p a. Choisissez une autre phrase ou gardez Maj-Échap activé."
  )
  #expect(
    L10nTable.language("en")("settings.exits.layout.missing", "p a")
      == "Letters missing from this layout: p a. Choose another phrase or keep Shift-Escape on."
  )
}

@Test("Lancer un mode : Start en anglais, Lancer en français")
func launchModeButtonCopy() {
  #expect(L10nTable.language("en")("settings.mode.launch") == "Start")
  #expect(L10nTable.language("fr")("settings.mode.launch") == "Lancer")
  #expect(L10nTable.language("en")("settings.mode.launch.accessibility", "Ocean") == "Start Ocean")
  #expect(L10nTable.language("fr")("settings.mode.launch.accessibility", "Océan") == "Lancer Océan")
}

@Test("À propos : titres, Made by, repli du nom, version absente, crédit d’un pack")
func aboutSectionCopy() {
  #expect(L10nTable.language("fr")("settings.about.title") == "À propos")
  #expect(L10nTable.language("en")("settings.about.title") == "About")
  #expect(L10nTable.language("fr")("settings.about.subtitle") == "BabyWorks et ce qui le rend possible.")
  #expect(L10nTable.language("en")("settings.about.subtitle") == "BabyWorks and what makes it possible.")
  #expect(L10nTable.language("fr")("settings.about.assets") == "Images")
  #expect(L10nTable.language("en")("settings.about.assets") == "Artwork")
  #expect(L10nTable.language("fr")("settings.about.madeBy") == "Made by")
  #expect(L10nTable.language("en")("settings.about.madeBy") == "Made by")
  #expect(L10nTable.language("fr")("settings.about.name.fallback") == "BabyWorks")
  #expect(L10nTable.language("en")("settings.about.name.fallback") == "BabyWorks")
  #expect(L10nTable.language("fr")("settings.about.version.missing") == "—")
  #expect(L10nTable.language("en")("settings.about.version.missing") == "—")
  #expect(L10nTable.language("fr")("settings.about.asset.credit", "Kenney", "CC0") == "Kenney · CC0")
  #expect(L10nTable.language("en")("settings.about.asset.credit", "Kenney", "CC0") == "Kenney · CC0")
}

@Test("Langue : Système, English, Français, et la relance")
func languagePreferenceCopy() {
  #expect(L10nTable.language("fr")("settings.general.language.label") == "Langue")
  #expect(L10nTable.language("en")("settings.general.language.label") == "Language")
  #expect(L10nTable.language("fr")("settings.general.language.system") == "Système")
  #expect(L10nTable.language("en")("settings.general.language.system") == "System")
  #expect(L10nTable.language("fr")("settings.general.language.english") == "English")
  #expect(L10nTable.language("en")("settings.general.language.english") == "English")
  #expect(L10nTable.language("fr")("settings.general.language.french") == "Français")
  #expect(L10nTable.language("en")("settings.general.language.french") == "Français")
  #expect(
    L10nTable.language("fr")("settings.general.language.relaunch.help")
      == "Relancer BabyWorks pour appliquer"
  )
  #expect(
    L10nTable.language("en")("settings.general.language.relaunch.help")
      == "Relaunch BabyWorks to apply"
  )
  #expect(L10nTable.language("fr")("settings.general.language.relaunch.action") == "Relancer maintenant")
  #expect(L10nTable.language("en")("settings.general.language.relaunch.action") == "Relaunch Now")
}

@Test("Permissions : Accessibilité accordée, à corriger, et les deux boutons")
func permissionsAccessibilityCopy() {
  #expect(L10nTable.language("fr")("settings.permissions.title") == "Permissions")
  #expect(L10nTable.language("en")("settings.permissions.title") == "Permissions")
  #expect(
    L10nTable.language("fr")("settings.permissions.subtitle")
      == "Si une session peut démarrer, et comment corriger sinon."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.subtitle")
      == "Whether a session can start, and how to fix it if not."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.sidebar.attention") == "Permissions, à corriger"
  )
  #expect(
    L10nTable.language("en")("settings.permissions.sidebar.attention") == "Permissions, needs attention"
  )
  #expect(L10nTable.language("fr")("settings.permissions.accessibility.title") == "Accessibilité")
  #expect(L10nTable.language("en")("settings.permissions.accessibility.title") == "Accessibility")
  #expect(
    L10nTable.language("fr")("settings.permissions.accessibility.ok")
      == "BabyWorks peut filtrer les raccourcis pendant une session."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.accessibility.ok")
      == "BabyWorks can filter shortcuts during a session."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.accessibility.attention")
      == "Cochez BabyWorks dans Réglages Système › Confidentialité et sécurité › Accessibilité. Si BabyWorks y est déjà cochée, retirez-la avec « – », puis ajoutez-la de nouveau : l’entrée est périmée après une mise à jour ou une copie."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.accessibility.attention")
      == "Turn on BabyWorks in System Settings › Privacy & Security › Accessibility. If BabyWorks is already on, remove it with “–”, then add it again: the entry is stale after an update or a copy."
  )
  #expect(L10nTable.language("fr")("settings.permissions.action.request") == "Demander l’accès")
  #expect(L10nTable.language("en")("settings.permissions.action.request") == "Request Access")
  #expect(
    L10nTable.language("fr")("settings.permissions.action.openSettings") == "Ouvrir Réglages Système"
  )
  #expect(
    L10nTable.language("en")("settings.permissions.action.openSettings") == "Open System Settings"
  )
}

@Test("Permissions : emplacement, démarrage automatique, et Afficher dans le Finder")
func permissionsLocationAndLaunchAtLoginCopy() {
  #expect(L10nTable.language("fr")("settings.permissions.location.title") == "Emplacement")
  #expect(L10nTable.language("en")("settings.permissions.location.title") == "Location")
  #expect(
    L10nTable.language("fr")("settings.permissions.location.ok")
      == "BabyWorks est dans le dossier Applications."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.location.ok")
      == "BabyWorks is in the Applications folder."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.location.attention")
      == "Déplacez BabyWorks dans le dossier Applications, puis rouvrez-la depuis là. L’autorisation Accessibilité est liée à cet emplacement."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.location.attention")
      == "Move BabyWorks to the Applications folder, then open it again from there. The Accessibility permission is tied to this location."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.action.revealInFinder") == "Afficher dans le Finder"
  )
  #expect(L10nTable.language("en")("settings.permissions.action.revealInFinder") == "Show in Finder")
  #expect(
    L10nTable.language("fr")("settings.permissions.launchAtLogin.title") == "Démarrage automatique"
  )
  #expect(L10nTable.language("en")("settings.permissions.launchAtLogin.title") == "Launch at Login")
  #expect(
    L10nTable.language("fr")("settings.permissions.launchAtLogin.ok")
      == "BabyWorks s’ouvrira à la connexion."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.launchAtLogin.ok") == "BabyWorks will open at login."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.launchAtLogin.requiresApproval")
      == "macOS attend votre accord pour ouvrir BabyWorks à la connexion."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.launchAtLogin.requiresApproval")
      == "macOS is waiting for your approval to open BabyWorks at login."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.launchAtLogin.notRegistered")
      == "Le démarrage automatique n’a pas pu être enregistré. Désactivez-le puis réactivez-le dans Général."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.launchAtLogin.notRegistered")
      == "Launch at login could not be registered. Turn it off, then turn it on again in General."
  )
}

@Test("Permissions : phrase de sortie tapable, intapable, et Modifier la phrase")
func permissionsPassphraseCopy() {
  #expect(L10nTable.language("fr")("settings.permissions.passphrase.title") == "Phrase de sortie")
  #expect(L10nTable.language("en")("settings.permissions.passphrase.title") == "Exit Phrase")
  #expect(
    L10nTable.language("fr")("settings.permissions.passphrase.ok", "Français")
      == "La phrase de sortie se tape avec la disposition « Français »."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.passphrase.ok", "French")
      == "The exit phrase is typed with the “French” layout."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.passphrase.attention", "U.S.", "é")
      == "Lettres absentes de la disposition « U.S. » : é."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.passphrase.attention", "U.S.", "é")
      == "Letters missing from the “U.S.” layout: é."
  )
  #expect(L10nTable.language("fr")("settings.permissions.action.changePhrase") == "Modifier la phrase")
  #expect(L10nTable.language("en")("settings.permissions.action.changePhrase") == "Change Phrase")
}

@Test("L’alerte de phrase intapable nomme les lettres manquantes")
func passphraseNotTypableAlertCopy() {
  #expect(
    L10nTable.language("fr")("alert.passphraseNotTypable", "é")
      == "La phrase de sortie ne peut pas être tapée avec la disposition clavier active (lettres absentes : é). Changez de phrase ou activez Maj-Échap."
  )
  #expect(
    L10nTable.language("en")("alert.passphraseNotTypable", "é")
      == "The exit phrase can't be typed with the active keyboard layout (missing letters: é). Change the phrase or turn on Shift-Escape."
  )
}

@Test("Une clé absente renvoie la clé")
func missingLocalizationKeyReturnsTheKey() {
  #expect(L10nTable.language("fr")("menu.absent") == "menu.absent")
  #expect(L10nTable.language("en")("menu.absent") == "menu.absent")
}

@Test("Les tables en et fr ont les mêmes clés, aucune valeur vide, et les mêmes spécificateurs")
func englishAndFrenchStringTablesMatch() throws {
  let english = try stringTable(language: "en")
  let french = try stringTable(language: "fr")

  #expect(Set(english.keys) == Set(french.keys))
  for key in english.keys.sorted() {
    let englishValue = try #require(english[key])
    let frenchValue = try #require(french[key])
    #expect(!englishValue.isEmpty)
    #expect(!frenchValue.isEmpty)
    #expect(formatSpecifiers(in: englishValue) == formatSpecifiers(in: frenchValue))
  }
}

@Test("Les spécificateurs reconnus sont %@, %lld, %d et %1$@, pas %%")
func formatSpecifiersMatchTheDocumentedForms() {
  #expect(formatSpecifiers(in: "%@ %lld %d %1$@") == ["%@", "%lld", "%d", "%1$@"])
  #expect(formatSpecifiers(in: "100%%") == [])
}

private func stringTable(language code: String) throws -> [String: String] {
  let lproj = try #require(L10n.bundle.url(forResource: code, withExtension: "lproj"))
  let strings = lproj.appendingPathComponent("Localizable.strings")
  return try #require(NSDictionary(contentsOf: strings) as? [String: String])
}

private func formatSpecifiers(in value: String) -> [String] {
  let pattern = /%(?:\d+\$)?[#0\-+\x20]*(?:\d+|\*)?(?:\.(?:\d+|\*))?(?:hh|h|ll|l|z|t|j|L)?[@dDiufFeEgGxXoscpaA]/
  return value.matches(of: pattern).map { String(value[$0.range]) }
}
