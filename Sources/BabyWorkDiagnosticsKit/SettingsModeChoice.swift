import Foundation

/// Choix du mode dans Réglages : options du registre, persisté dans la config.
public struct SettingsModeChoice: Sendable {
  public let store: BabyWorksConfigurationStore

  public init(store: BabyWorksConfigurationStore = BabyWorksConfigurationStore()) {
    self.store = store
  }

  public var options: [KioskPlayModeID] {
    KioskPlayModeCatalog.available
  }

  public func selectedMode() -> KioskPlayModeID {
    store.load().mode
  }

  public func select(_ mode: KioskPlayModeID) throws {
    let current = store.load()
    try store.save(
      BabyWorksConfiguration(
        schemaVersion: current.schemaVersion,
        mode: mode,
        launchAtLogin: current.launchAtLogin
      )
    )
  }
}
