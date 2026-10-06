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
  /// Texte de rejet de la phrase de sortie. Les autres cas n’en ont pas :
  /// la fenêtre l’explique à part.
  public func message(in table: L10nTable) -> String? {
    switch self {
    case .passphraseTooShort:
      table("settings.error.passphrase.tooShort")
    case .passphraseTooLong:
      table("settings.error.passphrase.tooLong")
    case .passphraseInvalidCharacters:
      table("settings.error.passphrase.invalidCharacters")
    case .timeLimitOutOfRange, .lastManualExit:
      nil
    }
  }

  public var errorDescription: String? {
    message(in: .current)
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
public struct CmdBabySettings: Sendable {
  private let store: CmdBabyConfigurationStore
  private let loginItem: any LoginItemRegistration

  public init(store: CmdBabyConfigurationStore, loginItem: any LoginItemRegistration) {
    self.store = store
    self.loginItem = loginItem
  }

  /// Config sur disque. Un Login Item activé hors de l’app allume le réglage.
  /// Une demande déjà enregistrée reste si l’item est introuvable ou non enregistré,
  /// pour que Permissions puisse l’expliquer.
  public func current() -> CmdBabyConfiguration {
    let registered = loginItem.isRegistered
    var configuration = store.load()
    let keepUnregisteredRequest = configuration.launchAtLogin
      && !registered
      && (loginItem.status == .notRegistered || loginItem.status == .notFound)
    if keepUnregisteredRequest {
      return configuration
    }
    if configuration.launchAtLogin != registered {
      configuration.launchAtLogin = registered
      try? store.save(configuration)
    }
    return configuration
  }

  /// Applique le changement, enregistre, et renvoie la config enregistrée.
  /// En cas d’erreur, rien n’est écrit.
  @discardableResult
  public func apply(_ change: SettingsChange) throws -> CmdBabyConfiguration {
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
