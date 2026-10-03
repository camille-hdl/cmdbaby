import AppKit
import SwiftUI

/// Couleurs de la fenêtre Réglages, palette « ft-paper ».
/// Un seul `NSColor` dynamique par jeton ; SwiftUI le résout quand `ColorScheme` change.
enum SettingsPalette {
  static let paper = Swatch(light: 0xFFF1_E5, dark: 0x1F19_15)
  static let paperRaised = Swatch(light: 0xFFF9_F2, dark: 0x261F_1A)
  static let surface1 = Swatch(light: 0xF7E7_D8, dark: 0x2B23_1D)
  static let surface2 = Swatch(light: 0xF2DF_CE, dark: 0x3A2F_27)
  static let surface3 = Swatch(light: 0xEFDC_CA, dark: 0x4034_2B)
  static let rule = Swatch(light: 0xB8AF_A5, dark: 0x5C4F_45)
  static let ink = Swatch(light: 0x262A_33, dark: 0xE3D1_BF)
  static let ink2 = Swatch(light: 0x4A4F_59, dark: 0xC8B7_A6)
  static let inkMuted = Swatch(light: 0x6B62_59, dark: 0xB09F_8F)
  static let claret = Swatch(light: 0x990F_3D, dark: 0xD28E_9B)
  static let oxford = Swatch(light: 0x0F54_99, dark: 0x7DA5_D2)
  static let jade = Swatch(light: 0x0073_3A, dark: 0x4DB3_7B)
  static let crimson = Swatch(light: 0xCC00_00, dark: 0xE885_7E)
  static let crimsonWash = Swatch(light: 0xFBDE_D3, dark: 0x3017_13)

  struct Swatch {
    let nsColor: NSColor

    fileprivate init(light lightHex: UInt32, dark darkHex: UInt32) {
      nsColor = NSColor(name: nil, dynamicProvider: { appearance in
        let match = appearance.bestMatch(from: [.aqua, .darkAqua])
        return srgb(match == .darkAqua ? darkHex : lightHex)
      })
    }

    /// `ColorScheme` ne fait que relancer le dessin : la couleur vient du `NSColor` dynamique.
    func resolve(_ scheme: ColorScheme) -> Color {
      let name: NSAppearance.Name = scheme == .dark ? .darkAqua : .aqua
      let appearance = NSAppearance(named: name) ?? .currentDrawing()
      var resolved = nsColor
      appearance.performAsCurrentDrawingAppearance {
        resolved = nsColor.usingColorSpace(.sRGB) ?? nsColor
      }
      return Color(nsColor: resolved)
    }
  }
}

private func srgb(_ hex: UInt32) -> NSColor {
  NSColor(
    srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
    green: CGFloat((hex >> 8) & 0xFF) / 255,
    blue: CGFloat(hex & 0xFF) / 255,
    alpha: 1
  )
}
