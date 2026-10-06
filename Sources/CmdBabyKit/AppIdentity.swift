import Foundation

/// Nom et identifiants publics de l’app. L’Info.plist et `os_log_create` du pont
/// Objective-C répètent ces valeurs : un test vérifie l’Info.plist.
public enum AppIdentity {
  public static let displayName = "CmdBaby"
  public static let bundleIdentifier = "app.cmdbaby.CmdBaby"
  public static let supportDirectoryName = "CmdBaby"
  public static let logSubsystem = bundleIdentifier

  /// `~/Library/Application Support/CmdBaby/`
  public static let supportDirectory = URL.applicationSupportDirectory
    .appendingPathComponent(supportDirectoryName, isDirectory: true)
}
