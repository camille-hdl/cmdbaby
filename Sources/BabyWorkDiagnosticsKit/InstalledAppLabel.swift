import Foundation

/// Nom et version lus dans l’Info.plist, pour la section À propos.
public enum InstalledAppLabel {
  /// Nom affiché, sinon nom du bundle. Nil si les deux sont vides.
  public static func name(displayName: String?, bundleName: String?) -> String? {
    nonempty(displayName) ?? nonempty(bundleName)
  }

  /// `CFBundleShortVersionString` (`CFBundleVersion`). Nil si l’un des deux manque.
  public static func version(shortVersion: String?, build: String?) -> String? {
    guard let short = nonempty(shortVersion), let build = nonempty(build) else { return nil }
    return "\(short) (\(build))"
  }

  private static func nonempty(_ value: String?) -> String? {
    guard let value else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
