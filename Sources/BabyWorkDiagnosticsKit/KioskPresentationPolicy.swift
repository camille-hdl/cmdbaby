import Foundation

/// Options de présentation AppKit (`NSApplication.PresentationOptions.rawValue`)
/// représentées sans importer AppKit, pour rester testables.
public struct PresentationOptionsSnapshot: Equatable, Sendable {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue = rawValue
  }
}

/// Combinaisons d’options de présentation validées par construction.
/// Les bits suivent `NSApplication.PresentationOptions`.
public enum KioskPresentationPolicy {
  public static let autoHideDock: UInt = 1 << 0
  public static let hideDock: UInt = 1 << 1
  public static let autoHideMenuBar: UInt = 1 << 2
  public static let hideMenuBar: UInt = 1 << 3
  public static let disableAppleMenu: UInt = 1 << 4
  public static let disableProcessSwitching: UInt = 1 << 5
  public static let disableForceQuit: UInt = 1 << 6
  public static let disableSessionTermination: UInt = 1 << 7
  public static let disableHideApplication: UInt = 1 << 8
  public static let fullScreen: UInt = 1 << 10

  /// Dock et barre de menus masqués, bascule d’app / Force Quit / fin de session / masquage désactivés.
  /// N’inclut pas `fullScreen` (combinaison distincte, plus restrictive).
  public static let kiosk = PresentationOptionsSnapshot(
    rawValue: hideDock | hideMenuBar | disableAppleMenu | disableProcessSwitching
      | disableForceQuit | disableSessionTermination | disableHideApplication
  )

  public static func isValid(_ snapshot: PresentationOptionsSnapshot) -> Bool {
    let value = snapshot.rawValue
    let hideDockSet = contains(value, hideDock)
    let autoHideDockSet = contains(value, autoHideDock)
    let hideMenuBarSet = contains(value, hideMenuBar)
    let autoHideMenuBarSet = contains(value, autoHideMenuBar)
    let fullScreenSet = contains(value, fullScreen)

    if hideDockSet && autoHideDockSet { return false }
    if hideMenuBarSet && autoHideMenuBarSet { return false }
    if hideMenuBarSet && !hideDockSet { return false }
    if autoHideMenuBarSet && !(hideDockSet || autoHideDockSet) { return false }
    if fullScreenSet && !(hideDockSet && autoHideMenuBarSet) { return false }
    return true
  }

  private static func contains(_ value: UInt, _ bit: UInt) -> Bool {
    value & bit != 0
  }
}

public struct ScreenDescriptor: Equatable, Sendable, Identifiable {
  public let id: String
  public let name: String
  public let originX: Double
  public let originY: Double
  public let width: Double
  public let height: Double
  public let scale: Double
  public let isMain: Bool

  public init(
    id: String,
    name: String,
    originX: Double,
    originY: Double,
    width: Double,
    height: Double,
    scale: Double,
    isMain: Bool
  ) {
    self.id = id
    self.name = name
    self.originX = originX
    self.originY = originY
    self.width = width
    self.height = height
    self.scale = scale
    self.isMain = isMain
  }

  public var hasNegativeOrigin: Bool {
    originX < 0 || originY < 0
  }
}

public enum FailureInjectionChoice: String, CaseIterable, Sendable, Hashable, Identifiable {
  case none
  case capturePresentation
  case prepareWindows
  case applyPresentation
  case startInputFilter

  public var id: String { rawValue }

  public var step: KioskPrepStep? {
    switch self {
    case .none:
      nil
    case .capturePresentation:
      .capturePresentation
    case .prepareWindows:
      .prepareWindows
    case .applyPresentation:
      .applyPresentation
    case .startInputFilter:
      .startInputFilter
    }
  }

  public var displayName: String {
    step?.displayName ?? "Aucune"
  }
}

public enum KioskPrepStep: String, CaseIterable, Sendable, Equatable {
  case capturePresentation
  case prepareWindows
  case applyPresentation
  case startInputFilter

  public var displayName: String {
    switch self {
    case .capturePresentation:
      "Mémoriser la présentation"
    case .prepareWindows:
      "Préparer les fenêtres"
    case .applyPresentation:
      "Appliquer la présentation"
    case .startInputFilter:
      "Démarrer le filtre"
    }
  }
}

public enum KioskSessionPhase: Equatable, Sendable {
  case configuration
  case preparing
  case activating
  case active
  case stopping
  case failed

  public var displayName: String {
    switch self {
    case .configuration:
      "Configuration"
    case .preparing:
      "Préparation"
    case .activating:
      "Activation"
    case .active:
      "Actif"
    case .stopping:
      "Arrêt"
    case .failed:
      "Échec"
    }
  }
}

public enum KioskSessionError: Error, Equatable, Sendable {
  case noScreens
  case injectedFailure(KioskPrepStep)
  case presentationRejected
  case filterUnavailable(String)
}

extension KioskSessionError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .noScreens:
      "Aucun écran n’est disponible pour la couverture."
    case .injectedFailure(let step):
      "Défaillance injectée à l’étape « \(step.displayName) »."
    case .presentationRejected:
      "Les options de présentation kiosque ont été refusées."
    case .filterUnavailable(let reason):
      "Le filtre d’entrée n’a pas pu démarrer (\(reason))."
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .noScreens:
      "Vérifier qu’un écran est connecté, puis réessayer."
    case .injectedFailure:
      "Retirer la défaillance simulée pour un démarrage réel."
    case .presentationRejected:
      "Relancer l’application et réessayer le mode kiosque."
    case .filterUnavailable:
      "Accorder Accessibilité, puis quitter et relancer l’application."
    }
  }
}

public struct KioskSessionState: Equatable, Sendable {
  public var phase: KioskSessionPhase
  public var coveredScreens: [ScreenDescriptor]
  public var lastError: KioskSessionError?
  public var lastExitKind: AdultExitKind?

  public init(
    phase: KioskSessionPhase = .configuration,
    coveredScreens: [ScreenDescriptor] = [],
    lastError: KioskSessionError? = nil,
    lastExitKind: AdultExitKind? = nil
  ) {
    self.phase = phase
    self.coveredScreens = coveredScreens
    self.lastError = lastError
    self.lastExitKind = lastExitKind
  }

  public var blocksTermination: Bool {
    switch phase {
    case .preparing, .activating, .active, .stopping:
      true
    case .configuration, .failed:
      false
    }
  }
}
