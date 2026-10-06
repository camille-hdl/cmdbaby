import Foundation

public enum KitResources {
  /// Bundle de ressources du kit : `Contents/Resources/CmdBaby_CmdBabyKit.bundle` dans le `.app`.
  static let bundle: Bundle = resourceBundle(named: "CmdBaby_CmdBabyKit.bundle") {
    #if DEBUG
    Bundle.module
    #else
    Bundle.main
    #endif
  }

  /// Dans un `.app`, jamais de repli hors du bundle signé : un bundle absent est journalisé et
  /// remplacé par `Bundle.main` (clés L10n affichées telles quelles). `Bundle.module`, qui inscrit
  /// le chemin absolu du build dans le binaire, ne sert qu’aux builds de debug (`swift test`, `swift run`).
  public static func resourceBundle(named name: String, module: () -> Bundle) -> Bundle {
    if let resources = Bundle.main.resourceURL,
      let packaged = Bundle(url: resources.appendingPathComponent(name))
    {
      return packaged
    }
    if Bundle.main.bundleURL.pathExtension == "app" {
      LifecycleLogRecorder.shared.emit(.resourceBundleMissing(name: name))
      return Bundle.main
    }
    #if DEBUG
    return module()
    #else
    return Bundle.main
    #endif
  }
}
