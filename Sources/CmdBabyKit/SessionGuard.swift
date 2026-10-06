/// Pourquoi la protection du clavier ne peut plus être garantie.
public enum SessionGuardWarning: Hashable, Sendable {
  case accessibilityLost
  /// Une autre app a activé Secure Event Input : le tap ne voit plus les frappes.
  case secureInput
}

public enum SessionGuardAction: Equatable, Sendable {
  case reenableTap
  case refocusCovers
  case warnParent(SessionGuardWarning)
}

/// Chien de garde d’une session active : ce qu’il faut faire, d’après l’état lu toutes les 0,5 s.
public enum SessionGuard {
  /// Dans l’ordre : réactiver le tap, reprendre le focus, prévenir l’adulte. Vide si tout va bien.
  public static func evaluate(
    tapEnabled: Bool,
    accessibilityTrusted: Bool,
    secureInputActive: Bool,
    appActive: Bool
  ) -> [SessionGuardAction] {
    var actions: [SessionGuardAction] = []
    if !tapEnabled && accessibilityTrusted {
      actions.append(.reenableTap)
    }
    if !appActive {
      actions.append(.refocusCovers)
    }
    if !accessibilityTrusted {
      actions.append(.warnParent(.accessibilityLost))
    }
    if secureInputActive {
      actions.append(.warnParent(.secureInput))
    }
    return actions
  }
}
