import Foundation

/// Agent idle : politique d’activation, icône de barre, menu fixe.
/// Aucune dépendance AppKit — le câblage NSStatusItem vit dans CmdBaby.
public enum MenuBarAgent {
  public static let activationPolicy = ActivationPolicy.accessory
  /// Biberon de l’identité, PDF noir sur transparent dans les ressources du kit.
  public static let statusIconResourceName = "MenuBarIcon"
  public static let statusIconPointSize = CGSize(width: 18, height: 18)
  public static let usesTemplateImage = true
  /// Repli si le PDF manque (bug d’empaquetage) : la barre de menus n’est jamais vide.
  public static let fallbackSymbolName = "fish"

  public static func statusIconURL() -> URL? {
    KitResources.bundle.url(forResource: statusIconResourceName, withExtension: "pdf")
  }

  public static func items(_ table: L10nTable = .current) -> [Item] {
    [
      Item(title: table("menu.startSession"), action: .startSession),
      Item(title: table("menu.settings"), action: .openSettings, keyEquivalent: ","),
      Item(title: table("menu.quit"), action: .terminate),
    ]
  }

  /// Menu de l’app, visible quand les Réglages sont au premier plan. En session, la barre des menus est masquée.
  public static let applicationMenu: [MenuEntry] = [
    MenuEntry("menu.app.about", .about),
    MenuEntry("menu.app.checkForUpdates", .checkForUpdates),
    .separator,
    MenuEntry("menu.settings", .settings, key: ","),
    .separator,
    MenuEntry("menu.app.hide", .hide, key: "h"),
    MenuEntry("menu.app.hideOthers", .hideOthers, key: "h", modifiers: [.command, .option]),
    MenuEntry("menu.app.showAll", .showAll),
    .separator,
    MenuEntry("menu.quitApplication", .quit, key: "q"),
  ]

  public static let editMenuTitleKey = "menu.edit"

  /// Menu Édition : sans lui, Cmd-C, Cmd-V… ne font rien dans les champs des Réglages.
  public static let editMenu: [MenuEntry] = [
    MenuEntry("menu.edit.undo", .undo, key: "z"),
    MenuEntry("menu.edit.redo", .redo, key: "z", modifiers: [.command, .shift]),
    .separator,
    MenuEntry("menu.edit.cut", .cut, key: "x"),
    MenuEntry("menu.edit.copy", .copy, key: "c"),
    MenuEntry("menu.edit.paste", .paste, key: "v"),
    MenuEntry("menu.edit.selectAll", .selectAll, key: "a"),
  ]

  public struct MenuEntry: Equatable, Sendable {
    public let titleKey: String
    public let command: MenuCommand
    /// "" si aucun.
    public let keyEquivalent: String
    public let modifiers: InputModifierMask

    public init(
      _ titleKey: String,
      _ command: MenuCommand,
      key keyEquivalent: String = "",
      modifiers: InputModifierMask = [.command]
    ) {
      self.titleKey = titleKey
      self.command = command
      self.keyEquivalent = keyEquivalent
      self.modifiers = modifiers
    }

    public static let separator = MenuEntry("", .separator)
  }

  public enum MenuCommand: Equatable, Sendable {
    case about, checkForUpdates, settings, hide, hideOthers, showAll, quit
    case undo, redo, cut, copy, paste, selectAll
    case separator
  }

  public enum ActivationPolicy: Equatable, Sendable {
    /// Correspond à `NSApplication.ActivationPolicy.accessory`.
    case accessory
    /// Correspond à `NSApplication.ActivationPolicy.regular`.
    case regular
  }

  public struct Item: Equatable, Sendable {
    public let title: String
    public let action: Action
    /// Équivalent clavier affiché, avec Commande ; "" si aucun.
    public let keyEquivalent: String

    public init(title: String, action: Action, keyEquivalent: String = "") {
      self.title = title
      self.action = action
      self.keyEquivalent = keyEquivalent
    }
  }

  public enum Action: Equatable, Sendable {
    case startSession
    case openSettings
    case terminate
  }
}
