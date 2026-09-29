/// Création du tap de session : un prompt Accessibilité, un seul retry.
public enum AccessibilityTapCreation {
  /// Si la première création échoue et que le processus n’est pas de confiance,
  /// affiche le prompt système puis relance `create` une fois. Jamais de boucle.
  public static func createWithSingleTrustPrompt<Port>(
    isProcessTrusted: () -> Bool,
    promptForTrust: () -> Void,
    create: () -> Port?
  ) -> Port? {
    if let created = create() {
      return created
    }
    guard !isProcessTrusted() else {
      return nil
    }
    promptForTrust()
    return create()
  }
}
