import Foundation

/// Demande de lancement. L’origine est journalisée.
/// `mode` et `durationMinutes` réservent la place des surcharges de la session
/// suivante : cette décision ne les applique pas.
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
}

/// Décision pure : lancer, déjà en cours, ou refusé avec le motif du contrôle.
/// Les échecs d’activation (`KioskSessionError` en phase `.failed`) réutilisent `.refused`.
public enum SessionLaunchDecision: Equatable, Sendable {
  case launch
  case alreadyInProgress
  case refused(KioskSessionError)

  public static func evaluate(
    request: SessionLaunchRequest,
    phase: KioskSessionPhase,
    check: SessionLaunchCheck
  ) -> SessionLaunchDecision {
    switch phase {
    case .preparing, .activating, .active, .stopping:
      return .alreadyInProgress
    case .configuration, .failed:
      break
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
    }
  }
}
