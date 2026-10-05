import AppKit
import BabyWorkDiagnosticsKit
import CoreText
import os
import QuartzCore

private let terminalLog = Logger(subsystem: "fr.camille.babywork", category: "Terminal")

/// Un par session, partagé entre les écrans. Un seul prompt, sur le plus grand écran.
@MainActor
final class TerminalDirector {
  private struct ScreenSlot {
    var index: Int
    var frame: CGRect?
    var painter: TerminalPainter
  }

  private struct FallingColumn {
    var id: Int
    var screenIndex: Int
    var column: TerminalRainColumn
  }

  let tuning: TerminalRainTuning
  let atlas = TerminalGlyphAtlas()

  private var screens: [ScreenSlot] = []
  private var columns: [FallingColumn] = []
  private var nextColumnID = 0
  private var prompt = TerminalPrompt()
  private var promptScreenIndex: Int?
  private var cursorOn = true
  private var blinkTimer: Timer?
  private var rainTimer: Timer?
  private var lastRainTick: TimeInterval = 0
  private var promptFont: NSFont?

  init(tuning: TerminalRainTuning = .standard) {
    self.tuning = tuning
  }

  func register(screenIndex: Int, painter: TerminalPainter) {
    screens.append(ScreenSlot(index: screenIndex, frame: nil, painter: painter))
    if blinkTimer == nil {
      scheduleBlink()
    }
    choosePromptScreenIfReady()
  }

  func noteFrame(screenIndex: Int, frame: CGRect) {
    guard let slot = screens.firstIndex(where: { $0.index == screenIndex }) else { return }
    screens[slot].frame = frame
    choosePromptScreenIfReady()
  }

  /// Reçoit la frappe. La demande de pluie est ignorée : le ticket #58 la branchera.
  func handleKey(_ event: NSEvent) {
    cursorOn = true
    scheduleBlink()
    let code = event.keyCode
    if code == Self.deleteBackwardCode {
      prompt.deleteBackward()
      publish()
      return
    }
    if code == Self.returnCode || code == Self.keypadEnterCode {
      _ = prompt.submit()
      publish()
      shakePromptScreen()
      return
    }
    for character in event.characters ?? "" where Self.acceptsPromptCharacter(character) {
      _ = prompt.type(character)
    }
    publish()
  }

  /// Fait tomber une colonne sur l’écran cliqué. Ignorée si le plafond de colonnes est atteint.
  func spawnColumn(atGlobalX x: Double, screenIndex: Int) {
    guard columns.count < tuning.maxActiveColumns else { return }
    guard let frame = screens.first(where: { $0.index == screenIndex })?.frame else { return }
    let id = nextColumnID
    nextColumnID += 1
    columns.append(
      FallingColumn(
        id: id,
        screenIndex: screenIndex,
        column: TerminalRainColumn(
          x: TerminalStyle.snapToGrid(x: x),
          topY: Double(frame.maxY),
          floorY: Double(frame.minY),
          stepInterval: tuning.stepInterval(roll: Double.random(in: 0..<1)),
          trailLifetime: tuning.trailLifetime(roll: Double.random(in: 0..<1))
        )
      )
    )
    startRainTicker()
  }

  func reset() {
    let timer = blinkTimer
    blinkTimer = nil
    timer?.invalidate()
    stopRainTicker()
    columns.removeAll(keepingCapacity: false)
    for slot in screens {
      slot.painter.teardown()
    }
    screens.removeAll(keepingCapacity: false)
    atlas.reset()
    prompt = TerminalPrompt()
    promptScreenIndex = nil
    cursorOn = true
    promptFont = nil
  }

  private func choosePromptScreenIfReady() {
    let framed: [TerminalScreen] = screens.compactMap { slot in
      guard let frame = slot.frame else { return nil }
      return TerminalScreen(
        index: slot.index,
        x: Double(frame.origin.x),
        y: Double(frame.origin.y),
        width: Double(frame.size.width),
        height: Double(frame.size.height)
      )
    }
    guard framed.count == screens.count else { return }
    guard let index = TerminalScreenLayout.largestScreenIndex(framed) else { return }
    guard index != promptScreenIndex else { return }
    promptScreenIndex = index
    publish()
  }

  private func publish() {
    let font = resolvedPromptFont()
    for slot in screens {
      if slot.index == promptScreenIndex {
        slot.painter.show(text: prompt.text, cursorOn: cursorOn, font: font)
      } else {
        slot.painter.hide()
      }
    }
  }

  private func shakePromptScreen() {
    guard let promptScreenIndex else { return }
    screens.first { $0.index == promptScreenIndex }?.painter.shake()
  }

  private func scheduleBlink() {
    blinkTimer?.invalidate()
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.blink()
      }
    }
    blinkTimer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  private func blink() {
    cursorOn.toggle()
    publish()
  }

  private func startRainTicker() {
    guard rainTimer == nil else { return }
    lastRainTick = ProcessInfo.processInfo.systemUptime
    let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.tickRain()
      }
    }
    rainTimer = timer
    RunLoop.main.add(timer, forMode: .common)
  }

  private func stopRainTicker() {
    let timer = rainTimer
    rainTimer = nil
    timer?.invalidate()
    lastRainTick = 0
  }

  private func tickRain() {
    let now = ProcessInfo.processInfo.systemUptime
    let dt = lastRainTick == 0 ? 1.0 / 60.0 : min(0.05, max(1.0 / 120.0, now - lastRainTick))
    lastRainTick = now

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    var index = 0
    while index < columns.count {
      let spawned = columns[index].column.advance(by: dt)
      let column = columns[index]
      if let painter = screens.first(where: { $0.index == column.screenIndex })?.painter {
        for bottomY in spawned {
          painter.addCell(
            columnID: column.id,
            atGlobalX: column.column.x,
            bottomY: bottomY,
            trailLifetime: column.column.trailLifetime,
            now: now
          )
        }
        if column.column.isFinished {
          painter.releaseColumnHead(columnID: column.id)
        }
      }
      if columns[index].column.isFinished {
        columns.remove(at: index)
      } else {
        index += 1
      }
    }
    for slot in screens {
      slot.painter.tick(now: now)
    }
    CATransaction.commit()
  }

  private func resolvedPromptFont() -> NSFont {
    if let promptFont { return promptFont }
    let size = CGFloat(TerminalStyle.promptFontSize)
    let font = TerminalStyle.promptFontNames.compactMap { NSFont(name: $0, size: size) }.first
      ?? NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
    promptFont = font
    terminalLog.notice("police du prompt : \(font.fontName, privacy: .public)")
    return font
  }

  private static let deleteBackwardCode: UInt16 = 0x33
  private static let returnCode: UInt16 = 0x24
  private static let keypadEnterCode: UInt16 = 0x4C

  /// Espace accepté. Contrôles et touches de fonction Apple (`U+F700…U+F8FF`) ignorés.
  private static func acceptsPromptCharacter(_ character: Character) -> Bool {
    let functionKeys: ClosedRange<UInt32> = 0xF700...0xF8FF
    return character.unicodeScalars.allSatisfy { scalar in
      scalar.properties.generalCategory != .control && !functionKeys.contains(scalar.value)
    }
  }
}

/// Images de glyphes pré-rendues, partagées par les écrans de même échelle.
@MainActor
final class TerminalGlyphAtlas {
  struct Frames {
    var trail: [CGImage]
    var head: [CGImage]
  }

  private var cache: [CGFloat: Frames] = [:]
  private var didLogFont = false

  func frames(at scale: CGFloat) -> Frames {
    let key = scale > 0 ? scale : 2
    if let cached = cache[key] { return cached }
    let rendered = Self.render(scale: key, font: rainFont(size: CGFloat(TerminalStyle.cellHeight)))
    cache[key] = rendered
    return rendered
  }

  func reset() {
    cache.removeAll()
    didLogFont = false
  }

  private func rainFont(size: CGFloat) -> NSFont {
    let names = ["HiraginoSans-W3", "Hiragino Sans W3"]
    let font = names.compactMap { NSFont(name: $0, size: size) }.first
      ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    if !didLogFont {
      didLogFont = true
      terminalLog.notice("police de la pluie : \(font.fontName, privacy: .public)")
    }
    return font
  }

  private static func render(scale: CGFloat, font: NSFont) -> Frames {
    var trail: [CGImage] = []
    var head: [CGImage] = []
    trail.reserveCapacity(TerminalGlyphCatalog.glyphs.count)
    head.reserveCapacity(TerminalGlyphCatalog.glyphs.count)
    for glyph in TerminalGlyphCatalog.glyphs {
      guard
        let trailImage = image(
          glyph: glyph,
          font: font,
          scale: scale,
          fill: TerminalStyle.trail,
          glow: TerminalStyle.trail,
          blur: TerminalStyle.glowBlur
        ),
        let headImage = image(
          glyph: glyph,
          font: font,
          scale: scale,
          fill: TerminalStyle.head,
          glow: TerminalStyle.headGlow,
          blur: TerminalStyle.headGlowBlur
        )
      else { continue }
      trail.append(trailImage)
      head.append(headImage)
    }
    return Frames(trail: trail, head: head)
  }

  /// Deux passes : lueur puis glyphe net, en miroir horizontal. Fond transparent.
  private static func image(
    glyph: Character,
    font: NSFont,
    scale: CGFloat,
    fill: TerminalStyle.SRGB,
    glow: TerminalStyle.SRGB,
    blur: Double
  ) -> CGImage? {
    let size = terminalGlyphImageSize()
    let width = size.width
    let height = size.height
    let pixelsWide = max(Int((width * scale).rounded(.up)), 1)
    let pixelsHigh = max(Int((height * scale).rounded(.up)), 1)
    guard
      let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
      let ctx = CGContext(
        data: nil,
        width: pixelsWide,
        height: pixelsHigh,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return nil }

    ctx.scaleBy(x: scale, y: scale)
    ctx.translateBy(x: width, y: 0)
    ctx.scaleBy(x: -1, y: 1)

    let soft = line(glyph, font: font, color: fill.nsColor(alpha: 0.9))
    let sharp = line(glyph, font: font, color: fill.nsColor(alpha: 1))
    var ascent: CGFloat = 0
    var descent: CGFloat = 0
    let lineWidth = CGFloat(CTLineGetTypographicBounds(sharp, &ascent, &descent, nil))
    let origin = CGPoint(
      x: (width - lineWidth) / 2,
      y: (height - ascent - descent) / 2 + descent
    )

    ctx.setShadow(offset: .zero, blur: blur, color: glow.nsColor.cgColor)
    ctx.textPosition = origin
    CTLineDraw(soft, ctx)
    ctx.setShadow(offset: .zero, blur: 0, color: nil)
    ctx.textPosition = origin
    CTLineDraw(sharp, ctx)
    return ctx.makeImage()
  }

  private static func line(_ glyph: Character, font: NSFont, color: NSColor) -> CTLine {
    let text = NSAttributedString(
      string: String(glyph),
      attributes: [.font: font, .foregroundColor: color]
    )
    return CTLineCreateWithAttributedString(text)
  }
}

/// Calques du prompt et de la pluie d’un écran.
@MainActor
final class TerminalPainter {
  private static let horizontalInset: CGFloat = 96
  private static let measurementSpan: CGFloat = 100_000
  private static let shakeKey = "terminalShake"
  private static let fadeKey = "terminalFade"

  @MainActor
  private final class RainCell {
    let layer: CALayer
    var glyphIndex: Int
    var expiresAt: TimeInterval
    var isHead: Bool
    let columnID: Int

    init(layer: CALayer, glyphIndex: Int, expiresAt: TimeInterval, columnID: Int) {
      self.layer = layer
      self.glyphIndex = glyphIndex
      self.expiresAt = expiresAt
      self.isHead = true
      self.columnID = columnID
    }
  }

  private let promptLayer: CATextLayer
  private let rainHost: CALayer
  private let tuning: TerminalRainTuning
  private let atlas: TerminalGlyphAtlas
  private var bounds: CGRect = .zero
  private var globalFrame: CGRect = .zero
  private var scale: CGFloat
  private var frames: TerminalGlyphAtlas.Frames?
  private var visible = false
  private var text = ""
  private var cursorOn = true
  private var font: NSFont?
  /// Cellules dans l’ordre d’apparition. L’indice `oldest` sépare le préfixe déjà recyclé.
  private var cells: [RainCell] = []
  private var oldest = 0
  private var pool: [CALayer] = []
  private var headByColumn: [Int: RainCell] = [:]
  private var nonHeadCount = 0

  init(
    promptLayer: CATextLayer,
    rainHost: CALayer,
    scale: CGFloat,
    tuning: TerminalRainTuning,
    atlas: TerminalGlyphAtlas
  ) {
    self.promptLayer = promptLayer
    self.rainHost = rainHost
    self.scale = scale
    self.tuning = tuning
    self.atlas = atlas
    promptLayer.isWrapped = true
    promptLayer.alignmentMode = .left
    promptLayer.contentsScale = scale
    promptLayer.isHidden = true
    promptLayer.zPosition = 1
    rainHost.zPosition = 0
    rainHost.contentsScale = scale
    let glow = TerminalStyle.prompt.nsColor.cgColor
    promptLayer.foregroundColor = glow
    promptLayer.shadowColor = glow
    promptLayer.shadowOffset = .zero
    promptLayer.shadowRadius = 8
    promptLayer.shadowOpacity = 0.8
  }

  func setBounds(_ bounds: CGRect, globalFrame: CGRect, scale: CGFloat) {
    let scaleChanged = self.scale != scale || frames == nil
    self.bounds = bounds
    self.globalFrame = globalFrame
    self.scale = scale
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    rainHost.frame = bounds
    rainHost.contentsScale = scale
    CATransaction.commit()
    if scaleChanged, bounds.width > 1, bounds.height > 1 {
      frames = atlas.frames(at: scale)
    }
    layoutPrompt()
  }

  func addCell(
    columnID: Int,
    atGlobalX x: Double,
    bottomY: Double,
    trailLifetime: Double,
    now: TimeInterval
  ) {
    guard let frames, !frames.head.isEmpty, cellIntersectsFrame(x: x, bottomY: bottomY) else { return }
    evictOldestIfNeeded()
    let glyphIndex = Int.random(in: 0..<frames.head.count)
    let layer = takeLayer()
    layer.contents = frames.head[glyphIndex]
    layer.frame = layerFrame(x: x, bottomY: bottomY)
    layer.opacity = 1
    layer.isHidden = false
    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 1
    fade.toValue = 0
    fade.duration = trailLifetime
    fade.timingFunction = CAMediaTimingFunction(name: .easeIn)
    fade.fillMode = .forwards
    fade.isRemovedOnCompletion = false
    layer.add(fade, forKey: Self.fadeKey)

    if let previous = headByColumn[columnID] {
      demote(previous, frames: frames)
    }
    let cell = RainCell(
      layer: layer,
      glyphIndex: glyphIndex,
      expiresAt: now + trailLifetime,
      columnID: columnID
    )
    cells.append(cell)
    headByColumn[columnID] = cell
  }

  func releaseColumnHead(columnID: Int) {
    guard let head = headByColumn.removeValue(forKey: columnID), let frames else { return }
    demote(head, frames: frames)
  }

  func tick(now: TimeInterval) {
    expire(now: now)
    flicker()
  }

  func teardown() {
    for cell in cells {
      cell.layer.removeAllAnimations()
    }
    cells.removeAll(keepingCapacity: false)
    pool.removeAll(keepingCapacity: false)
    headByColumn.removeAll(keepingCapacity: false)
    oldest = 0
    nonHeadCount = 0
    frames = nil
    rainHost.sublayers?.forEach { $0.removeFromSuperlayer() }
    rainHost.removeFromSuperlayer()
  }

  func show(text: String, cursorOn: Bool, font: NSFont) {
    visible = true
    self.text = text
    self.cursorOn = cursorOn
    self.font = font
    layoutPrompt()
  }

  func hide() {
    visible = false
    promptLayer.isHidden = true
  }

  func shake() {
    let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
    animation.values = [0, -10, 9, -7, 5, -3, 0].map { NSNumber(value: $0) }
    animation.duration = 0.3
    // Pluie, prompt et calque CRT sont frères : le tremblement porte sur leur parent.
    let scene = promptLayer.superlayer ?? promptLayer
    scene.add(animation, forKey: Self.shakeKey)
  }

  private func layoutPrompt() {
    guard visible, let font else {
      promptLayer.isHidden = true
      return
    }
    let availableWidth = bounds.width - Self.horizontalInset * 2
    guard availableWidth > 1, bounds.height > 1 else {
      promptLayer.isHidden = true
      return
    }

    let shown = text + (cursorOn ? "_" : " ")
    let attributed = Self.promptString(shown, font: font)
    let singleLine = attributed.boundingRect(
      with: CGSize(width: Self.measurementSpan, height: Self.measurementSpan),
      options: [.usesLineFragmentOrigin, .usesFontLeading]
    )
    let fitsOnOneLine = singleLine.width <= availableWidth
    let block = fitsOnOneLine
      ? singleLine
      : attributed.boundingRect(
        with: CGSize(width: availableWidth, height: Self.measurementSpan),
        options: [.usesLineFragmentOrigin, .usesFontLeading]
      )
    let width = pixel(fitsOnOneLine ? singleLine.width : availableWidth, rounding: .up)
    let height = pixel(max(block.height, 1), rounding: .up)
    let x = pixel(
      fitsOnOneLine ? (bounds.width - width) / 2 : Self.horizontalInset,
      rounding: .toNearestOrAwayFromZero
    )
    let y = pixel((bounds.height - height) / 2, rounding: .toNearestOrAwayFromZero)

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    promptLayer.font = font
    promptLayer.fontSize = font.pointSize
    promptLayer.string = attributed
    promptLayer.contentsScale = scale
    promptLayer.frame = CGRect(x: x, y: y, width: max(width, 1), height: height)
    promptLayer.isHidden = false
    CATransaction.commit()
  }

  private func pixel(_ value: CGFloat, rounding: FloatingPointRoundingRule) -> CGFloat {
    let factor = max(scale, 1)
    return (value * factor).rounded(rounding) / factor
  }

  private func demote(_ cell: RainCell, frames: TerminalGlyphAtlas.Frames) {
    guard cell.isHead else { return }
    cell.isHead = false
    nonHeadCount += 1
    if frames.trail.indices.contains(cell.glyphIndex) {
      cell.layer.contents = frames.trail[cell.glyphIndex]
    }
  }

  private func evictOldestIfNeeded() {
    while cells.count - oldest >= tuning.maxLiveCellsPerScreen, oldest < cells.count {
      discard(cells[oldest])
      oldest += 1
    }
  }

  private func expire(now: TimeInterval) {
    guard oldest < cells.count else {
      cells.removeAll(keepingCapacity: true)
      oldest = 0
      return
    }
    var write = oldest
    for read in oldest..<cells.count {
      let cell = cells[read]
      if cell.expiresAt <= now {
        discard(cell)
      } else {
        if write != read { cells[write] = cell }
        write += 1
      }
    }
    cells.removeSubrange(write..<cells.count)
    if oldest > 0 {
      cells.removeFirst(oldest)
      oldest = 0
    }
  }

  private func flicker() {
    let probability = tuning.flickerProbabilityPerTick
    guard probability > 0, nonHeadCount > 0, let frames, !frames.trail.isEmpty else { return }
    let draws = Int((Double(nonHeadCount) * probability).rounded())
    guard draws > 0, oldest < cells.count else { return }
    let glyphCount = frames.trail.count
    var produced = 0
    var tries = 0
    while produced < draws, tries < draws * 4 {
      tries += 1
      let cell = cells[Int.random(in: oldest..<cells.count)]
      if cell.isHead { continue }
      var next = Int.random(in: 0..<glyphCount)
      if glyphCount > 1, next == cell.glyphIndex {
        next = (next + 1) % glyphCount
      }
      cell.glyphIndex = next
      cell.layer.contents = frames.trail[next]
      produced += 1
    }
  }

  private func discard(_ cell: RainCell) {
    if cell.isHead {
      if headByColumn[cell.columnID] === cell {
        headByColumn.removeValue(forKey: cell.columnID)
      }
    } else {
      nonHeadCount -= 1
    }
    cell.layer.removeAllAnimations()
    cell.layer.isHidden = true
    cell.layer.contents = nil
    pool.append(cell.layer)
  }

  private func takeLayer() -> CALayer {
    let layer: CALayer
    if let reused = pool.popLast() {
      layer = reused
      layer.removeAllAnimations()
    } else {
      layer = CALayer()
      layer.contentsGravity = .resize
      rainHost.addSublayer(layer)
    }
    layer.contentsScale = scale
    layer.isHidden = false
    return layer
  }

  private func layerFrame(x globalX: Double, bottomY: Double) -> CGRect {
    let margin = CGFloat(TerminalStyle.headGlowBlur)
    let size = terminalGlyphImageSize()
    let localX = CGFloat(globalX) - globalFrame.minX + bounds.minX
    let localBottom = CGFloat(bottomY) - globalFrame.minY + bounds.minY
    return CGRect(x: localX - margin, y: localBottom - margin, width: size.width, height: size.height)
  }

  private func cellIntersectsFrame(x: Double, bottomY: Double) -> Bool {
    let cell = CGRect(
      x: x,
      y: bottomY,
      width: TerminalStyle.cellWidth,
      height: TerminalStyle.cellHeight
    )
    return cell.intersects(globalFrame)
  }

  private static func promptString(_ text: String, font: NSFont) -> NSAttributedString {
    let style = NSMutableParagraphStyle()
    style.lineBreakMode = .byCharWrapping
    style.alignment = .left
    return NSAttributedString(
      string: text,
      attributes: [
        .font: font,
        .foregroundColor: TerminalStyle.prompt.nsColor,
        .paragraphStyle: style,
      ]
    )
  }
}

/// Fond noir, prompt et pluie au clic.
@MainActor
final class TerminalPlayMode: PlayMode {
  private let director: TerminalDirector

  init(tuning: TerminalRainTuning = .standard) {
    director = TerminalDirector(tuning: tuning)
  }

  func windowBackground(screenIndex _: Int) -> NSColor {
    TerminalStageView.backgroundColor
  }

  func makeStage(inputBridge: KioskInputBridge, screenIndex: Int, scale: CGFloat) -> NSView {
    TerminalStageView(
      inputBridge: inputBridge,
      director: director,
      screenIndex: screenIndex,
      scale: scale
    )
  }

  func reset() {
    director.reset()
  }
}

/// Fond uni, prompt sur l’écran choisi par le director.
final class TerminalStageView: NSView {
  static let backgroundColor = TerminalStyle.background.nsColor

  private let inputBridge: KioskInputBridge
  private let director: TerminalDirector
  private let screenIndex: Int
  /// Parent de la pluie, du prompt et du CRT. C’est lui qui tremble.
  private let sceneLayer = CALayer()
  /// Créé après `wantsLayer`, une fois le calque racine de la vue disponible.
  private var painter: TerminalPainter!
  private var crtOverlay: TerminalCRTOverlay?

  init(
    inputBridge: KioskInputBridge,
    director: TerminalDirector,
    screenIndex: Int,
    scale: CGFloat
  ) {
    self.inputBridge = inputBridge
    self.director = director
    self.screenIndex = screenIndex
    super.init(frame: .zero)
    wantsLayer = true
    guard let root = layer else {
      fatalError("TerminalStageView n’a pas de calque")
    }
    root.backgroundColor = Self.backgroundColor.cgColor
    root.contentsScale = scale
    sceneLayer.actions = TerminalCRTOverlay.frozenActions()
    root.addSublayer(sceneLayer)
    let rainHost = CALayer()
    let promptLayer = CATextLayer()
    painter = TerminalPainter(
      promptLayer: promptLayer,
      rainHost: rainHost,
      scale: scale,
      tuning: director.tuning,
      atlas: director.atlas
    )
    sceneLayer.addSublayer(rainHost)
    sceneLayer.addSublayer(promptLayer)
    if TerminalStyle.crtEffectEnabled {
      let overlay = TerminalCRTOverlay(scale: scale)
      sceneLayer.addSublayer(overlay.layer)
      crtOverlay = overlay
    }
    director.register(screenIndex: screenIndex, painter: painter)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) n’est pas supporté")
  }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    reportFrame()
  }

  override func layout() {
    super.layout()
    guard painter != nil else { return }
    let scale = window?.backingScaleFactor ?? 2
    layer?.contentsScale = scale
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    sceneLayer.frame = bounds
    sceneLayer.contentsScale = scale
    CATransaction.commit()
    painter.setBounds(bounds, globalFrame: window?.frame ?? .zero, scale: scale)
    crtOverlay?.layout(in: bounds, scale: scale)
    reportFrame()
  }

  override func mouseDown(with event: NSEvent) {
    reportFrame()
    guard let window else { return }
    let x = Double(window.frame.minX + event.locationInWindow.x)
    director.spawnColumn(atGlobalX: x, screenIndex: screenIndex)
  }

  override var acceptsFirstResponder: Bool { true }
  override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

  override func keyDown(with event: NSEvent) {
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
    director.handleKey(event)
  }

  private func reportFrame() {
    guard let frame = window?.frame else { return }
    director.noteFrame(screenIndex: screenIndex, frame: frame)
  }
}

/// Lignes de balayage, vignettage et coins noirs. Aucune animation sur ces calques.
private final class TerminalCRTOverlay {
  static let bleed: CGFloat = 16

  /// Empêche toute animation implicite quand `layout()` pose le cadre.
  static func frozenActions() -> [String: any CAAction] {
    [
      "bounds": NSNull(),
      "position": NSNull(),
      "contents": NSNull(),
      "backgroundColor": NSNull(),
      "path": NSNull(),
      "contentsScale": NSNull(),
      "sublayers": NSNull(),
      "zPosition": NSNull(),
      "opacity": NSNull(),
      "transform": NSNull(),
    ]
  }

  let layer = CALayer()
  private let scanlines = CALayer()
  private let vignette = CAGradientLayer()
  private let corners = CAShapeLayer()
  private var patternScale: CGFloat = 0

  init(scale: CGFloat) {
    layer.zPosition = 2
    let frozen = Self.frozenActions()
    layer.actions = frozen
    scanlines.actions = frozen
    vignette.actions = frozen
    corners.actions = frozen
    vignette.type = .radial
    vignette.startPoint = CGPoint(x: 0.5, y: 0.5)
    vignette.endPoint = CGPoint(x: 1, y: 1)
    let clear = NSColor.black.withAlphaComponent(0).cgColor
    let edge = NSColor.black.withAlphaComponent(CGFloat(TerminalStyle.vignetteEdgeOpacity)).cgColor
    vignette.colors = [clear, clear, edge]
    vignette.locations = [0, NSNumber(value: TerminalStyle.vignetteInnerRadius), 1]
    corners.fillColor = NSColor.black.cgColor
    corners.fillRule = .evenOdd
    layer.addSublayer(scanlines)
    layer.addSublayer(vignette)
    layer.addSublayer(corners)
    applyScale(scale)
  }

  func layout(in bounds: CGRect, scale: CGFloat) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    let frame = bounds.insetBy(dx: -Self.bleed, dy: -Self.bleed)
    layer.frame = frame
    let local = CGRect(origin: .zero, size: frame.size)
    scanlines.frame = local
    vignette.frame = local
    corners.frame = local
    applyScale(scale)
    corners.path = Self.cornerPath(overlayBounds: local)
    CATransaction.commit()
  }

  private func applyScale(_ scale: CGFloat) {
    guard scale > 0, scale != patternScale else { return }
    patternScale = scale
    layer.contentsScale = scale
    scanlines.contentsScale = scale
    vignette.contentsScale = scale
    corners.contentsScale = scale
    scanlines.backgroundColor = Self.scanlinePattern(scale: scale)
  }

  private static func cornerPath(overlayBounds: CGRect) -> CGPath {
    let radius = CGFloat(TerminalStyle.crtCornerRadius)
    let path = CGMutablePath()
    path.addPath(CGPath(rect: overlayBounds, transform: nil))
    path.addPath(
      CGPath(
        roundedRect: overlayBounds.insetBy(dx: bleed, dy: bleed),
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
      )
    )
    return path
  }

  /// Image 1 × `scanlinePeriodPixels` pixels, taille en points = pixels / échelle.
  private static func scanlinePattern(scale: CGFloat) -> CGColor? {
    let period = TerminalStyle.scanlinePeriodPixels
    guard period >= 1, scale > 0 else { return nil }
    guard
      let context = CGContext(
        data: nil,
        width: 1,
        height: period,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else { return nil }
    context.setFillColor(
      NSColor.black.withAlphaComponent(CGFloat(TerminalStyle.scanlineOpacity)).cgColor
    )
    context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
    guard let image = context.makeImage() else { return nil }
    let pointSize = NSSize(width: 1 / scale, height: CGFloat(period) / scale)
    return NSColor(patternImage: NSImage(cgImage: image, size: pointSize)).cgColor
  }
}

private func terminalGlyphImageSize() -> CGSize {
  let margin = CGFloat(TerminalStyle.headGlowBlur)
  return CGSize(
    width: CGFloat(TerminalStyle.cellWidth) + margin * 2,
    height: CGFloat(TerminalStyle.cellHeight) + margin * 2
  )
}

extension TerminalStyle.SRGB {
  var nsColor: NSColor {
    nsColor(alpha: 1)
  }

  func nsColor(alpha: CGFloat) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
  }
}
