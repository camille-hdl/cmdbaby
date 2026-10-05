import AppKit
import BabyWorkDiagnosticsKit
import SwiftUI

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
  /// Instancie le mode. L’autre `switch` sur les modes est `preview`.
  static func make(_ id: KioskPlayModeID) -> any PlayMode {
    switch id {
    case .ocean:
      OceanPlayMode()
    case .terminal:
      TerminalPlayMode()
    case .starship:
      StarshipPlayMode()
    }
  }

  /// Aperçu statique de la carte de Réglages. Seul autre `switch` sur les modes.
  @ViewBuilder
  static func preview(_ id: KioskPlayModeID) -> some View {
    switch id {
    case .ocean:
      OceanModePreview()
    case .terminal:
      TerminalModePreview()
    case .starship:
      StarshipModePreview()
    }
  }
}

extension View {
  /// Cadre commun des aperçus de carte : 16:10, coins de 10 pt.
  func playModePreviewFrame<Overlay: View>(@ViewBuilder overlay: () -> Overlay) -> some View {
    aspectRatio(16.0 / 10.0, contentMode: .fit)
      .overlay { overlay() }
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .accessibilityHidden(true)
  }
}
