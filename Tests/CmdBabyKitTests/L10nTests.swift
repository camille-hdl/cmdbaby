import Foundation
import Testing

@testable import CmdBabyKit

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

@Test("Raccourcis : Lancer une session en français, Start a Session en anglais")
func startSessionShortcutCopy() {
  #expect(L10nTable.language("fr")("shortcuts.startSession.title") == "Lancer une session")
  #expect(L10nTable.language("en")("shortcuts.startSession.title") == "Start a Session")
  #expect(
    L10nTable.language("fr")("shortcuts.startSession.description")
      == "Lance une session avec les réglages enregistrés."
  )
  #expect(
    L10nTable.language("en")("shortcuts.startSession.description")
      == "Starts a session with your saved settings."
  )
}

@Test("Raccourcis : durée invalide, libellés et résumé Vaisseau de 10 minutes")
func startSessionOverrideCopy() {
  #expect(
    L10nTable.language("fr")("shortcuts.startSession.invalidParameter")
      == "La durée doit être comprise entre 1 et 120 minutes."
  )
  #expect(
    L10nTable.language("en")("shortcuts.startSession.invalidParameter")
      == "The duration must be between 1 and 120 minutes."
  )
  #expect(L10nTable.language("fr")("shortcuts.startSession.mode") == "Mode")
  #expect(L10nTable.language("en")("shortcuts.startSession.mode") == "Mode")
  #expect(L10nTable.language("fr")("shortcuts.startSession.duration") == "Durée")
  #expect(L10nTable.language("en")("shortcuts.startSession.duration") == "Duration")
  #expect(L10nTable.language("fr")("shortcuts.startSession.duration.hint") == "Minutes, de 1 à 120")
  #expect(
    L10nTable.language("en")("shortcuts.startSession.duration.hint") == "Minutes, from 1 to 120"
  )
  #expect(
    L10nTable.language("fr")("shortcuts.startSession.summary", "Vaisseau", 10)
      == "Lancer une session Vaisseau de 10 minutes"
  )
  #expect(
    L10nTable.language("en")("shortcuts.startSession.summary", "Starship", 10)
      == "Start a Starship session for 10 minutes"
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
  #expect(L10nTable.language("fr")("settings.about.subtitle") == "CmdBaby et ce qui le rend possible.")
  #expect(L10nTable.language("en")("settings.about.subtitle") == "CmdBaby and what makes it possible.")
  #expect(L10nTable.language("fr")("settings.about.assets") == "Images")
  #expect(L10nTable.language("en")("settings.about.assets") == "Artwork")
  #expect(L10nTable.language("fr")("settings.about.madeBy") == "Made by")
  #expect(L10nTable.language("en")("settings.about.madeBy") == "Made by")
  #expect(L10nTable.language("fr")("settings.about.name.fallback") == "CmdBaby")
  #expect(L10nTable.language("en")("settings.about.name.fallback") == "CmdBaby")
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
      == "Relancer CmdBaby pour appliquer"
  )
  #expect(
    L10nTable.language("en")("settings.general.language.relaunch.help")
      == "Relaunch CmdBaby to apply"
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
      == "CmdBaby peut filtrer les raccourcis pendant une session."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.accessibility.ok")
      == "CmdBaby can filter shortcuts during a session."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.accessibility.attention")
      == "Cochez CmdBaby dans Réglages Système › Confidentialité et sécurité › Accessibilité. Si CmdBaby y est déjà cochée, retirez-la avec « – », puis ajoutez-la de nouveau : l’entrée est périmée après une mise à jour ou une copie."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.accessibility.attention")
      == "Turn on CmdBaby in System Settings › Privacy & Security › Accessibility. If CmdBaby is already on, remove it with “–”, then add it again: the entry is stale after an update or a copy."
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
      == "CmdBaby est dans le dossier Applications."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.location.ok")
      == "CmdBaby is in the Applications folder."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.location.attention")
      == "Déplacez CmdBaby dans le dossier Applications, puis rouvrez-la depuis là. L’autorisation Accessibilité est liée à cet emplacement."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.location.attention")
      == "Move CmdBaby to the Applications folder, then open it again from there. The Accessibility permission is tied to this location."
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
      == "CmdBaby s’ouvrira à la connexion."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.launchAtLogin.ok") == "CmdBaby will open at login."
  )
  #expect(
    L10nTable.language("fr")("settings.permissions.launchAtLogin.requiresApproval")
      == "macOS attend votre accord pour ouvrir CmdBaby à la connexion."
  )
  #expect(
    L10nTable.language("en")("settings.permissions.launchAtLogin.requiresApproval")
      == "macOS is waiting for your approval to open CmdBaby at login."
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

@Test("La fenêtre Réglages parle français et anglais")
func settingsWindowCopy() {
  #expect(L10nTable.language("fr")("settings.window.title") == "Réglages")
  #expect(L10nTable.language("en")("settings.window.title") == "Settings")

  #expect(L10nTable.language("fr")("settings.mode.title") == "Mode de jeu")
  #expect(L10nTable.language("en")("settings.mode.title") == "Play Mode")
  #expect(
    L10nTable.language("fr")("settings.mode.subtitle")
      == "Choisis ce que l’enfant voit pendant la session."
  )
  #expect(
    L10nTable.language("en")("settings.mode.subtitle")
      == "Choose what the child sees during the session."
  )

  #expect(L10nTable.language("fr")("settings.exits.title") == "Sorties")
  #expect(L10nTable.language("en")("settings.exits.title") == "Exits")
  #expect(L10nTable.language("fr")("settings.exits.subtitle") == "Ce qui met fin à une session.")
  #expect(L10nTable.language("en")("settings.exits.subtitle") == "What ends a session.")
  #expect(L10nTable.language("fr")("settings.exits.parent.title") == "Sorties parent")
  #expect(L10nTable.language("en")("settings.exits.parent.title") == "Parent Exits")
  #expect(L10nTable.language("fr")("settings.exits.passphrase.toggle") == "Phrase + Entrée")
  #expect(L10nTable.language("en")("settings.exits.passphrase.toggle") == "Phrase + Return")
  #expect(L10nTable.language("fr")("settings.exits.shiftEscape.label") == "Maj-Échap")
  #expect(L10nTable.language("en")("settings.exits.shiftEscape.label") == "Shift-Escape")
  #expect(L10nTable.language("fr")("settings.exits.shiftEscape.help") == "Maintenir Maj-Échap")
  #expect(L10nTable.language("en")("settings.exits.shiftEscape.help") == "Hold Shift-Escape")
  #expect(L10nTable.language("fr")("settings.exits.failsafe.label") == "Clics de secours")
  #expect(L10nTable.language("en")("settings.exits.failsafe.label") == "Failsafe clicks")
  #expect(
    L10nTable.language("fr")("settings.exits.failsafe.help")
      == "5 clics rapides sur le carré en bas à droite"
  )
  #expect(
    L10nTable.language("en")("settings.exits.failsafe.help")
      == "5 quick clicks on the square at the bottom right"
  )
  #expect(L10nTable.language("fr")("settings.exits.passphrase.label") == "Phrase de sortie")
  #expect(L10nTable.language("en")("settings.exits.passphrase.label") == "Exit Phrase")
  #expect(
    L10nTable.language("fr")("settings.exits.passphrase.help")
      == "3 à 12 lettres, à taper en moins de 5 secondes puis Entrée."
  )
  #expect(
    L10nTable.language("en")("settings.exits.passphrase.help")
      == "3 to 12 letters, typed in under 5 seconds, then Return."
  )
  #expect(
    L10nTable.language("fr")("settings.exits.keepOne") == "Gardez au moins une sortie active."
  )
  #expect(L10nTable.language("en")("settings.exits.keepOne") == "Keep at least one exit on.")

  #expect(L10nTable.language("fr")("settings.exits.timer.title") == "Minuteur")
  #expect(L10nTable.language("en")("settings.exits.timer.title") == "Timer")
  #expect(L10nTable.language("fr")("settings.exits.timer.label") == "Fin de session après")
  #expect(L10nTable.language("en")("settings.exits.timer.label") == "Session ends after")
  #expect(L10nTable.language("fr")("settings.exits.timer.field") == "minutes")
  #expect(L10nTable.language("en")("settings.exits.timer.field") == "minutes")
  #expect(L10nTable.language("fr")("settings.exits.timer.unit") == "min")
  #expect(L10nTable.language("en")("settings.exits.timer.unit") == "min")
  #expect(
    L10nTable.language("fr")("settings.exits.timer.accessibility")
      == "Fin de session après, en minutes"
  )
  #expect(
    L10nTable.language("en")("settings.exits.timer.accessibility")
      == "Session ends after, in minutes"
  )
  #expect(L10nTable.language("fr")("settings.exits.timer.duration") == "Durée de la session")
  #expect(L10nTable.language("en")("settings.exits.timer.duration") == "Session length")
  #expect(
    L10nTable.language("fr")("settings.exits.timer.help")
      == "Le contour du carré de secours se remplit pendant la session ; la session s’arrête quand il est complet."
  )
  #expect(
    L10nTable.language("en")("settings.exits.timer.help")
      == "The outline of the failsafe square fills during the session; the session stops when it is full."
  )
  #expect(
    L10nTable.language("fr")("settings.exits.timer.rejection", Int64(1), Int64(120))
      == "Indique une durée entre 1 et 120 minutes."
  )
  #expect(
    L10nTable.language("en")("settings.exits.timer.rejection", Int64(1), Int64(120))
      == "Enter a duration between 1 and 120 minutes."
  )

  #expect(L10nTable.language("fr")("settings.general.title") == "Général")
  #expect(L10nTable.language("en")("settings.general.title") == "General")
  #expect(
    L10nTable.language("fr")("settings.general.subtitle")
      == "Réglages qui s’appliquent en dehors d’une session."
  )
  #expect(
    L10nTable.language("en")("settings.general.subtitle")
      == "Settings that apply outside a session."
  )
  #expect(
    L10nTable.language("fr")("settings.general.launchAtLogin.label") == "Démarrage automatique"
  )
  #expect(
    L10nTable.language("en")("settings.general.launchAtLogin.label") == "Launch at Login"
  )
  #expect(
    L10nTable.language("fr")("settings.general.launchAtLogin.help")
      == "Ouvre CmdBaby dans la barre de menus au login, sans lancer de session."
  )
  #expect(
    L10nTable.language("en")("settings.general.launchAtLogin.help")
      == "Opens CmdBaby in the menu bar at login, without starting a session."
  )
}

@Test("Le menu principal, l’icône et les couvertures sont en anglais et en français")
func applicationMenuIconAndCoverLabelsAreLocalized() {
  #expect(L10nTable.language("fr")("menu.quitApplication") == "Quitter CmdBaby")
  #expect(L10nTable.language("en")("menu.quitApplication") == "Quit CmdBaby")
  #expect(L10nTable.language("fr")("menu.statusIcon.accessibility") == "CmdBaby")
  #expect(L10nTable.language("en")("menu.statusIcon.accessibility") == "CmdBaby")
  #expect(L10nTable.language("fr")("cover.failsafe.accessibility") == "Sortie de secours")
  #expect(L10nTable.language("en")("cover.failsafe.accessibility") == "Failsafe exit")
  #expect(L10nTable.language("fr")("cover.timer.accessibility") == "Minuteur de session")
  #expect(L10nTable.language("en")("cover.timer.accessibility") == "Session timer")
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
