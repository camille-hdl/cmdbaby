import Foundation

/// Phrase de sortie adulte : forme normalisée, puis bornes et lettres seules.
public struct ExitPassphrase: Equatable, Sendable {
  public static let defaultValue = ExitPassphrase(value: "parent")

  public let value: String

  private init(value: String) {
    self.value = value
  }

  /// Espaces de bord retirés, minuscules, NFC, puis 3 à 12 lettres.
  public static func parse(_ raw: String) throws -> ExitPassphrase {
    let normalized = raw
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .precomposedStringWithCanonicalMapping
    let scalars = normalized.unicodeScalars
    if scalars.contains(where: { !CharacterSet.letters.contains($0) }) {
      throw SettingsError.passphraseInvalidCharacters
    }
    if scalars.count < 3 {
      throw SettingsError.passphraseTooShort
    }
    if scalars.count > 12 {
      throw SettingsError.passphraseTooLong
    }
    return ExitPassphrase(value: normalized)
  }
}
