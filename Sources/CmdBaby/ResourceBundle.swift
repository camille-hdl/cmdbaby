import CmdBabyKit
import Foundation

enum ResourceBundle {
  /// Bundle de ressources de l’app : `Contents/Resources/CmdBaby_CmdBaby.bundle` dans le `.app`.
  /// Même règle que le kit : jamais de repli hors du bundle signé.
  static let shared: Bundle = KitResources.resourceBundle(named: "CmdBaby_CmdBaby.bundle") {
    #if DEBUG
    Bundle.module
    #else
    Bundle.main
    #endif
  }
}
