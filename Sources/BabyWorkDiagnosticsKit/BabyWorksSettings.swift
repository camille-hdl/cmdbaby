import Foundation

/// Login Item du process principal (`SMAppService.mainApp` côté app).
public protocol LoginItemRegistration: Sendable {
  var isRegistered: Bool { get }
  var status: LoginItemStatus { get }
  func register() throws
  func unregister() throws
}

public enum SettingsError: Error, Equatable, Sendable {
  case timeLimitOutOfRange
  case lastManualExit
  case passphraseTooShort
  case passphraseTooLong
  case passphraseInvalidCharacters
}

extension SettingsError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .passphraseTooShort:
      "Au moins 3 lettres."
    case .passphraseTooLong:
      "12 lettres au maximum."
    case .passphraseInvalidCharacters:
      "Uniquement des lettres, sans espace ni chiffre."
    case .timeLimitOutOfRange, .lastManualExit:
      nil
    }
  }
}

public enum SettingsChange: Equatable, Sendable {
  case mode(KioskPlayModeID)
  case launchAtLogin(Bool)
  case timeLimitMinutes(Int)
  case exitMethod(AdultExitMethod, enabled: Bool)
  case passphrase(String)
}

/// Lecture, validation et enregistrement des réglages.
/// La réconciliation du Login Item et la persistance restent derrière `current()` et `apply(_:)`.
public struct BabyWorksSettings: Sendable {
  private let store: BabyWorksConfigurationStore
  private let loginItem: any LoginItemRegistration

  public init(store: BabyWorksConfigurationStore, loginItem: any LoginItemRegistration) {
    self.store = store
    self.loginItem = loginItem
  }

  /// Config sur disque. `launchAtLogin` est réconcilié avec l’état réel du Login Item.
  public func current() -> BabyWorksConfiguration {
    let registered = loginItem.isRegistered
    var configuration = store.load()
    if configuration.launchAtLogin != registered {
      configuration.launchAtLogin = registered
      try? store.save(configuration)
    }
    return configuration
  }

  /// Applique le changement, enregistre, et renvoie la config enregistrée.
  /// En cas d’erreur, rien n’est écrit.
  @discardableResult
  public func apply(_ change: SettingsChange) throws -> BabyWorksConfiguration {
    var configuration = store.load()
    switch change {
    case .mode(let mode):
      configuration.mode = mode
    case .launchAtLogin(let enabled):
      if enabled {
        if !loginItem.isRegistered {
          try loginItem.register()
        }
      } else if loginItem.isRegistered {
        try loginItem.unregister()
      }
      configuration.launchAtLogin = enabled
    case .timeLimitMinutes(let minutes):
      guard AdultExitSettings.timeLimitRange.contains(minutes) else {
        throw SettingsError.timeLimitOutOfRange
      }
      configuration.exits.timeLimitMinutes = minutes
    case .exitMethod(let method, let enabled):
      if enabled {
        configuration.exits.enabledMethods.insert(method)
      } else {
        var remaining = configuration.exits.enabledMethods
        remaining.remove(method)
        guard !remaining.isEmpty else {
          throw SettingsError.lastManualExit
        }
        configuration.exits.enabledMethods = remaining
      }
    case .passphrase(let raw):
      configuration.exits.passphrase = try ExitPassphrase.parse(raw)
    }
    try store.save(configuration)
    return configuration
  }
}
