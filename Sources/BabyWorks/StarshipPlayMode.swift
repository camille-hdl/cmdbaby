import AppKit
import BabyWorkDiagnosticsKit
import QuartzCore

/// Une skybox par session, découpée sur l’union des écrans.
@MainActor
final class StarshipDirector {
  private struct ScreenSlot {
    var index: Int
    var frame: CGRect?
    var painter: StarshipPainter
  }

  let tuning: StarshipTuning

  private var screens: [ScreenSlot] = []
  private var skybox: CGImage?
  private var skyboxChosen = false
  private var rng = SystemRandomNumberGenerator()

  init(tuning: StarshipTuning = .standard) {
    self.tuning = tuning
  }

  func register(screenIndex: Int, painter: StarshipPainter) {
    screens.append(ScreenSlot(index: screenIndex, frame: nil, painter: painter))
    if !skyboxChosen {
      skyboxChosen = true
      let name = StarshipSkyboxRotation.first(using: &rng)
      skybox = StarshipSprite.cgImage(named: name)
    }
    publishSkybox()
  }

  func noteFrame(screenIndex: Int, frame: CGRect) {
    guard let slot = screens.firstIndex(where: { $0.index == screenIndex }) else { return }
    if screens[slot].frame == frame { return }
    screens[slot].frame = frame
    publishSkybox()
  }

  func reset() {
    screens.removeAll(keepingCapacity: false)
    skybox = nil
    skyboxChosen = false
    rng = SystemRandomNumberGenerator()
  }

  private func framedScreens() -> [TerminalScreen] {
    screens.compactMap { slot in
      guard let frame = slot.frame else { return nil }
      return TerminalScreen(
        index: slot.index,
        x: Double(frame.origin.x),
        y: Double(frame.origin.y),
        width: Double(frame.size.width),
        height: Double(frame.size.height)
      )
    }
  }

  private func publishSkybox() {
    guard let skybox else { return }
    let framed = framedScreens()
    for slot in screens {
      guard slot.frame != nil,
        let rect = StarshipSkyboxFraming.contentsRect(forScreen: slot.index, among: framed)
      else { continue }
      slot.painter.showSkybox(image: skybox, contentsRect: rect)
    }
  }
}

/// Ciel commun à tous les écrans. Rien ne bouge encore.
@MainActor
final class StarshipPlayMode: PlayMode {
  private let director: StarshipDirector
  #if DEBUG
  private var checkedCatalogImages = false
  #endif

  init(tuning: StarshipTuning = .standard) {
    director = StarshipDirector(tuning: tuning)
  }

  func windowBackground(screenIndex _: Int) -> NSColor {
    StarshipStageView.backgroundColor
  }

  func makeStage(inputBridge: KioskInputBridge, screenIndex: Int, scale: CGFloat) -> NSView {
    assertCatalogImagesIfNeeded()
    return StarshipStageView(
      inputBridge: inputBridge,
      director: director,
      screenIndex: screenIndex,
      scale: scale
    )
  }

  func reset() {
    director.reset()
    StarshipSprite.purge()
  }

  private func assertCatalogImagesIfNeeded() {
    #if DEBUG
    guard !checkedCatalogImages else { return }
    checkedCatalogImages = true
    for name in StarshipCatalog.allImageNames {
      assert(
        StarshipSprite.cgImage(named: name) != nil,
        "Image du mode Vaisseau introuvable : \(name)"
      )
    }
    #endif
  }
}

/// Calque de skybox d’un écran. Le `contentsRect` choisit le morceau du ciel.
@MainActor
final class StarshipPainter {
  let skyboxLayer = CALayer()

  init() {
    skyboxLayer.zPosition = 0
    skyboxLayer.contentsGravity = .resize
    skyboxLayer.magnificationFilter = .linear
    skyboxLayer.minificationFilter = .trilinear
  }

  func setBounds(_ bounds: CGRect) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skyboxLayer.frame = bounds
    CATransaction.commit()
  }

  /// `contentsRect` partage l’origine en bas à gauche du calque non retourné.
  /// Vérifié avec `skybox-space-band` : la bande claire reste dans le même sens que le PNG.
  func showSkybox(image: CGImage, contentsRect: StarshipUnitRect) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    skyboxLayer.contents = image
    skyboxLayer.contentsRect = CGRect(
      x: contentsRect.x,
      y: contentsRect.y,
      width: contentsRect.width,
      height: contentsRect.height
    )
    CATransaction.commit()
  }
}

/// Ciel de la session sur un écran. La frappe ne fait encore que remonter les sorties adultes.
final class StarshipStageView: NSView {
  static let backgroundColor = NSColor(
    srgbRed: 0x0B / 255,
    green: 0x0B / 255,
    blue: 0x1F / 255,
    alpha: 1
  )

  private let inputBridge: KioskInputBridge
  private let director: StarshipDirector
  private let screenIndex: Int
  private let sceneLayer = CALayer()
  private var painter: StarshipPainter!

  init(
    inputBridge: KioskInputBridge,
    director: StarshipDirector,
    screenIndex: Int,
    scale: CGFloat
  ) {
    self.inputBridge = inputBridge
    self.director = director
    self.screenIndex = screenIndex
    super.init(frame: .zero)
    wantsLayer = true
    guard let root = layer else {
      fatalError("StarshipStageView n’a pas de calque")
    }
    root.backgroundColor = Self.backgroundColor.cgColor
    root.contentsScale = scale
    root.addSublayer(sceneLayer)
    let painter = StarshipPainter()
    self.painter = painter
    sceneLayer.addSublayer(painter.skyboxLayer)
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
    painter.setBounds(bounds)
    reportFrame()
  }

  override func mouseDown(with event: NSEvent) {
    window?.makeFirstResponder(self)
  }

  private func reportFrame() {
    guard let frame = window?.frame else { return }
    director.noteFrame(screenIndex: screenIndex, frame: frame)
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
