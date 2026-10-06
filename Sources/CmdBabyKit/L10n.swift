import Foundation

/// Table de chaînes d’une langue. `callAsFunction` formate avec `%@` et `%lld`.
public struct L10nTable: Sendable {
  /// Langue choisie par macOS pour le bundle du kit (préférences de l’utilisateur ∩ en/fr, repli en).
  public static let current: L10nTable = {
    let code = L10n.bundle.preferredLocalizations.first { $0 != "Base" } ?? "en"
    return language(code)
  }()

  /// Table d’une langue précise (`"en"` ou `"fr"`), pour les tests.
  public static func language(_ code: String) -> L10nTable {
    L10nTable(entries: entries(in: code), languageCode: code)
  }

  private let entries: [String: String]
  private let languageCode: String

  /// Chaîne de la clé, formatée avec `arguments`. Clé absente : renvoie la clé.
  public func callAsFunction(_ key: String, _ arguments: CVarArg...) -> String {
    format(key, arguments: arguments)
  }

  func format(_ key: String, arguments: [CVarArg]) -> String {
    guard let format = entries[key] else { return key }
    guard !arguments.isEmpty else { return format }
    return String(format: format, locale: Locale(identifier: languageCode), arguments: arguments)
  }

  /// Jeton des tables remplacé par `AppIdentity.displayName`.
  static let appNameToken = "{app}"

  /// Charge le sous-bundle `<code>.lproj` du kit et y place le nom de l’app.
  private static func entries(in code: String) -> [String: String] {
    guard
      let lprojURL = L10n.bundle.url(forResource: code, withExtension: "lproj"),
      let lproj = Bundle(url: lprojURL),
      let stringsURL = lproj.url(forResource: "Localizable", withExtension: "strings"),
      let dictionary = NSDictionary(contentsOf: stringsURL) as? [String: String]
    else {
      return [:]
    }
    return dictionary.mapValues {
      $0.replacingOccurrences(of: appNameToken, with: AppIdentity.displayName)
    }
  }
}

public enum L10n {
  public static var current: L10nTable { L10nTable.current }

  /// Bundle de ressources du kit, voir `KitResources`.
  public static var bundle: Bundle { KitResources.bundle }
}
