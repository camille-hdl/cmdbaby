import Foundation

/// Ce que le mode Vaisseau fait d’une frappe.
public enum StarshipKeyAction: Equatable, Sendable {
  /// Barre d’espace.
  case spin
  /// Toute autre touche (le glyphe éventuel est décidé au ticket des cibles).
  case other
  /// Répétition automatique d’une touche maintenue : ignorée par le mode.
  case ignored
}

/// Reconnaissance des touches du mode Vaisseau, sans AppKit.
public enum StarshipKey: Sendable {
  /// `keyCode` AppKit de la barre d’espace.
  private static let space: UInt16 = 49

  /// `keyCode` du `NSEvent` (49 = barre d’espace), `isARepeat` du `NSEvent`.
  public static func action(keyCode: UInt16, isARepeat: Bool) -> StarshipKeyAction {
    if isARepeat {
      return .ignored
    }
    if keyCode == space {
      return .spin
    }
    return .other
  }
}
