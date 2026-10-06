import Foundation

/// Section des Réglages choisie par le kit.
/// L’app la traduit vers `SettingsSection`.
public enum InitialSettingsSection: Equatable, Sendable {
  case mode
  case exits
  case general
  case permissions
}
