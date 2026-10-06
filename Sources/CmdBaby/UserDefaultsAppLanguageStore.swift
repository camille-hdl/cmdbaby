import CmdBabyKit
import Foundation

/// `AppleLanguages` du domaine de l’app, la même clé que Réglages Système › Applications.
struct UserDefaultsAppLanguageStore: AppLanguageStore {
  private static let appleLanguagesKey = "AppleLanguages"

  func appleLanguages() -> [String]? {
    guard let identifier = Bundle.main.bundleIdentifier else { return nil }
    let domain = UserDefaults.standard.persistentDomain(forName: identifier)
    return domain?[Self.appleLanguagesKey] as? [String]
  }

  func setAppleLanguages(_ languages: [String]?) {
    if let languages {
      UserDefaults.standard.set(languages, forKey: Self.appleLanguagesKey)
    } else {
      UserDefaults.standard.removeObject(forKey: Self.appleLanguagesKey)
    }
  }
}
