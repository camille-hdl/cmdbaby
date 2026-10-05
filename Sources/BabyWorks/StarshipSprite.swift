import AppKit

/// Images Kenney du mode Vaisseau, un `CGImage` par nom pour toute la session.
@MainActor
enum StarshipSprite {
  static func image(named name: String) -> NSImage? {
    ResourceBundle.shared.image(forResource: name)
      ?? ResourceBundle.shared.image(forResource: "\(name).png")
  }

  static func cgImage(named name: String) -> CGImage? {
    if let cached = cache[name] {
      return cached
    }
    guard let image = image(named: name) else { return nil }
    var rect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
      return nil
    }
    cache[name] = cgImage
    return cgImage
  }

  static func purge() {
    cache.removeAll(keepingCapacity: false)
  }

  private static var cache: [String: CGImage] = [:]
}
