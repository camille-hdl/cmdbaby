import Foundation

/// Demande de fin de kiosque : sortie adulte ou Quitter.
///
/// Seul `explicitQuit` tue le process. Une sortie adulte démonte la session
/// et laisse l’application vivante.
public enum KioskEndRequest: Equatable, Sendable {
  case adultExit(AdultExitKind)
  case explicitQuit

  public var terminatesProcess: Bool {
    switch self {
    case .adultExit(let kind):
      switch kind {
      case .passphrase, .shiftEscape, .failsafeClick, .timeLimit:
        false
      }
    case .explicitQuit:
      true
    }
  }
}
