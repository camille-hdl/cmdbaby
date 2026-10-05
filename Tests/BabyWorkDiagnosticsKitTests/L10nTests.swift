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
