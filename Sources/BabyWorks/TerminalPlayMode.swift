import AppKit
import BabyWorkDiagnosticsKit

/// Un par session, partagé entre les écrans.
@MainActor
final class TerminalDirector {
  func register(_: TerminalStageView) {}

  func reset() {}
}

/// Fond noir identique sur chaque écran. Pas de prompt ni de pluie.
@MainActor
final class TerminalPlayMode: PlayMode {
  private let director = TerminalDirector()

  func windowBackground(screenIndex _: Int) -> NSColor {
    TerminalStageView.backgroundColor
  }

  func makeStage(inputBridge: KioskInputBridge, screenIndex _: Int, scale: CGFloat) -> NSView {
    TerminalStageView(inputBridge: inputBridge, director: director, scale: scale)
  }

  func reset() {
    director.reset()
  }
}

/// Fond uni. Les frappes partent vers les sorties adultes, rien d’autre.
final class TerminalStageView: NSView {
  static let backgroundColor = TerminalStyle.background.nsColor

  private let inputBridge: KioskInputBridge

  init(inputBridge: KioskInputBridge, director: TerminalDirector, scale: CGFloat) {
    self.inputBridge = inputBridge
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = Self.backgroundColor.cgColor
    layer?.contentsScale = scale
    director.register(self)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) n’est pas supporté")
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
  }
}

extension TerminalStyle.SRGB {
  var nsColor: NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
  }
}
