import Foundation

/// Faits système lus par l’app. Les tickets suivants ajoutent l’emplacement, le Login Item et la phrase.
public struct SetupFacts: Equatable, Sendable {
  public var accessibilityGranted: Bool

  public init(accessibilityGranted: Bool) {
    self.accessibilityGranted = accessibilityGranted
  }
}

public enum SetupCheckID: Equatable, Sendable, Hashable {
  case accessibility
}

public enum SetupCheckState: Equatable, Sendable {
  case ok
  case attention
}

public enum SetupAction: Equatable, Sendable, Hashable {
  case requestAccessibility
  case openAccessibilitySettings
}

/// Une vérification de la section Permissions.
public struct SetupCheck: Equatable, Sendable {
  public let id: SetupCheckID
  public let state: SetupCheckState
  public let titleKey: String
  public let detailKey: String
  public let actions: [SetupAction]

  public init(
    id: SetupCheckID,
    state: SetupCheckState,
    titleKey: String,
    detailKey: String,
    actions: [SetupAction]
  ) {
    self.id = id
    self.state = state
    self.titleKey = titleKey
    self.detailKey = detailKey
    self.actions = actions
  }
}

/// Liste ordonnée des vérifications, calculée à partir des faits. `needsAttention` marque la barre latérale.
public struct SetupChecklist: Equatable, Sendable {
  public let checks: [SetupCheck]

  public var needsAttention: Bool {
    checks.contains { $0.state == .attention }
  }

  public init(facts: SetupFacts) {
    checks = [Self.accessibility(granted: facts.accessibilityGranted)]
  }

  private static func accessibility(granted: Bool) -> SetupCheck {
    if granted {
      return SetupCheck(
        id: .accessibility,
        state: .ok,
        titleKey: "settings.permissions.accessibility.title",
        detailKey: "settings.permissions.accessibility.ok",
        actions: []
      )
    }
    return SetupCheck(
      id: .accessibility,
      state: .attention,
      titleKey: "settings.permissions.accessibility.title",
      detailKey: "settings.permissions.accessibility.attention",
      actions: [.requestAccessibility, .openAccessibilitySettings]
    )
  }
}
