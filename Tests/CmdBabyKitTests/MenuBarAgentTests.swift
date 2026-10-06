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
