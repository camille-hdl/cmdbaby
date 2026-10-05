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
