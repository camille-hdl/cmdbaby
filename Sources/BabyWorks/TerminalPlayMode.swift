import AppKit
import BabyWorkDiagnosticsKit
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

  private var screens: [ScreenSlot] = []
  private var prompt = TerminalPrompt()
  private var promptScreenIndex: Int?
  private var cursorOn = true
  private var blinkTimer: Timer?
  private var promptFont: NSFont?

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

  func reset() {
    let timer = blinkTimer
    blinkTimer = nil
    timer?.invalidate()
    screens.removeAll(keepingCapacity: false)
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

/// Calque de prompt : texte, curseur et lueur.
@MainActor
final class TerminalPainter {
  private static let horizontalInset: CGFloat = 96
  private static let measurementSpan: CGFloat = 100_000
  private static let shakeKey = "terminalShake"

  private let root: CALayer
  private let promptLayer: CATextLayer
  private var bounds: CGRect = .zero
  private var scale: CGFloat
  private var visible = false
  private var text = ""
  private var cursorOn = true
  private var font: NSFont?

  init(root: CALayer, promptLayer: CATextLayer, scale: CGFloat) {
    self.root = root
    self.promptLayer = promptLayer
    self.scale = scale
    promptLayer.isWrapped = true
    promptLayer.alignmentMode = .left
    promptLayer.contentsScale = scale
    promptLayer.isHidden = true
    let glow = TerminalStyle.prompt.nsColor.cgColor
    promptLayer.foregroundColor = glow
    promptLayer.shadowColor = glow
    promptLayer.shadowOffset = .zero
    promptLayer.shadowRadius = 8
    promptLayer.shadowOpacity = 0.8
  }

  func setBounds(_ bounds: CGRect, scale: CGFloat) {
    self.bounds = bounds
    self.scale = scale
    layoutPrompt()
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
    root.add(animation, forKey: Self.shakeKey)
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

/// Fond noir et prompt. Pas encore de pluie.
@MainActor
final class TerminalPlayMode: PlayMode {
  private let director = TerminalDirector()

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
  /// Créé après `wantsLayer`, une fois le calque racine de la vue disponible.
  private var painter: TerminalPainter!

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
    let promptLayer = CATextLayer()
    painter = TerminalPainter(root: root, promptLayer: promptLayer, scale: scale)
    root.addSublayer(promptLayer)
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
    painter.setBounds(bounds, scale: scale)
    reportFrame()
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

extension TerminalStyle.SRGB {
  var nsColor: NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
  }
}
