import Foundation

/// Préférence de langue, lue et écrite via `AppleLanguages`.
public struct AppLanguageSettings: Sendable {
  private let store: any AppLanguageStore

  public init(store: any AppLanguageStore) {
    self.store = store
  }

  /// `["fr…"]` → french, `["en…"]` → english, nil ou autre → system.
  public func current() -> AppLanguagePreference {
    guard let code = store.appleLanguages()?.first else { return .system }
    switch primaryLanguage(of: code) {
    case "fr":
      return .french
    case "en":
      return .english
    default:
      return .system
    }
  }

  /// english → `["en"]`, french → `["fr"]`, system → clé supprimée.
  public func apply(_ preference: AppLanguagePreference) {
    switch preference {
    case .english:
      store.setAppleLanguages(["en"])
    case .french:
      store.setAppleLanguages(["fr"])
    case .system:
      store.setAppleLanguages(nil)
    }
  }

  /// Sous-étiquette principale : `fr-FR` et `fr_CA` donnent `fr`.
  private func primaryLanguage(of code: String) -> String {
    let lowered = code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard let primary = lowered.split(whereSeparator: { $0 == "-" || $0 == "_" }).first else {
      return ""
    }
    return String(primary)
  }
}
