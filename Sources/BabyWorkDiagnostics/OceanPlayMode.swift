import AppKit
import BabyWorkDiagnosticsKit
import QuartzCore

enum OceanSprite {
  static func image(named name: String) -> NSImage? {
    oceanBundle.image(forResource: name)
      ?? oceanBundle.image(forResource: "\(name).png")
  }

  static func cgImage(named name: String) -> CGImage? {
    cache.image(named: name)
  }

  private static let cache = OceanSpriteCache()

  /// `Bundle.module` SPM cherche le `.bundle` à la racine du `.app`, interdit par codesign.
  /// Le script d’empaquetage le pose dans `Contents/Resources/`.
  private static let oceanBundle: Bundle = {
    let names = "BabyWork_BabyWorkDiagnostics.bundle"
    if let resources = Bundle.main.resourceURL {
      let packaged = resources.appendingPathComponent(names)
      if let bundle = Bundle(url: packaged) {
        return bundle
      }
    }
    return Bundle.module
  }()
}

private final class OceanSpriteCache: @unchecked Sendable {
  private let lock = NSLock()
  private var images: [String: CGImage] = [:]

  func image(named name: String) -> CGImage? {
    lock.lock()
    if let cached = images[name] {
      lock.unlock()
      return cached
    }
    lock.unlock()
    guard let image = OceanSprite.image(named: name) else { return nil }
    var rect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
      return nil
    }
    lock.lock()
    images[name] = cgImage
    lock.unlock()
    return cgImage
  }
}

/// Répartit le banc et le timer entre les écrans.
final class OceanDirector: @unchecked Sendable {
  static let displaySizeRange = 96.0...150.0

  private let lock = NSLock()
  private let sessionSalt: UInt64
  private var painters: [OceanPainter] = []
  private var school = OceanSchool()
  private var rng = SystemRandomNumberGenerator()
  private var spawnedInitial: Set<Int> = []
  private var ticker: Timer?
  private var lastTick: TimeInterval = 0

  init() {
    sessionSalt = UInt64.random(in: 1...UInt64.max)
  }

  func register(_ painter: OceanPainter) {
    lock.lock()
    let index = painters.count
    painters.append(painter)
    let shouldStart = ticker == nil
    lock.unlock()
    painter.attach(screenIndex: index, sessionSalt: sessionSalt)
    if shouldStart {
      startTicker()
    }
  }

  func reset() {
    lock.lock()
    painters.removeAll(keepingCapacity: false)
    school = OceanSchool()
    rng = SystemRandomNumberGenerator()
    spawnedInitial.removeAll(keepingCapacity: false)
    let timer = ticker
    ticker = nil
    lock.unlock()
    timer?.invalidate()
  }

  func spawnKeyFish() {
    lock.lock()
    let snapshot = painters
    lock.unlock()
    guard !snapshot.isEmpty else { return }
    let painter = snapshot[Int.random(in: 0..<snapshot.count)]
    let layout = painter.layoutSnapshot()
    guard layout.ready else { return }
    lock.lock()
    _ = school.spawnFish(
      screenIndex: layout.screenIndex,
      screenSize: layout.size,
      groundTop: layout.groundTop,
      displaySizeRange: Self.displaySizeRange,
      rng: &rng
    )
    lock.unlock()
  }

  func ensureInitialFish(for painter: OceanPainter) {
    let layout = painter.layoutSnapshot()
    guard layout.ready else { return }
    lock.lock()
    defer { lock.unlock() }
    guard !spawnedInitial.contains(layout.screenIndex) else { return }
    spawnedInitial.insert(layout.screenIndex)
    _ = school.spawnFish(
      screenIndex: layout.screenIndex,
      screenSize: layout.size,
      groundTop: layout.groundTop,
      displaySizeRange: Self.displaySizeRange,
      rng: &rng
    )
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
    let snapshot = painters
    lock.unlock()

    for painter in snapshot {
      ensureInitialFish(for: painter)
    }

    lock.lock()
    let widths = snapshot.map { Double($0.layoutSnapshot().size.width) }
    let result = school.tick(dt: dt, screenWidths: widths)
    lock.unlock()

    for painter in snapshot {
      painter.tick(dt: dt, fish: result.fish, removedIDs: result.removedIDs)
    }
  }
}

/// Dessin Core Animation hors isolation MainActor de `NSView`.
final class OceanPainter: @unchecked Sendable {
  static let cameraSpeed = 22.0
  static let bubblePeriod = 2.0...4.0
  static let fishBubblesPerEmit = 1...2
  static let clickBubbles = 1...3
  static let bubbleRiseSpeed = 50.0...80.0
  static let bubbleLifetime = 1.4...2.2
  static let bubbleDisplaySize = 24.0...48.0

  private let lock = NSLock()
  private let farHost: CALayer
  private let midHost: CALayer
  private let groundHost: CALayer
  private let foregroundHost: CALayer
  private let fishHost: CALayer
  private let bubbleHost: CALayer
  private var screenIndex = 0
  private var sessionSalt: UInt64 = 1
  private var bounds: CGRect = .zero
  private var contentsScale: CGFloat
  private var scenery: OceanScenery?
  private var propLayers: [CALayer] = []
  private var fishLayers: [UInt64: CALayer] = [:]
  private var bubbleEmitAt: [UInt64: TimeInterval] = [:]
  private var bubbles: [RisingBubble] = []

  init(
    farHost: CALayer,
    midHost: CALayer,
    groundHost: CALayer,
    foregroundHost: CALayer,
    fishHost: CALayer,
    bubbleHost: CALayer,
    contentsScale: CGFloat
  ) {
    self.farHost = farHost
    self.midHost = midHost
    self.groundHost = groundHost
    self.foregroundHost = foregroundHost
    self.fishHost = fishHost
    self.bubbleHost = bubbleHost
    self.contentsScale = contentsScale
  }

  func attach(screenIndex: Int, sessionSalt: UInt64) {
    lock.lock()
    self.screenIndex = screenIndex
    self.sessionSalt = sessionSalt
    lock.unlock()
  }

  func layoutSnapshot() -> OceanLayoutSnapshot {
    lock.lock()
    defer { lock.unlock() }
    return OceanLayoutSnapshot(
      screenIndex: screenIndex,
      size: bounds.size,
      groundTop: scenery?.groundTop ?? 0,
      ready: scenery != nil && bounds.width > 8 && bounds.height > 8
    )
  }

  func setBounds(_ bounds: CGRect, scale: CGFloat) {
    lock.lock()
    self.bounds = bounds
    self.contentsScale = scale
    var installed: OceanScenery?
    if scenery == nil, bounds.width > 8, bounds.height > 8 {
      var rng = SplitMix64(seed: scenerySeedLocked())
      let generated = OceanScenery.generate(bounds: bounds.size, rng: &rng)
      scenery = generated
      installed = generated
    }
    lock.unlock()

    let farHost = farHost
    let midHost = midHost
    let groundHost = groundHost
    let foregroundHost = foregroundHost
    let fishHost = fishHost
    let bubbleHost = bubbleHost
    runOnMain {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      farHost.contentsScale = scale
      midHost.contentsScale = scale
      groundHost.contentsScale = scale
      foregroundHost.contentsScale = scale
      fishHost.contentsScale = scale
      bubbleHost.contentsScale = scale
      farHost.frame = bounds
      midHost.frame = bounds
      groundHost.frame = bounds
      foregroundHost.frame = bounds
      fishHost.frame = bounds
      bubbleHost.frame = bounds
      CATransaction.commit()
    }
    if let installed {
      installPropLayers(installed)
    }
  }

  func tick(dt: Double, fish: [OceanFish], removedIDs: [UInt64]) {
    runOnMain { [weak self] in
      self?.tickOnMain(dt: dt, fish: fish, removedIDs: removedIDs)
    }
  }

  func spawnClickBubbles(at point: CGPoint, count: Int) {
    let clamped = min(
      Self.clickBubbles.upperBound,
      max(Self.clickBubbles.lowerBound, count)
    )
    runOnMain { [weak self] in
      guard let self else { return }
      for _ in 0..<clamped {
        self.addBubble(
          at: CGPoint(
            x: point.x + CGFloat.random(in: -10...10),
            y: point.y + CGFloat.random(in: -8...8)
          )
        )
      }
    }
  }

  private func tickOnMain(dt: Double, fish: [OceanFish], removedIDs: [UInt64]) {
    lock.lock()
    let screenIndex = screenIndex
    let scenery = scenery
    let bounds = bounds
    lock.unlock()

    CATransaction.begin()
    CATransaction.setDisableActions(true)

    if var scenery, bounds.width > 8 {
      scenery.scroll(cameraDelta: Self.cameraSpeed * dt, bounds: bounds.size)
      lock.lock()
      self.scenery = scenery
      let layers = propLayers
      lock.unlock()
      for (index, prop) in scenery.props.enumerated() where index < layers.count {
        layers[index].frame = frame(for: prop, scenery: scenery)
      }
    }

    for id in removedIDs {
      fishLayers[id]?.removeFromSuperlayer()
      fishLayers[id] = nil
      bubbleEmitAt[id] = nil
    }

    let now = ProcessInfo.processInfo.systemUptime
    let mine = fish.filter { $0.screenIndex == screenIndex }
    let living = Set(mine.map(\.id))
    for id in fishLayers.keys where !living.contains(id) {
      fishLayers[id]?.removeFromSuperlayer()
      fishLayers[id] = nil
      bubbleEmitAt[id] = nil
    }

    var appeared: [CALayer] = []
    for fish in mine {
      if fishLayers[fish.id] == nil {
        let layer = makeFishLayer(fish)
        fishLayers[fish.id] = layer
        appeared.append(layer)
      }
      fishLayers[fish.id]?.position = CGPoint(x: fish.x, y: fish.y)
      emitFishBubblesIfNeeded(fish: fish, now: now)
    }

    var kept: [RisingBubble] = []
    kept.reserveCapacity(bubbles.count)
    for var bubble in bubbles {
      bubble.age += dt
      guard bubble.age < bubble.lifetime else {
        bubble.layer.removeFromSuperlayer()
        continue
      }
      bubble.y += bubble.riseSpeed * dt
      bubble.layer.position = CGPoint(x: bubble.x, y: bubble.y)
      let fadeStart = bubble.lifetime * 0.45
      if bubble.age <= fadeStart {
        bubble.layer.opacity = 1
      } else {
        let fade = (bubble.age - fadeStart) / (bubble.lifetime - fadeStart)
        bubble.layer.opacity = Float(max(0, 1 - fade))
      }
      kept.append(bubble)
    }
    bubbles = kept

    CATransaction.commit()

    for layer in appeared {
      playAppearAnimation(on: layer)
    }
  }

  private func emitFishBubblesIfNeeded(fish: OceanFish, now: TimeInterval) {
    let deadline = bubbleEmitAt[fish.id] ?? now + Double.random(in: Self.bubblePeriod)
    if bubbleEmitAt[fish.id] == nil {
      bubbleEmitAt[fish.id] = deadline
    }
    guard now >= deadline else { return }
    bubbleEmitAt[fish.id] = now + Double.random(in: Self.bubblePeriod)
    let count = Int.random(in: Self.fishBubblesPerEmit)
    let headX = CGFloat(fish.x) + CGFloat(fish.displaySize) * 0.38
    let headY = CGFloat(fish.y) + CGFloat.random(in: -10...10)
    for _ in 0..<count {
      addBubble(
        at: CGPoint(
          x: headX + CGFloat.random(in: -6...6),
          y: headY
        )
      )
    }
  }

  private func addBubble(at point: CGPoint) {
    let name = ["bubble_a", "bubble_b", "bubble_c"].randomElement() ?? "bubble_a"
    let size = CGFloat.random(in: CGFloat(Self.bubbleDisplaySize.lowerBound)...CGFloat(Self.bubbleDisplaySize.upperBound))
    let layer = CALayer()
    layer.contents = OceanSprite.cgImage(named: name)
    layer.contentsGravity = .resizeAspect
    layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    layer.bounds = CGRect(x: 0, y: 0, width: size, height: size)
    layer.position = point
    bubbleHost.addSublayer(layer)
    bubbles.append(
      RisingBubble(
        layer: layer,
        x: point.x,
        y: point.y,
        riseSpeed: CGFloat.random(
          in: CGFloat(Self.bubbleRiseSpeed.lowerBound)...CGFloat(Self.bubbleRiseSpeed.upperBound)
        ),
        age: 0,
        lifetime: Double.random(in: Self.bubbleLifetime)
      )
    )
  }

  private func makeFishLayer(_ fish: OceanFish) -> CALayer {
    let size = CGFloat(fish.displaySize)
    let wrapper = CALayer()
    wrapper.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    wrapper.bounds = CGRect(x: 0, y: 0, width: size, height: size)
    wrapper.position = CGPoint(x: fish.x, y: fish.y)

    let sprite = CALayer()
    sprite.contents = OceanSprite.cgImage(named: "fish_\(fish.kind.rawValue)")
    sprite.contentsGravity = .resizeAspect
    sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    sprite.bounds = wrapper.bounds
    sprite.position = CGPoint(x: size / 2, y: size / 2)
    wrapper.addSublayer(sprite)
    fishHost.addSublayer(wrapper)
    return wrapper
  }

  private func playAppearAnimation(on layer: CALayer) {
    let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
    pulse.values = [0.35, 1.18, 0.92, 1.08, 1]
    pulse.keyTimes = [0, 0.18, 0.38, 0.62, 1]
    pulse.duration = 0.55
    pulse.timingFunction = CAMediaTimingFunction(name: .easeOut)
    layer.add(pulse, forKey: "appear")
  }

  private func installPropLayers(_ scenery: OceanScenery) {
    runOnMain { [weak self] in
      guard let self else { return }
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      for layer in self.propLayers {
        layer.removeFromSuperlayer()
      }
      var layers: [CALayer] = []
      layers.reserveCapacity(scenery.props.count)
      for prop in scenery.props {
        let layer = CALayer()
        layer.contents = OceanSprite.cgImage(named: prop.kind.assetName)
        layer.contentsGravity = Self.contentsGravity(for: prop)
        layer.allowsEdgeAntialiasing = false
        layer.zPosition = Self.zPosition(for: prop)
        layer.frame = self.frame(for: prop, scenery: scenery)
        self.host(for: prop.layer).addSublayer(layer)
        layers.append(layer)
      }
      CATransaction.commit()
      self.lock.lock()
      self.propLayers = layers
      self.lock.unlock()
    }
  }

  private func host(for layer: OceanLayer) -> CALayer {
    switch layer {
    case .far: farHost
    case .mid: midHost
    case .ground: groundHost
    case .foreground: foregroundHost
    }
  }

  private func frame(for prop: OceanProp, scenery: OceanScenery) -> CGRect {
    let x = snap(CGFloat(prop.x))
    let y = snap(CGFloat(prop.y))
    let tile = CGFloat(OceanScenery.tileStride)
    let name = prop.kind.assetName

    if name.hasPrefix("terrain_") {
      return CGRect(x: x, y: y, width: tile, height: tile)
    }

    if prop.layer == .foreground {
      // Les PNG ont du transparent en bas : enfoncer un peu dans le sable pour masquer la couture.
      let embed = CGFloat(40)
      return CGRect(x: x - tile / 2, y: y - embed, width: tile, height: tile)
    }
    return CGRect(x: x - tile / 2, y: y - tile / 2, width: tile, height: tile)
  }

  private func snap(_ value: CGFloat) -> CGFloat {
    let scale = max(contentsScale, 1)
    return (value * scale).rounded() / scale
  }

  private static func contentsGravity(for prop: OceanProp) -> CALayerContentsGravity {
    if prop.kind.assetName.hasPrefix("terrain_") {
      return .resize
    }
    return .resizeAspect
  }

  private static func zPosition(for prop: OceanProp) -> CGFloat {
    let name = prop.kind.assetName
    if name.hasPrefix("terrain_sand"), name.contains("_top_") { return 3 }
    if name.hasPrefix("terrain_dirt"), name.contains("_top_") { return 2 }
    if name.hasPrefix("terrain_dirt") { return 1 }
    if name.hasPrefix("terrain_sand") { return 0 }
    return 0
  }

  private func scenerySeedLocked() -> UInt64 {
    sessionSalt &+ UInt64(truncatingIfNeeded: screenIndex) &* 0x9E3779B97F4A7C15
  }
}

struct OceanLayoutSnapshot: Sendable {
  var screenIndex: Int
  var size: CGSize
  var groundTop: Double
  var ready: Bool
}

/// Fond marin, poissons mirroirés, bulles. Pas de SwiftUI (isolation MainActor).
final class OceanStageView: NSView {
  static let waterColor = NSColor(srgbRed: 126 / 255, green: 200 / 255, blue: 227 / 255, alpha: 1)

  private let inputBridge: KioskInputBridge
  private let director: OceanDirector
  private let painter: OceanPainter

  init(
    inputBridge: KioskInputBridge,
    director: OceanDirector,
    scale: CGFloat
  ) {
    self.inputBridge = inputBridge
    self.director = director
    let farHost = CALayer()
    let midHost = CALayer()
    let groundHost = CALayer()
    let foregroundHost = CALayer()
    let fishHost = CALayer()
    let bubbleHost = CALayer()
    farHost.zPosition = 0
    midHost.zPosition = 1
    groundHost.zPosition = 2
    foregroundHost.zPosition = 3
    fishHost.zPosition = 4
    bubbleHost.zPosition = 5
    self.painter = OceanPainter(
      farHost: farHost,
      midHost: midHost,
      groundHost: groundHost,
      foregroundHost: foregroundHost,
      fishHost: fishHost,
      bubbleHost: bubbleHost,
      contentsScale: scale
    )
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = Self.waterColor.cgColor
    layer?.contentsScale = scale
    layer?.addSublayer(farHost)
    layer?.addSublayer(midHost)
    layer?.addSublayer(groundHost)
    layer?.addSublayer(foregroundHost)
    layer?.addSublayer(fishHost)
    layer?.addSublayer(bubbleHost)

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

  override func layout() {
    super.layout()
    painter.setBounds(bounds, scale: window?.backingScaleFactor ?? 2)
    director.ensureInitialFish(for: painter)
  }

  nonisolated override var acceptsFirstResponder: Bool { true }
  nonisolated override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  nonisolated override func mouseDown(with event: NSEvent) {
    painter.spawnClickBubbles(
      at: event.locationInWindow,
      count: Int.random(in: OceanPainter.clickBubbles)
    )
  }

  nonisolated override func keyDown(with event: NSEvent) {
    let code = UInt16(event.keyCode)
    let isReturn = code == 0x24 || code == 0x4C
    let isEscape = code == 0x35
    let shiftDown = event.modifierFlags.contains(.shift)
    let ignoring = event.charactersIgnoringModifiers ?? ""
    let letter = ignoring.lowercased().first { $0.isLetter }
      ?? KeyboardLayoutLetter.shared.fromKeyCode(code)
    inputBridge.noteKeyDown(
      letter: letter,
      isReturn: isReturn,
      isEscape: isEscape,
      shiftDown: shiftDown
    )
    director.spawnKeyFish()
  }
}

private struct RisingBubble {
  let layer: CALayer
  var x: CGFloat
  var y: CGFloat
  let riseSpeed: CGFloat
  var age: Double
  let lifetime: Double
}

private struct SplitMix64: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed
  }

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var z = state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
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
