/// Barrière de session des mises à jour Sparkle, consultée avant la vérification
/// et de nouveau quand une mise à jour est trouvée : une session peut commencer entre les deux.
/// Un refus est mémorisé pour relancer la vérification à la fin de la session.
public struct UpdateSessionGate: Sendable {
  private var checkDeferred = false

  public init() {}

  public mutating func allows(sessionActive: Bool) -> Bool {
    guard UpdatePresentationPolicy.allowsPresentation(sessionActive: sessionActive) else {
      checkDeferred = true
      return false
    }
    return true
  }

  /// Vrai si une vérification a été refusée pendant la session et doit être relancée.
  public mutating func sessionDidEnd() -> Bool {
    defer { checkDeferred = false }
    return checkDeferred
  }
}
