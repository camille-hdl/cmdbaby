import CoreGraphics

/// Identifiant stable d’un écran : `CGDirectDisplayID`, lu dans `NSScreenNumber`.
public typealias ScreenID = CGDirectDisplayID

/// Couvertures à créer, fermer ou recadrer quand les écrans changent en cours de session.
public struct CoverLayoutDiff: Equatable, Sendable {
  public var add: [ScreenID]
  public var remove: [ScreenID]
  public var reframe: [ScreenID]

  public init(add: [ScreenID], remove: [ScreenID], reframe: [ScreenID]) {
    self.add = add
    self.remove = remove
    self.reframe = reframe
  }

  public var isEmpty: Bool {
    add.isEmpty && remove.isEmpty && reframe.isEmpty
  }

  public static func changes(
    current: [ScreenID: CGRect],
    next: [ScreenID: CGRect]
  ) -> CoverLayoutDiff {
    CoverLayoutDiff(
      add: next.keys.filter { current[$0] == nil }.sorted(),
      remove: current.keys.filter { next[$0] == nil }.sorted(),
      reframe: next.keys.filter { id in
        current[id].map { $0 != next[id] } ?? false
      }.sorted()
    )
  }
}
