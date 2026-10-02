import AppKit
import BabyWorkDiagnosticsKit
import QuartzCore

/// Répartit les glyphes clavier et la vitesse de défilement entre les écrans.
@MainActor
final class GalaxyDirector {
  private var painters: [GalaxyPainter] = []
  private var drive = WarpDrive()
  private var ticker: Timer?
  private var lastTick: TimeInterval = 0

  func register(_ painter: GalaxyPainter) {
    painters.append(painter)
    let shouldStart = ticker == nil
    if shouldStart {
      startTicker()
    }
  }

  func reset() {
    painters.removeAll(keepingCapacity: false)
    drive = WarpDrive()
    let timer = ticker
    ticker = nil
    timer?.invalidate()
  }

  func spawnKeyGlyph(_ glyph: PlayGlyph) {
    drive.impulse(at: ProcessInfo.processInfo.systemUptime)
    let snapshot = painters
    guard !snapshot.isEmpty else { return }
    snapshot[Int.random(in: 0..<snapshot.count)].spawnGlyph(glyph, at: nil)
  }

  private func startTicker() {
    guard ticker == nil else { return }
    lastTick = ProcessInfo.processInfo.systemUptime
    let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.tick()
      }
    }
    ticker = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  private func tick() {
    let now = ProcessInfo.processInfo.systemUptime
    let dt = lastTick == 0 ? 1.0 / 60.0 : min(0.05, max(1.0 / 120.0, now - lastTick))
    lastTick = now
    drive.tick(now: now, dt: dt)
    let speed = drive.speed
    let snapshot = painters
    for painter in snapshot {
      painter.tickWarp(dt: dt, speed: speed)
    }
  }
}

/// Dessin Core Animation de la scène galaxie.
@MainActor
final class GalaxyPainter {
  private let glyphHost: CALayer
  private let starHost: CALayer
  private let warpHost: CALayer
  private var glyphLayers: [CALayer] = []
  private var starLayers: [CALayer] = []
  private var warpStars: [WarpStar] = []
  private var lastStarPoint: CGPoint?
  private var bounds: CGRect = .zero
  private var contentsScale: CGFloat

  init(glyphHost: CALayer, starHost: CALayer, warpHost: CALayer, contentsScale: CGFloat) {
    self.glyphHost = glyphHost
    self.starHost = starHost
    self.warpHost = warpHost
    self.contentsScale = contentsScale
  }

  func setBounds(_ bounds: CGRect, scale: CGFloat) {
    self.bounds = bounds
    self.contentsScale = scale
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    glyphHost.frame = bounds
    starHost.frame = bounds
    warpHost.frame = bounds
    CATransaction.commit()
    populateWarpFieldIfNeeded()
  }

  func tickWarp(dt: TimeInterval, speed: Double) {
    advanceWarpField(dt: dt, speed: speed)
  }

  func spawnGlyph(_ glyph: PlayGlyph, at point: CGPoint?) {
    let text = glyph.displayText
    let fontSize: CGFloat = {
      if case .emoji = glyph { return 96 }
      return 110
    }()
    let origin = point ?? randomPoint(padding: 90)
    addAnimatedText(
      text,
      at: origin,
      fontSize: fontSize,
      host: glyphHost,
      isGlyph: true,
      cap: 36,
      lifetime: 2.8
    )
  }

  func spawnStar(at point: CGPoint) {
    if let last = lastStarPoint, hypot(point.x - last.x, point.y - last.y) < 22 {
      return
    }
    lastStarPoint = point
    let star = ["✦", "✧", "★", "⋆"].randomElement() ?? "✦"
    addAnimatedText(
      star,
      at: point,
      fontSize: 22,
      host: starHost,
      isGlyph: false,
      cap: 48,
      lifetime: 0.7
    )
  }

  private func populateWarpFieldIfNeeded() {
    guard warpStars.isEmpty, bounds.width > 8, bounds.height > 8 else { return }
    let maxRadius = hypot(bounds.width, bounds.height) * 0.55
    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let scale = contentsScale
    var stars: [WarpStar] = []
    for _ in 0..<16 {
      stars.append(
        makeWarpStar(
          maxRadius: maxRadius,
          scale: scale,
          center: center,
          seedNearCenter: false
        )
      )
    }
    warpStars = stars
  }

  private func advanceWarpField(dt: TimeInterval, speed: Double) {
    guard bounds.width > 8, !warpStars.isEmpty else { return }

    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let maxRadius = hypot(bounds.width, bounds.height) * 0.55
    let scale = contentsScale
    var stars = warpStars
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    for index in stars.indices {
      stars[index].radius += speed * (22 + stars[index].radius * 2.4) * dt
      if stars[index].radius > maxRadius {
        stars[index].recycle(scale: scale)
      }
      stars[index].apply(center: center, scale: scale)
    }
    CATransaction.commit()
    warpStars = stars
  }

  private func makeWarpStar(
    maxRadius: CGFloat,
    scale: CGFloat,
    center: CGPoint,
    seedNearCenter: Bool
  ) -> WarpStar {
    let roll = Double.random(in: 0..<1)
    let emoji = WarpFieldCatalog.emoji(
      roll: roll,
      starIndex: Int.random(in: 0..<WarpFieldCatalog.stars.count),
      rareIndex: Int.random(in: 0..<WarpFieldCatalog.rare.count)
    )
    let isRare = roll < WarpFieldCatalog.rareProbability
    let wrapper = CALayer()
    let label = CATextLayer()
    label.string = emoji
    label.alignmentMode = .center
    label.contentsScale = scale
    label.font = NSFont(name: "Apple Color Emoji", size: isRare ? 54 : 36)
      ?? NSFont.systemFont(ofSize: 36)
    label.foregroundColor = NSColor.white.cgColor
    wrapper.addSublayer(label)
    warpHost.addSublayer(wrapper)
    let star = WarpStar(
      angle: Double.random(in: 0..<(2 * .pi)),
      radius: seedNearCenter ? Double.random(in: 6...28) : Double.random(in: 8...Double(maxRadius) * 0.9),
      emoji: emoji,
      isRare: isRare,
      wrapper: wrapper,
      label: label
    )
    star.apply(center: center, scale: scale)
    return star
  }

  private func addAnimatedText(
    _ text: String,
    at point: CGPoint,
    fontSize: CGFloat,
    host: CALayer,
    isGlyph: Bool,
    cap: Int,
    lifetime: CFTimeInterval
  ) {
    if isGlyph {
      while glyphLayers.count >= cap {
        glyphLayers.removeFirst().removeFromSuperlayer()
      }
    } else {
      while starLayers.count >= cap {
        starLayers.removeFirst().removeFromSuperlayer()
      }
    }
    let scale = contentsScale

    let size = fontSize * 1.6
    let wrapper = CALayer()
    wrapper.frame = CGRect(
      x: point.x - size / 2,
      y: point.y - size / 2,
      width: size,
      height: size
    )
    wrapper.zPosition = 10

    let label = CATextLayer()
    label.string = text
    label.alignmentMode = .center
    label.contentsScale = scale
    if text.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
      label.font = NSFont(name: "Apple Color Emoji", size: fontSize)
        ?? NSFont.systemFont(ofSize: fontSize)
    } else {
      label.font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
    }
    label.fontSize = fontSize
    label.foregroundColor = NSColor.white.cgColor
    label.frame = wrapper.bounds
    wrapper.addSublayer(label)
    host.addSublayer(wrapper)

    if isGlyph {
      glyphLayers.append(wrapper)
    } else {
      starLayers.append(wrapper)
    }

    let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
    pulse.values = [0.35, 1.18, 0.92, 1.08, 1]
    pulse.keyTimes = [0, 0.18, 0.38, 0.62, 1]
    pulse.duration = min(1.1, lifetime * 0.55)
    pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1
    fade.toValue = 0
    fade.beginTime = lifetime * 0.55
    fade.duration = lifetime * 0.45
    fade.fillMode = .forwards
    fade.isRemovedOnCompletion = false

    let group = CAAnimationGroup()
    group.animations = [pulse, fade]
    group.duration = lifetime
    group.fillMode = .forwards
    group.isRemovedOnCompletion = false
    wrapper.add(group, forKey: "play")

    DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) { [weak self, weak wrapper] in
      MainActor.assumeIsolated {
        guard let self, let wrapper else { return }
        wrapper.removeFromSuperlayer()
        self.glyphLayers.removeAll { $0 === wrapper }
        self.starLayers.removeAll { $0 === wrapper }
      }
    }
  }

  private func randomPoint(padding: CGFloat) -> CGPoint {
    let inset = bounds.insetBy(dx: padding, dy: padding)
    guard inset.width > 8, inset.height > 8 else {
      return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    return CGPoint(
      x: CGFloat.random(in: inset.minX...inset.maxX),
      y: CGFloat.random(in: inset.minY...inset.maxY)
    )
  }
}

private struct WarpStar {
  var angle: Double
  var radius: Double
  var emoji: String
  var isRare: Bool
  let wrapper: CALayer
  let label: CATextLayer

  mutating func recycle(scale: CGFloat) {
    angle = Double.random(in: 0..<(2 * .pi))
    radius = Double.random(in: 8...36)
    let roll = Double.random(in: 0..<1)
    emoji = WarpFieldCatalog.emoji(
      roll: roll,
      starIndex: Int.random(in: 0..<WarpFieldCatalog.stars.count),
      rareIndex: Int.random(in: 0..<WarpFieldCatalog.rare.count)
    )
    isRare = roll < WarpFieldCatalog.rareProbability
    label.string = emoji
    label.contentsScale = scale
  }

  func apply(center: CGPoint, scale: CGFloat) {
    let x = center.x + CGFloat(cos(angle)) * CGFloat(radius)
    let y = center.y + CGFloat(sin(angle)) * CGFloat(radius)
    let growth = 0.22 + CGFloat(radius) / 260
    let fontSize: CGFloat = (isRare ? 48 : 30) * growth
    let box = fontSize * 1.8
    wrapper.frame = CGRect(x: x - box / 2, y: y - box / 2, width: box, height: box)
    wrapper.opacity = Float(min(0.92, 0.08 + radius / 160))
    label.frame = wrapper.bounds
    label.fontSize = fontSize
    label.contentsScale = scale
    label.font = NSFont(name: "Apple Color Emoji", size: fontSize)
      ?? NSFont.systemFont(ofSize: fontSize)
  }
}

/// Enveloppe `GalaxyDirector` et la palette de fonds.
@MainActor
final class GalaxyPlayMode: PlayMode {
  private let director = GalaxyDirector()

  func windowBackground(screenIndex: Int) -> NSColor {
    CoverPalette.color(at: screenIndex)
  }

  func makeStage(inputBridge: KioskInputBridge, screenIndex: Int, scale: CGFloat) -> NSView {
    GalaxyStageView(
      background: windowBackground(screenIndex: screenIndex),
      inputBridge: inputBridge,
      director: director,
      scale: scale
    )
  }

  func reset() {
    director.reset()
  }
}

private enum CoverPalette {
  private static let colors: [NSColor] = [
    NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.18, alpha: 1),
    NSColor(calibratedRed: 0.12, green: 0.04, blue: 0.20, alpha: 1),
    NSColor(calibratedRed: 0.03, green: 0.14, blue: 0.18, alpha: 1),
  ]

  static func color(at index: Int) -> NSColor {
    colors[index % colors.count]
  }
}

/// Fond uni, lettres / emojis animés, traînée d’étoiles. Pas de SwiftUI (isolation MainActor).
final class GalaxyStageView: NSView {
  private let inputBridge: KioskInputBridge
  private let director: GalaxyDirector
  private let painter: GalaxyPainter
  private var trackingArea: NSTrackingArea?

  init(
    background: NSColor,
    inputBridge: KioskInputBridge,
    director: GalaxyDirector,
    scale: CGFloat
  ) {
    self.inputBridge = inputBridge
    self.director = director
    let glyphHost = CALayer()
    let starHost = CALayer()
    let warpHost = CALayer()
    warpHost.zPosition = 0
    starHost.zPosition = 1
    glyphHost.zPosition = 2
    self.painter = GalaxyPainter(
      glyphHost: glyphHost,
      starHost: starHost,
      warpHost: warpHost,
      contentsScale: scale
    )
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = background.cgColor
    layer?.contentsScale = scale
    layer?.addSublayer(warpHost)
    layer?.addSublayer(starHost)
    layer?.addSublayer(glyphHost)
    director.register(painter)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) n’est pas supporté")
  }

  override func updateTrackingAreas() {
    super.updateTrackingAreas()
    if let trackingArea {
      removeTrackingArea(trackingArea)
    }
    let area = NSTrackingArea(
      rect: bounds,
      options: [.mouseMoved, .activeAlways, .inVisibleRect],
      owner: self,
      userInfo: nil
    )
    trackingArea = area
    addTrackingArea(area)
  }

  override func layout() {
    super.layout()
    painter.setBounds(bounds, scale: window?.backingScaleFactor ?? 2)
  }

  override var acceptsFirstResponder: Bool { true }
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  override func mouseDown(with event: NSEvent) {
    let point = event.locationInWindow
    painter.spawnGlyph(
      PlayGlyphResolver.glyph(
        fromVisibleCharacter: nil,
        emojiIndex: Int.random(in: 0..<PlayGlyphResolver.emojis.count)
      ),
      at: point
    )
  }

  override func mouseMoved(with event: NSEvent) {
    painter.spawnStar(at: event.locationInWindow)
  }

  override func mouseDragged(with event: NSEvent) {
    painter.spawnStar(at: event.locationInWindow)
  }

  override func keyDown(with event: NSEvent) {
    let code = UInt16(event.keyCode)
    let isReturn = code == 0x24 || code == 0x4C
    let isEscape = code == 0x35
    let shiftDown = event.modifierFlags.contains(.shift)
    let ignoring = event.charactersIgnoringModifiers ?? ""
    let raw = event.characters ?? ""
    let letter = ignoring.lowercased().first { $0.isLetter }
      ?? KeyboardLayoutLetter.shared.fromKeyCode(code)
    inputBridge.noteKeyDown(
      letter: letter,
      isReturn: isReturn,
      isEscape: isEscape,
      shiftDown: shiftDown
    )
    let visible = ignoring.first(where: { $0.isLetter || $0.isNumber })
      ?? raw.first(where: { $0.isLetter || $0.isNumber })
      ?? letter
    let glyph = PlayGlyphResolver.glyph(
      fromVisibleCharacter: visible,
      emojiIndex: Int.random(in: 0..<PlayGlyphResolver.emojis.count)
    )
    director.spawnKeyGlyph(glyph)
  }
}
