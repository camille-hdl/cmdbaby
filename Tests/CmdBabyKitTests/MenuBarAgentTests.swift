import AppKit
import Testing

@testable import CmdBabyKit

@Test("L’agent idle n’a pas d’icône Dock")
func menuBarAgentUsesAccessoryActivationPolicy() {
  #expect(MenuBarAgent.activationPolicy == .accessory)
}

@Test("Le status item est le biberon en PDF template de 18 × 18 pt")
func menuBarAgentStatusItemIsTemplateBottle() throws {
  let url = try #require(MenuBarAgent.statusIconURL())
  #expect(FileManager.default.fileExists(atPath: url.path))
  let image = try #require(NSImage(contentsOf: url))
  #expect(image.size == MenuBarAgent.statusIconPointSize)
  #expect(MenuBarAgent.statusIconPointSize == CGSize(width: 18, height: 18))
  #expect(MenuBarAgent.usesTemplateImage)
}

@Test("Le menu de la barre de menus est en français")
func menuBarAgentMenuTitlesAreFrench() {
  #expect(
    MenuBarAgent.items(.language("fr")).map(\.title)
      == ["Lancer session", "Réglages…", "Quitter"]
  )
}

@Test("Le menu de la barre de menus est en anglais")
func menuBarAgentMenuTitlesAreEnglish() {
  #expect(
    MenuBarAgent.items(.language("en")).map(\.title)
      == ["Start Session", "Settings…", "Quit"]
  )
}

@Test("Lancer session démarre le kiosque ; Réglages ouvre la fenêtre ; seul Quitter termine")
func menuBarAgentLaunchStartsSessionSettingsOpenAndOnlyQuitTerminates() {
  #expect(
    MenuBarAgent.items(.language("en")).map(\.action)
      == [.startSession, .openSettings, .terminate]
  )
}

@Test("Un picto introuvable est journalisé")
func missingStatusIconIsLogged() {
  #expect(LifecycleLogEvent.statusIconMissing.message == "statusItem.icon missing fallback=fish")
  #expect(LifecycleLogEvent.statusIconMissing.category == .lifecycle)
}

@Test("Le menu de l’app : Réglages en ⌘, et Quitter en ⌘Q")
func applicationMenuHasSettingsAndQuitShortcuts() throws {
  let settings = try #require(MenuBarAgent.applicationMenu.first { $0.command == .settings })
  #expect(settings.keyEquivalent == ",")
  #expect(settings.modifiers == [.command])
  let quit = try #require(MenuBarAgent.applicationMenu.first { $0.command == .quit })
  #expect(quit.keyEquivalent == "q")
  #expect(
    MenuBarAgent.applicationMenu.map(\.command)
      == [.about, .separator, .settings, .separator, .hide, .hideOthers, .showAll, .separator, .quit]
  )
  let hideOthers = try #require(MenuBarAgent.applicationMenu.first { $0.command == .hideOthers })
  #expect(hideOthers.keyEquivalent == "h")
  #expect(hideOthers.modifiers == [.command, .option])
}

@Test("Le menu Édition porte les six commandes et leurs raccourcis standard")
func editMenuHasStandardShortcuts() {
  let shortcuts = MenuBarAgent.editMenu.filter { $0.command != .separator }
    .map { "\($0.command):\($0.keyEquivalent):\($0.modifiers.rawValue)" }
  let command = InputModifierMask.command.rawValue
  let commandShift = InputModifierMask([.command, .shift]).rawValue
  #expect(
    shortcuts == [
      "undo:z:\(command)", "redo:z:\(commandShift)", "cut:x:\(command)", "copy:c:\(command)",
      "paste:v:\(command)", "selectAll:a:\(command)",
    ]
  )
}

@Test("Chaque titre de menu existe en anglais et en français")
func menuTitlesAreTranslated() {
  let keys = (MenuBarAgent.applicationMenu + MenuBarAgent.editMenu)
    .filter { $0.command != .separator }
    .map(\.titleKey) + [MenuBarAgent.editMenuTitleKey]
  for language in ["en", "fr"] {
    let table = L10nTable.language(language)
    for key in keys {
      #expect(table(key) != key, "\(key) manque en \(language)")
    }
  }
  #expect(L10nTable.language("fr")("menu.app.about") == "À propos de CmdBaby")
  #expect(L10nTable.language("en")("menu.app.about") == "About CmdBaby")
}

@Test("Réglages… dans la barre de menus affiche ⌘,")
func statusMenuSettingsShowsShortcut() {
  #expect(MenuBarAgent.items(.language("en")).map(\.keyEquivalent) == ["", ",", ""])
}
