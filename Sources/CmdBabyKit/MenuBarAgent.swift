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
      Item(title: table("menu.settings"), action: .openSettings),
      Item(title: table("menu.quit"), action: .terminate),
    ]
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
  }

  public enum Action: Equatable, Sendable {
    case startSession
    case openSettings
    case terminate
  }
}
