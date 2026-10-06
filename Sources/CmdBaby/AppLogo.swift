import AppKit
import CmdBabyKit
import SwiftUI

/// Logo ⌘ + biberon des Réglages. Suit l’apparence de la fenêtre ; décoratif, le nom est écrit à côté.
struct AppLogo: View {
  let size: CGFloat
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    Group {
      if let image = Self.image(AppLogoVariant.for(colorSchemeIsDark: colorScheme == .dark)) {
        Image(nsImage: image)
          .resizable()
          .interpolation(.high)
      } else {
        Color.clear
      }
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }

  /// PDF vectoriel : net à toutes les tailles.
  @MainActor private static var cache: [String: NSImage] = [:]

  @MainActor private static func image(_ variant: AppLogoVariant) -> NSImage? {
    if let cached = cache[variant.resourceName] {
      return cached
    }
    guard
      let url = ResourceBundle.shared.url(forResource: variant.resourceName, withExtension: "pdf"),
      let image = NSImage(contentsOf: url)
    else {
      return nil
    }
    cache[variant.resourceName] = image
    return image
  }
}
