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

/// Séquence d’ouverture de Réglages : pas d’activation `.regular` tant que le menu track.
public struct SettingsShowSequence: Equatable, Sendable {
  public enum Phase: Equatable, Sendable {
    case waitingForMenuTracking
    case applyingPolicyThenOrderFront
    case retryingOrderFront
    case finished(outcome: LifecycleLog.SettingsOrderFrontOutcome)
  }

  public private(set) var phase: Phase

  public init(fromStatusItemMenu: Bool) {
    switch SettingsWindowPresentation.orderFrontTiming(fromStatusItemMenu: fromStatusItemMenu) {
    case .afterStatusItemMenuDismisses:
      phase = .waitingForMenuTracking
    case .immediate:
      phase = .applyingPolicyThenOrderFront
    }
  }

  public var shouldWaitForMenuTracking: Bool {
    if case .waitingForMenuTracking = phase { return true }
    return false
  }

  public var shouldApplyVisibleActivationPolicy: Bool {
    if case .applyingPolicyThenOrderFront = phase { return true }
    return false
  }

  public var shouldOrderFront: Bool {
    switch phase {
    case .applyingPolicyThenOrderFront, .retryingOrderFront:
      true
    case .waitingForMenuTracking, .finished:
      false
    }
  }

  public var orderFrontIsRetry: Bool {
    if case .retryingOrderFront = phase { return true }
    return false
  }

  public var finishedOutcome: LifecycleLog.SettingsOrderFrontOutcome? {
    if case .finished(let outcome) = phase { return outcome }
    return nil
  }

  public mutating func menuTrackingDidEnd() {
    guard case .waitingForMenuTracking = phase else { return }
    phase = .applyingPolicyThenOrderFront
  }

  @discardableResult
  public mutating func recordOrderFront(
    isVisible: Bool,
    isKeyWindow: Bool
  ) -> LifecycleLogEvent {
    let isRetry = orderFrontIsRetry
    let outcome: LifecycleLog.SettingsOrderFrontOutcome =
      (isVisible && isKeyWindow) ? .success : .fail
    if outcome == .success {
      phase = .finished(outcome: .success)
    } else if isRetry {
      phase = .finished(outcome: .fail)
    } else {
      phase = .retryingOrderFront
    }
    return .settingsOrderFront(
      isVisible: isVisible,
      isKeyWindow: isKeyWindow,
      outcome: outcome,
      retry: isRetry
    )
  }
}
