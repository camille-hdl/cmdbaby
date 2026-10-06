/// Arrêt du tap de session, à quelque moment qu’il soit demandé.
/// Le filtre le garde sous son verrou : création du port et arrêt ne se croisent pas.
public struct TapLifecycle: Equatable, Sendable {
  public enum AfterPortCreation: Equatable, Sendable {
    case enable
    /// Arrêt déjà demandé : ne jamais activer ni faire tourner ce tap.
    case invalidate
  }

  public enum OnStop: Equatable, Sendable {
    /// Port pas encore créé, ou déjà arrêté.
    case nothingToStop
    case disableAndStopLoop
  }

  private var stopRequested = false
  private var running = false

  public init() {}

  public mutating func portCreated() -> AfterPortCreation {
    guard !stopRequested else { return .invalidate }
    running = true
    return .enable
  }

  public mutating func requestStop() -> OnStop {
    stopRequested = true
    defer { running = false }
    return running ? .disableAndStopLoop : .nothingToStop
  }
}
