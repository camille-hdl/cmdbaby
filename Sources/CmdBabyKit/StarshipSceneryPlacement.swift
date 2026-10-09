import Foundation

/// Décor déjà posé sur un écran. Un second appel ne l’empile pas.
/// Si l’origine ou la taille de l’écran change, les éléments posés sont oubliés : le painter retire
/// leurs calques, et ils sont rejoués avec le même `beginTime`. Un autre écran a son propre placement.
public struct StarshipSceneryPlacement: Equatable, Sendable {
  public struct Flight: Equatable, Sendable {
    public var elementID: Int
    public var from: StarshipPoint
    public var to: StarshipPoint
    public var mediaBeginTime: TimeInterval
  }

  /// Calques à retirer, puis le vol à poser. `flight` est `nil` si l’élément est déjà en place.
  public struct Update: Equatable, Sendable {
    public var droppedIDs: Set<Int>
    public var flight: Flight?
  }

  private var screen: TerminalScreen?
  private var placed: Set<Int> = []

  public init() {}

  public mutating func install(
    _ element: StarshipSceneryElement,
    on screen: TerminalScreen,
    mediaBeginTime: TimeInterval
  ) -> Update {
    var dropped: Set<Int> = []
    if let previous = self.screen, frameChanged(previous, screen) {
      dropped = placed
      placed.removeAll(keepingCapacity: false)
    }
    self.screen = screen
    guard placed.insert(element.id).inserted else {
      return Update(droppedIDs: dropped, flight: nil)
    }
    return Update(
      droppedIDs: dropped,
      flight: Flight(
        elementID: element.id,
        from: element.localPoint(at: element.start, on: screen),
        to: element.localPoint(at: element.start + element.duration, on: screen),
        mediaBeginTime: mediaBeginTime
      )
    )
  }

  /// L’élément a quitté l’écran : son calque n’est plus là.
  public mutating func forget(_ elementID: Int) {
    placed.remove(elementID)
  }

  /// Sortie adulte : plus aucun calque, plus aucun souvenir du cadre.
  public mutating func reset() {
    screen = nil
    placed.removeAll(keepingCapacity: false)
  }

  private func frameChanged(_ previous: TerminalScreen, _ next: TerminalScreen) -> Bool {
    previous.x != next.x || previous.y != next.y
      || previous.width != next.width || previous.height != next.height
  }
}
