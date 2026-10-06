import Foundation

/// Lettres de la phrase de sortie absentes de la disposition clavier active.
public struct PassphraseTypability: Equatable, Sendable {
  /// Dans l’ordre de la phrase, sans doublon.
  public let missingLetters: [Character]

  public var isTypable: Bool { missingLetters.isEmpty }

  /// `layoutLetters` : pour chaque keycode, les lettres qu’il peut produire (minuscules).
  public static func check(
    _ phrase: ExitPassphrase,
    layoutLetters: [UInt16: Set<Character>]
  ) -> PassphraseTypability {
    let available = Set(layoutLetters.values.flatMap { $0.map(comparable) })
    var missing: [Character] = []
    var seen = Set<String>()
    for character in phrase.value {
      let key = comparable(character)
      guard !available.contains(key) else { continue }
      guard seen.insert(key).inserted else { continue }
      missing.append(character)
    }
    return PassphraseTypability(missingLetters: missing)
  }

  /// Même forme que `ExitPassphrase.parse` : minuscules, puis NFC.
  private static func comparable(_ character: Character) -> String {
    String(character)
      .lowercased()
      .precomposedStringWithCanonicalMapping
  }
}
