import Foundation

/// Agent idle : politique d’activation, icône de barre, menu fixe.
/// Aucune dépendance AppKit — le câblage NSStatusItem vit dans BabyWorks.
public enum MenuBarAgent {
  public static let activationPolicy = ActivationPolicy.accessory
  public static let systemSymbolName = "fish"
  public static let usesTemplateImage = true

  public static let items: [Item] = [
    Item(title: "Lancer session", action: .stub),
    Item(title: "Réglages…", action: .openSettings),
    Item(title: "Quitter", action: .terminate),
  ]

  public enum ActivationPolicy: Equatable, Sendable {
    /// Correspond à `NSApplication.ActivationPolicy.accessory`.
    case accessory
  }

  public struct Item: Equatable, Sendable {
    public let title: String
    public let action: Action
  }

  public enum Action: Equatable, Sendable {
    case stub
    case openSettings
    case terminate
  }
}
