/// Présentation de Réglages depuis l’agent idle (`.accessory`).
/// L’activation `.regular` n’est que temporaire, le temps que la fenêtre soit visible.
public enum SettingsWindowPresentation {
  /// Pendant que Réglages est à l’écran, l’app peut devenir key.
  public static let visibleActivationPolicy = MenuBarAgent.ActivationPolicy.regular

  /// Fermer Réglages ramène l’idle, sauf si une autre surface parent est encore là.
  public static func activationPolicyAfterHiding(
    otherParentUIVisible: Bool
  ) -> MenuBarAgent.ActivationPolicy {
    otherParentUIVisible ? visibleActivationPolicy : MenuBarAgent.activationPolicy
  }

  public enum OrderFrontTiming: Equatable, Sendable {
    case immediate
    case afterStatusItemMenuDismisses
  }

  /// Le menu du status item vole l’activation s’il n’est pas encore fermé.
  public static func orderFrontTiming(fromStatusItemMenu: Bool) -> OrderFrontTiming {
    fromStatusItemMenu ? .afterStatusItemMenuDismisses : .immediate
  }
}
