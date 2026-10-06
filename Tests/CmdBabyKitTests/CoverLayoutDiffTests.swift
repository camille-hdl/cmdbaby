import CoreGraphics
import Testing

@testable import CmdBabyKit

private let main = CGRect(x: 0, y: 0, width: 1512, height: 982)
private let external = CGRect(x: 1512, y: 0, width: 2560, height: 1440)

@Test("Un écran branché est à ajouter")
func pluggedScreenIsAdded() {
  let diff = CoverLayoutDiff.changes(current: [1: main], next: [1: main, 2: external])
  #expect(diff == CoverLayoutDiff(add: [2], remove: [], reframe: []))
}

@Test("Un écran débranché est à retirer")
func unpluggedScreenIsRemoved() {
  let diff = CoverLayoutDiff.changes(current: [1: main, 2: external], next: [1: main])
  #expect(diff == CoverLayoutDiff(add: [], remove: [2], reframe: []))
}

@Test("Un écran qui change de résolution est à recadrer")
func resizedScreenIsReframed() {
  let resized = CGRect(x: 1512, y: 0, width: 1920, height: 1080)
  let diff = CoverLayoutDiff.changes(current: [1: main, 2: external], next: [1: main, 2: resized])
  #expect(diff == CoverLayoutDiff(add: [], remove: [], reframe: [2]))
}

@Test("Sans changement, rien à faire")
func unchangedLayoutDoesNothing() {
  let diff = CoverLayoutDiff.changes(current: [1: main, 2: external], next: [1: main, 2: external])
  #expect(diff.isEmpty)
}

@Test("Les écrans sortent triés, pour un ordre stable")
func screensAreSorted() {
  let diff = CoverLayoutDiff.changes(current: [:], next: [3: external, 1: main, 2: main])
  #expect(diff.add == [1, 2, 3])
}
