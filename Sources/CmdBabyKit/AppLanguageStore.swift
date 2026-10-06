import Foundation

/// Lecture et écriture de `AppleLanguages` dans le domaine de l’app.
public protocol AppLanguageStore: Sendable {
  /// Valeur de `AppleLanguages` dans le domaine de l’app, nil si absente.
  func appleLanguages() -> [String]?
  func setAppleLanguages(_ languages: [String]?)
}
