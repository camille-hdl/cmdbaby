import AppKit
import ApplicationServices
import CmdBabyKit

/// Demande d’Accessibilité et ouverture de la page Réglages Système.
/// L’alerte d’échec de session fait les deux ; la section Permissions les sépare.
@MainActor
enum AccessibilitySettings {
  static func isProcessTrusted() -> Bool {
    AXIsProcessTrusted()
  }

  static func requestAccess() {
    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
    _ = AXIsProcessTrustedWithOptions(options)
  }

  /// Première URL de `SessionActivationAlert.accessibilitySettingsURLCandidates` que le système ouvre.
  static func openSystemSettings() {
    for candidate in SessionActivationAlert.accessibilitySettingsURLCandidates {
      guard let url = URL(string: candidate), NSWorkspace.shared.open(url) else { continue }
      return
    }
  }
}
