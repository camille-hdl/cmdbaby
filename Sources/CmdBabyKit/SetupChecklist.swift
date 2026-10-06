import Foundation

/// Faits système que l’app lit pour la section Permissions.
public struct SetupFacts: Equatable, Sendable {
  public var accessibilityGranted: Bool
  public var bundlePath: String
  public var homeDirectory: String
  /// Vrai quand la configuration demande le démarrage automatique.
  public var launchAtLoginRequested: Bool
  public var loginItemStatus: LoginItemStatus
  /// Vrai quand la phrase de sortie est active.
  public var passphraseEnabled: Bool
  public var passphraseTypability: PassphraseTypability
  /// Nom localisé de la disposition active.
  public var layoutName: String?

  public init(
    accessibilityGranted: Bool,
    bundlePath: String,
    homeDirectory: String,
    launchAtLoginRequested: Bool,
    loginItemStatus: LoginItemStatus,
    passphraseEnabled: Bool,
    passphraseTypability: PassphraseTypability,
    layoutName: String?
  ) {
    self.accessibilityGranted = accessibilityGranted
    self.bundlePath = bundlePath
    self.homeDirectory = homeDirectory
    self.launchAtLoginRequested = launchAtLoginRequested
    self.loginItemStatus = loginItemStatus
    self.passphraseEnabled = passphraseEnabled
    self.passphraseTypability = passphraseTypability
    self.layoutName = layoutName
  }
}

public enum SetupCheckID: Equatable, Sendable, Hashable {
  case accessibility
  case location
  case launchAtLogin
  case passphrase
}

public enum SetupCheckState: Equatable, Sendable {
  case ok
  case attention
}

public enum SetupAction: Equatable, Sendable, Hashable {
  case requestAccessibility
  case openAccessibilitySettings
  case revealInFinder
  case openLoginItemsSettings
  case showExitsSection
}

/// Une vérification de la section Permissions.
public struct SetupCheck: Equatable, Sendable {
  public let id: SetupCheckID
  public let state: SetupCheckState
  public let titleKey: String
  public let detailKey: String
  public let detailArguments: [String]
  public let actions: [SetupAction]

  public init(
    id: SetupCheckID,
    state: SetupCheckState,
    titleKey: String,
    detailKey: String,
    detailArguments: [String] = [],
    actions: [SetupAction]
  ) {
    self.id = id
    self.state = state
    self.titleKey = titleKey
    self.detailKey = detailKey
    self.detailArguments = detailArguments
    self.actions = actions
  }

  /// Détail tel que le parent le lit, arguments compris.
  public func localizedDetail(in table: L10nTable) -> String {
    table.format(detailKey, arguments: detailArguments.map { $0 as CVarArg })
  }
}

/// Liste ordonnée des vérifications, calculée à partir des faits. `needsAttention` marque la barre latérale.
public struct SetupChecklist: Equatable, Sendable {
  public let checks: [SetupCheck]

  public var needsAttention: Bool {
    checks.contains { $0.state == .attention }
  }

  public init(facts: SetupFacts) {
    var checks = [
      Self.accessibility(granted: facts.accessibilityGranted),
      Self.location(bundlePath: facts.bundlePath, homeDirectory: facts.homeDirectory),
    ]
    if let launchAtLogin = Self.launchAtLogin(
      requested: facts.launchAtLoginRequested,
      status: facts.loginItemStatus
    ) {
      checks.append(launchAtLogin)
    }
    if let passphrase = Self.passphrase(
      enabled: facts.passphraseEnabled,
      typability: facts.passphraseTypability,
      layoutName: facts.layoutName
    ) {
      checks.append(passphrase)
    }
    self.checks = checks
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

  private static func location(bundlePath: String, homeDirectory: String) -> SetupCheck {
    if isInApplicationsFolder(bundlePath: bundlePath, homeDirectory: homeDirectory) {
      return SetupCheck(
        id: .location,
        state: .ok,
        titleKey: "settings.permissions.location.title",
        detailKey: "settings.permissions.location.ok",
        actions: []
      )
    }
    return SetupCheck(
      id: .location,
      state: .attention,
      titleKey: "settings.permissions.location.title",
      detailKey: "settings.permissions.location.attention",
      actions: [.revealInFinder]
    )
  }

  /// `/Applications/` ou `<home>/Applications/`. Le slash final évite un préfixe trop court.
  private static func isInApplicationsFolder(bundlePath: String, homeDirectory: String) -> Bool {
    bundlePath.hasPrefix("/Applications/")
      || bundlePath.hasPrefix(homeDirectory + "/Applications/")
  }

  private static func launchAtLogin(requested: Bool, status: LoginItemStatus) -> SetupCheck? {
    guard requested else { return nil }
    switch status {
    case .enabled:
      return SetupCheck(
        id: .launchAtLogin,
        state: .ok,
        titleKey: "settings.permissions.launchAtLogin.title",
        detailKey: "settings.permissions.launchAtLogin.ok",
        actions: []
      )
    case .requiresApproval:
      return SetupCheck(
        id: .launchAtLogin,
        state: .attention,
        titleKey: "settings.permissions.launchAtLogin.title",
        detailKey: "settings.permissions.launchAtLogin.requiresApproval",
        actions: [.openLoginItemsSettings]
      )
    case .notRegistered, .notFound:
      return SetupCheck(
        id: .launchAtLogin,
        state: .attention,
        titleKey: "settings.permissions.launchAtLogin.title",
        detailKey: "settings.permissions.launchAtLogin.notRegistered",
        actions: []
      )
    }
  }

  /// Seulement si la phrase de sortie est active.
  private static func passphrase(
    enabled: Bool,
    typability: PassphraseTypability,
    layoutName: String?
  ) -> SetupCheck? {
    guard enabled else { return nil }
    let name = layoutName ?? ""
    if typability.isTypable {
      return SetupCheck(
        id: .passphrase,
        state: .ok,
        titleKey: "settings.permissions.passphrase.title",
        detailKey: "settings.permissions.passphrase.ok",
        detailArguments: [name],
        actions: []
      )
    }
    let missing = typability.missingLetters.map(String.init).joined(separator: " ")
    return SetupCheck(
      id: .passphrase,
      state: .attention,
      titleKey: "settings.permissions.passphrase.title",
      detailKey: "settings.permissions.passphrase.attention",
      detailArguments: [name, missing],
      actions: [.showExitsSection]
    )
  }
}
