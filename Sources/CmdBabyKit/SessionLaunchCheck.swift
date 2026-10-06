import Foundation

/// Décision de lancer une session.
/// Bloquée si une autre app protège la saisie (le tap ne verrait rien),
/// ou si la phrase est la seule sortie manuelle et n’est pas tapable.
public enum SessionLaunchCheck: Equatable, Sendable {
  case allowed
  case blocked(KioskSessionError)

  public static func evaluate(
    exits: AdultExitSettings,
    typability: PassphraseTypability,
    secureInputActive: Bool
  ) -> SessionLaunchCheck {
    if secureInputActive {
      return .blocked(.secureInputActive)
    }
    guard exits.enabledMethods == [.passphrase], !typability.isTypable else {
      return .allowed
    }
    return .blocked(.passphraseNotTypable(typability.missingLetters))
  }
}
