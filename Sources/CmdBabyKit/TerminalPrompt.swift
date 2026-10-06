import Foundation

public enum TerminalRainRequest: Equatable, Sendable {
  /// Entrée : une vague. Le director tire le nombre de colonnes.
  case wave
  /// Dix caractères tapés sans Entrée : une colonne.
  case column
}

public struct TerminalPrompt: Equatable, Sendable {
  public static let maxCharacters = 160
  public static let keysPerColumn = 10

  public private(set) var text: String
  public private(set) var keysSinceLastColumn: Int

  public init() {
    text = ""
    keysSinceLastColumn = 0
  }

  public mutating func type(_ character: Character) -> TerminalRainRequest? {
    text.append(character)
    if text.count > Self.maxCharacters {
      text.removeFirst()
    }
    keysSinceLastColumn += 1
    guard keysSinceLastColumn >= Self.keysPerColumn else { return nil }
    keysSinceLastColumn = 0
    return .column
  }

  public mutating func deleteBackward() {
    guard !text.isEmpty else { return }
    text.removeLast()
  }

  public mutating func submit() -> TerminalRainRequest {
    text = ""
    keysSinceLastColumn = 0
    return .wave
  }
}
