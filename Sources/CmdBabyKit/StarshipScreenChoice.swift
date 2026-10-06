import Foundation

/// Écran du vaisseau. Pendant `StarshipTuning.screenChangeDelay`, le curseur est ignoré.
public enum StarshipScreenChoice: Sendable {
  /// `true` une fois écoulées `tuning.screenChangeDelay` secondes de session.
  public static func followsPointer(sessionAge: Double, tuning: StarshipTuning) -> Bool {
    sessionAge >= tuning.screenChangeDelay
  }

  /// Index de l’écran du vaisseau.
  /// Avant le délai, `pointerScreenIndex` est ignoré : le plus grand écran, donc pas de warp.
  /// Ensuite, même règle que `TerminalScreenLayout.placement`.
  public static func index(
    sessionAge: Double,
    pointerScreenIndex: Int?,
    screens: [TerminalScreen],
    tuning: StarshipTuning
  ) -> Int? {
    let pointer = followsPointer(sessionAge: sessionAge, tuning: tuning) ? pointerScreenIndex : nil
    return TerminalScreenLayout.placement(lastClickedIndex: pointer, screens: screens)
  }
}
