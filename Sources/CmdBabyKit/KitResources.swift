import Foundation

enum KitResources {
  /// Bundle de ressources du kit : `Contents/Resources/CmdBaby_CmdBabyKit.bundle`
  /// dans le .app empaqueté, sinon `Bundle.module` (swift test, swift run).
  /// `Bundle.module` cherche le `.bundle` à la racine du `.app`, interdit par codesign.
  static let bundle: Bundle = {
    let name = "CmdBaby_CmdBabyKit.bundle"
    if let resources = Bundle.main.resourceURL {
      let packaged = resources.appendingPathComponent(name)
      if let found = Bundle(url: packaged) {
        return found
      }
    }
    return Bundle.module
  }()
}
