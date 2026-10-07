/// Mises à jour (Sparkle) : rien ne s’affiche ni ne s’installe pendant une session.
/// Une vérification tombée pendant la session est relancée à sa fin.
public enum UpdatePresentationPolicy {
  public static func allowsPresentation(sessionActive: Bool) -> Bool {
    !sessionActive
  }
}
