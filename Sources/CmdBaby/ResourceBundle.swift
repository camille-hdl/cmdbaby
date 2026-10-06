import Foundation

enum ResourceBundle {
  /// `Bundle.module` SPM cherche le `.bundle` à la racine du `.app`, interdit par codesign.
  /// Le script d’empaquetage le pose dans `Contents/Resources/`.
  static let shared: Bundle = {
    let names = "CmdBaby_CmdBaby.bundle"
    if let resources = Bundle.main.resourceURL {
      let packaged = resources.appendingPathComponent(names)
      if let bundle = Bundle(url: packaged) {
        return bundle
      }
    }
    return Bundle.module
  }()
}
