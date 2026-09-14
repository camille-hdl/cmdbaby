import AppKit
import BabyWorkDiagnosticsKit
import QuartzCore

/// Répartit les glyphes clavier et la vitesse de défilement entre les écrans.
final class GalaxyDirector: @unchecked Sendable {
  private let lock = NSLock()
  private var painters: [GalaxyPainter] = []
  private var drive = WarpDrive()
  private var ticker: Timer?
  private var lastTick: TimeInterval = 0

  func register(_ painter: GalaxyPainter) {
    lock.lock()
    painters.append(painter)
    let shouldStart = ticker == nil
    lock.unlock()
    if shouldStart {
      startTicker()
    }
  }

  func reset() {
    lock.lock()
    painters.removeAll(keepingCapacity: false)
    drive = WarpDrive()
    let timer = ticker
    ticker = nil
    lock.unlock()
    timer?.invalidate()
  }

  func spawnKeyGlyph(_ glyph: PlayGlyph) {
    lock.lock()
    drive.impulse(at: ProcessInfo.processInfo.systemUptime)
    let snapshot = painters
    lock.unlock()
    guard !snapshot.isEmpty else { return }
    snapshot[Int.random(in: 0..<snapshot.count)].spawnGlyph(glyph, at: nil)
  }

  private func startTicker() {
    lock.lock()
    guard ticker == nil else {
      lock.unlock()
      return
    }
    lastTick = ProcessInfo.processInfo.systemUptime
    let hop = MainHop { [weak self] in
      self?.tick()
    }
    let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { _ in
      hop.work()
    }
    ticker = timer
    lock.unlock()
    RunLoop.main.add(timer, forMode: .common)
  }

  private func tick() {
    let now = ProcessInfo.processInfo.systemUptime
    lock.lock()
    let dt = lastTick == 0 ? 1.0 / 60.0 : min(0.05, max(1.0 / 120.0, now - lastTick))
    lastTick = now
    drive.tick(now: now, dt: dt)
    let speed = drive.speed
    let snapshot = painters
    lock.unlock()
    for painter in snapshot {
      painter.tickWarp(dt: dt, speed: speed)
    }
  }
}

/// Dessin Core Animation hors isolation MainActor de `NSView`.
final class GalaxyPainter: @unchecked Sendable {
  private let lock = NSLock()
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
    lock.lock()
    self.bounds = bounds
    self.contentsScale = scale
    lock.unlock()
    let glyphHost = glyphHost
    let starHost = starHost
    let warpHost = warpHost
    runOnMain {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      glyphHost.frame = bounds
      starHost.frame = bounds
      warpHost.frame = bounds
      CATransaction.commit()
    }
    populateWarpFieldIfNeeded()
  }

  func tickWarp(dt: TimeInterval, speed: Double) {
    runOnMain { [weak self] in
      self?.advanceWarpField(dt: dt, speed: speed)
    }
  }

  func spawnGlyph(_ glyph: PlayGlyph, at point: CGPoint?) {
    let text = glyph.displayText
    let fontSize: CGFloat = {
      if case .emoji = glyph { return 96 }
      return 110
    }()
    runOnMain { [weak self] in
      guard let self else { return }
      let origin = point ?? self.randomPointLocked(padding: 90)
      self.addAnimatedText(
        text,
        at: origin,
        fontSize: fontSize,
        host: self.glyphHost,
        isGlyph: true,
        cap: 36,
        lifetime: 2.8
      )
    }
  }

  func spawnStar(at point: CGPoint) {
    runOnMain { [weak self] in
      guard let self else { return }
      self.lock.lock()
      if let last = self.lastStarPoint, hypot(point.x - last.x, point.y - last.y) < 22 {
        self.lock.unlock()
        return
      }
      self.lastStarPoint = point
      self.lock.unlock()
      let star = ["✦", "✧", "★", "⋆"].randomElement() ?? "✦"
      self.addAnimatedText(
        star,
        at: point,
        fontSize: 22,
        host: self.starHost,
        isGlyph: false,
        cap: 48,
        lifetime: 0.7
      )
    }
  }

  private func populateWarpFieldIfNeeded() {
    runOnMain { [weak self] in
      guard let self else { return }
      self.lock.lock()
      let already = !self.warpStars.isEmpty
      let bounds = self.bounds
      let scale = self.contentsScale
      self.lock.unlock()
      guard !already, bounds.width > 8, bounds.height > 8 else { return }
      let maxRadius = hypot(bounds.width, bounds.height) * 0.55
      let center = CGPoint(x: bounds.midX, y: bounds.midY)
      var stars: [WarpStar] = []
      for _ in 0..<16 {
        stars.append(
          self.makeWarpStar(
            maxRadius: maxRadius,
            scale: scale,
            center: center,
            seedNearCenter: false
          )
        )
      }
      self.lock.lock()
      self.warpStars = stars
      self.lock.unlock()
    }
  }

  private func advanceWarpField(dt: TimeInterval, speed: Double) {
    lock.lock()
    let bounds = bounds
    let scale = contentsScale
    var stars = warpStars
    lock.unlock()
    guard bounds.width > 8, !stars.isEmpty else { return }

    let center = CGPoint(x: bounds.midX, y: bounds.midY)
    let maxRadius = hypot(bounds.width, bounds.height) * 0.55
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
    lock.lock()
    warpStars = stars
    lock.unlock()
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
    lock.lock()
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
    lock.unlock()

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

    lock.lock()
    if isGlyph {
      glyphLayers.append(wrapper)
    } else {
      starLayers.append(wrapper)
    }
    lock.unlock()

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

    let hop = MainHop { [weak self, weak wrapper] in
      guard let self, let wrapper else { return }
      wrapper.removeFromSuperlayer()
      self.lock.lock()
      self.glyphLayers.removeAll { $0 === wrapper }
      self.starLayers.removeAll { $0 === wrapper }
      self.lock.unlock()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + lifetime) {
      hop.work()
    }
  }

  private func randomPointLocked(padding: CGFloat) -> CGPoint {
    lock.lock()
    let bounds = bounds
    lock.unlock()
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

    let failsafe = FailsafeClickView(inputBridge: inputBridge)
    failsafe.translatesAutoresizingMaskIntoConstraints = false
    addSubview(failsafe)
    NSLayoutConstraint.activate([
      failsafe.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      failsafe.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
      failsafe.widthAnchor.constraint(equalToConstant: 72),
      failsafe.heightAnchor.constraint(equalToConstant: 72),
    ])
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

  nonisolated override var acceptsFirstResponder: Bool { true }
  nonisolated override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  nonisolated override func mouseDown(with event: NSEvent) {
    let point = event.locationInWindow
    painter.spawnGlyph(
      PlayGlyphResolver.glyph(
        fromVisibleCharacter: nil,
        emojiIndex: Int.random(in: 0..<PlayGlyphResolver.emojis.count)
      ),
      at: point
    )
  }

  nonisolated override func mouseMoved(with event: NSEvent) {
    painter.spawnStar(at: event.locationInWindow)
  }

  nonisolated override func mouseDragged(with event: NSEvent) {
    painter.spawnStar(at: event.locationInWindow)
  }

  nonisolated override func keyDown(with event: NSEvent) {
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

private struct MainHop: @unchecked Sendable {
  let work: () -> Void
}

private func runOnMain(_ work: @escaping () -> Void) {
  if Thread.isMainThread {
    work()
  } else {
    let hop = MainHop(work: work)
    DispatchQueue.main.async {
      hop.work()
    }
  }
}
