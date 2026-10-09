import Foundation

/// Demande de lancement. L’origine est journalisée.
/// `mode` et `durationMinutes` ne valent que pour cette session : ils ne sont pas enregistrés.
public struct SessionLaunchRequest: Equatable, Sendable {
  public enum Origin: String, Equatable, Sendable {
    case menu
    case settings
    case shortcuts
    case link
  }

  public var origin: Origin
  public var mode: KioskPlayModeID?
  public var durationMinutes: Int?

  public init(
    origin: Origin,
    mode: KioskPlayModeID? = nil,
    durationMinutes: Int? = nil
  ) {
    self.origin = origin
    self.mode = mode
    self.durationMinutes = durationMinutes
  }

  /// Copie de la configuration enregistrée, avec les surcharges de cette session.
  /// Une durée hors de `AdultExitSettings.timeLimitRange` ne donne aucune configuration.
  public func effectiveConfiguration(from saved: CmdBabyConfiguration) -> SessionLaunchConfiguration {
    if let minutes = durationMinutes, !AdultExitSettings.timeLimitRange.contains(minutes) {
      return .invalidParameter
    }
    var configuration = saved
    if let mode {
      configuration.mode = mode
    }
    if let durationMinutes {
      configuration.exits.timeLimitMinutes = durationMinutes
    }
    return .ready(configuration)
  }
}

/// Configuration de cette session, ou refus avant tout lancement.
public enum SessionLaunchConfiguration: Equatable, Sendable {
  case ready(CmdBabyConfiguration)
  case invalidParameter
}

/// Modes proposés par l’action Raccourcis, dans l’ordre du catalogue.
/// Un mode ajouté à `KioskPlayModeID` sans cette liste fait échouer le test.
public enum SessionLaunchMode: Sendable {
  public static let playModes: [KioskPlayModeID] = [.ocean, .terminal, .starship]
}

/// Décision pure : lancer, déjà en cours, ou refusé avec le motif du contrôle.
/// Les échecs d’activation (`KioskSessionError` en phase `.failed`) réutilisent `.refused`.
public enum SessionLaunchDecision: Equatable, Sendable {
  case launch
  case alreadyInProgress
  case refused(KioskSessionError)
  case invalidParameter
  /// Lien `cmdbaby://` alors que la case Réglages › Général est décochée.
  case linkNotAllowed

  /// `linkLaunchAllowed` ne concerne que l’origine `.link`. Une phase occupée l’emporte :
  /// pendant une session, le lien ne devient pas une alerte.
  public static func evaluate(
    request: SessionLaunchRequest,
    phase: KioskSessionPhase,
    check: SessionLaunchCheck,
    linkLaunchAllowed: Bool
  ) -> SessionLaunchDecision {
    switch phase {
    case .preparing, .activating, .active, .stopping:
      return .alreadyInProgress
    case .configuration, .failed:
      break
    }
    if request.origin == .link, !linkLaunchAllowed {
      return .linkNotAllowed
    }
    if let minutes = request.durationMinutes, !AdultExitSettings.timeLimitRange.contains(minutes) {
      return .invalidParameter
    }
    switch check {
    case .allowed:
      return .launch
    case .blocked(let error):
      return .refused(error)
    }
  }

  /// Texte montré à l’appelant (Raccourcis). Les refus reprennent l’alerte.
  public func message(in table: L10nTable = .current) -> String {
    switch self {
    case .launch:
      table("shortcuts.startSession.launched")
    case .alreadyInProgress:
      table("shortcuts.startSession.alreadyInProgress")
    case .refused(let error):
      SessionActivationAlert.forFailedActivation(error, table: table).informativeText
    case .invalidParameter:
      table("shortcuts.startSession.invalidParameter")
    case .linkNotAllowed:
      table("alert.link.notAllowed")
    }
  }
}
