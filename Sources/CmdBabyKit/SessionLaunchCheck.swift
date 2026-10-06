import Foundation

/// Décision de lancer une session.
/// Bloquée seulement si la phrase est la seule sortie manuelle et n’est pas tapable.
public enum SessionLaunchCheck: Equatable, Sendable {
  case allowed
  case blocked(missingLetters: [Character])

  public static func evaluate(
    exits: AdultExitSettings,
    typability: PassphraseTypability
  ) -> SessionLaunchCheck {
    guard exits.enabledMethods == [.passphrase], !typability.isTypable else {
      return .allowed
    }
    return .blocked(missingLetters: typability.missingLetters)
  }
}
