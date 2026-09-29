/// Création du tap de session : un prompt Accessibilité, un seul retry.
public enum AccessibilityTapCreation {
  /// Si le processus n’est pas de confiance, affiche le prompt système, crée le tap,
  /// puis relance `create` une fois en cas d’échec. Jamais de boucle.
  public static func createWithSingleTrustPrompt<Port>(
    isProcessTrusted: () -> Bool,
    promptForTrust: () -> Void,
    create: () -> Port?
  ) -> Port? {
    if !isProcessTrusted() {
      promptForTrust()
    }
    if let created = create() {
      return created
    }
    guard !isProcessTrusted() else {
      return nil
    }
    return create()
  }
}
