import AppKit
import BabyWorkDiagnosticsKit

/// Port entre les couvertures et la scène.
@MainActor
protocol PlayMode: AnyObject {
  /// Couleur de fond de la fenêtre de couverture n° `screenIndex`.
  func windowBackground(screenIndex: Int) -> NSColor
  /// Scène de jeu pour un écran ; le carré de secours est ajouté par les couvertures, pas par le mode.
  func makeStage(inputBridge: KioskInputBridge, screenIndex: Int, scale: CGFloat) -> NSView
  /// Démontage en fin de session (timers, banc, sprites propres au mode).
  func reset()
}

@MainActor
enum PlayModeRegistry {
  /// Seul `switch` de l’app sur les modes de jeu.
  static func make(_ id: KioskPlayModeID) -> any PlayMode {
    switch id {
    case .ocean:
      OceanPlayMode()
    case .galaxy:
      GalaxyPlayMode()
    }
  }
}
