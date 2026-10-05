import Foundation

/// Section des Réglages choisie par le kit au lancement.
/// L’app la traduit vers `SettingsSection`.
public enum InitialSettingsSection: Equatable, Sendable {
  case exits
  case general
}
