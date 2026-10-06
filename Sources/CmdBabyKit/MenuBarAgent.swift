import Foundation

/// Agent idle : politique d’activation, icône de barre, menu fixe.
/// Aucune dépendance AppKit — le câblage NSStatusItem vit dans CmdBaby.
public enum MenuBarAgent {
  public static let activationPolicy = ActivationPolicy.accessory
  public static let systemSymbolName = "fish"
  public static let usesTemplateImage = true

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
