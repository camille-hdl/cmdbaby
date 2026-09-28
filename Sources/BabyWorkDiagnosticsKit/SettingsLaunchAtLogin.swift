import Foundation

/// Login Item du process principal (`SMAppService.mainApp` côté app).
public protocol LoginItemRegistration: Sendable {
  var isRegistered: Bool { get }
  func register() throws
  func unregister() throws
}

/// Démarrage automatique dans Réglages : Login Item idle (pas de session), persisté dans la config.
public struct SettingsLaunchAtLogin: Sendable {
  private let store: BabyWorksConfigurationStore
  private let loginItem: any LoginItemRegistration

  public init(store: BabyWorksConfigurationStore, loginItem: any LoginItemRegistration) {
    self.store = store
    self.loginItem = loginItem
  }

  public func isEnabled() -> Bool {
    let registered = loginItem.isRegistered
    let current = store.load()
    if current.launchAtLogin != registered {
      try? persist(launchAtLogin: registered, onto: current)
    }
    return registered
  }

  public func setEnabled(_ enabled: Bool) throws {
    if enabled {
      if !loginItem.isRegistered {
        try loginItem.register()
      }
    } else if loginItem.isRegistered {
      try loginItem.unregister()
    }
    try persist(launchAtLogin: enabled)
  }

  private func persist(
    launchAtLogin: Bool,
    onto current: BabyWorksConfiguration? = nil
  ) throws {
    let current = current ?? store.load()
    try store.save(
      BabyWorksConfiguration(
        schemaVersion: current.schemaVersion,
        mode: current.mode,
        launchAtLogin: launchAtLogin
      )
    )
  }
}
