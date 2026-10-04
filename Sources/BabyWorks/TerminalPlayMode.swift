import AppKit
import BabyWorkDiagnosticsKit

extension TerminalStyle.RGB {
  var nsColor: NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
  }
}

/// Session partagée entre les écrans. Pas de pluie ni de prompt.
@MainActor
final class TerminalDirector {
  func register(_: TerminalPainter) {}

  func reset() {}
}

/// Dessin Core Animation d’un écran Terminal.
@MainActor
final class TerminalPainter {}

/// Enveloppe `TerminalDirector` et le fond unique.
@MainActor
final class TerminalPlayMode: PlayMode {
  private let director = TerminalDirector()

  func windowBackground(screenIndex _: Int) -> NSColor {
    TerminalStyle.background.nsColor
  }

  func makeStage(inputBridge: KioskInputBridge, screenIndex: Int, scale: CGFloat) -> NSView {
    TerminalStageView(
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

/// Fond uni. Transmet les frappes au pont d’entrée. Pas de SwiftUI (isolation MainActor).
final class TerminalStageView: NSView {
  private let inputBridge: KioskInputBridge

  init(
    background: NSColor,
    inputBridge: KioskInputBridge,
    director: TerminalDirector,
    scale: CGFloat
  ) {
    self.inputBridge = inputBridge
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = background.cgColor
    layer?.contentsScale = scale
    director.register(TerminalPainter())
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
