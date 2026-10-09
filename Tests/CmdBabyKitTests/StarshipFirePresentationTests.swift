import AppKit
import QuartzCore
import Testing

@testable import CmdBaby
@testable import CmdBabyKit

@Test("Le tir au clic file du nez jusqu’à la cible, sans retour")
@MainActor
func boltFliesFromTheNoseToTheTargetWithoutReversing() throws {
  let painter = hostedPainter()
  let start = CGPoint(x: 80, y: 40)
  let end = CGPoint(x: 80, y: 640)
  painter.fireBolt(from: start, to: end, angle: .pi / 2, duration: 0.3, delay: 0)

  let flight = try #require(positionFlight(under: painter.skyboxBack.superlayer))
  #expect(flight.autoreverses == false)
  #expect(flight.repeatCount == 0)
  let from = try #require(cgPoint(flight.fromValue))
  let to = try #require(cgPoint(flight.toValue))
  #expect(abs(from.x - start.x) < 0.1)
  #expect(abs(from.y - start.y) < 0.1)
  #expect(abs(to.x - end.x) < 0.1)
  #expect(abs(to.y - end.y) < 0.1)
}

@Test("L’explosion grossit le glyphe déjà à l’écran, sans en dessiner un autre")
@MainActor
func explosionPopsTheGlyphAlreadyOnScreen() throws {
  let painter = hostedPainter()
  let host = try #require(painter.skyboxBack.superlayer)
  painter.addTarget(
    id: 1,
    kind: .enemy,
    sprite: "enemyBlue1",
    label: "A",
    at: CGPoint(x: 200, y: 300),
    heading: -.pi / 2
  )
  let glyphsBefore = textLayers(under: host)
  let glyph = try #require(glyphsBefore.first)
  #expect(glyphsBefore.count == 1)

  painter.explodeTarget(id: 1, kind: .enemy, now: ProcessInfo.processInfo.systemUptime)

  let glyphsAfter = textLayers(under: host)
  #expect(glyphsAfter.count == 1)
  #expect(glyphsAfter.first === glyph)
  let pop = try #require(glyph.animation(forKey: "pop") as? CAAnimationGroup)
  let scale = try #require(pop.animations?.compactMap { $0 as? CABasicAnimation }.first { $0.keyPath == "transform.scale" })
  #expect(abs((scalar(scale.fromValue) ?? -1) - 1) < 1e-6)
  #expect(abs((scalar(scale.toValue) ?? -1) - 1.6) < 1e-6)
}

@Test("L’explosion laisse la lettre sur l’ennemi, sans la faire partir du bord")
@MainActor
func explosionKeepsTheLetterOnTheEnemy() throws {
  let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
    styleMask: [.borderless],
    backing: .buffered,
    defer: false
  )
  let view = NSView(frame: NSRect(x: 0, y: 0, width: 1280, height: 800))
  view.wantsLayer = true
  window.contentView = view
  let painter = StarshipPainter(tuning: .standard, scale: 2)
  let host = try #require(view.layer)
  host.addSublayer(painter.skyboxBack)
  host.addSublayer(painter.skyboxFront)
  host.addSublayer(painter.shipRoot)

  let enemy = CGPoint(x: 640, y: 420)
  painter.addTarget(
    id: 1,
    kind: .enemy,
    sprite: "enemyBlue1",
    label: "A",
    at: enemy,
    heading: -.pi / 2
  )
  let glyph = try #require(textLayers(under: host).first)
  CATransaction.flush()

  painter.explodeTarget(id: 1, kind: .enemy, now: ProcessInfo.processInfo.systemUptime)
  CATransaction.flush()

  #expect(abs(glyph.position.x - enemy.x) < 0.5)
  #expect(abs(glyph.position.y - enemy.y) < 0.5)
  let departure = cgPoint((glyph.animation(forKey: "position") as? CABasicAnimation)?.fromValue)
  #expect(departure == nil)
  #expect(glyph.animation(forKey: "pop") != nil)
  _ = window
}

@Test("Le rayon vers une cible étire le sprite, sans calque de la hauteur du tir")
@MainActor
func beamStretchesTheSpriteInsteadOfAScreenTallLayer() throws {
  let painter = hostedPainter()
  let start = CGPoint(x: 120, y: 80)
  let end = CGPoint(x: 120, y: 80 + 860)
  painter.fireBeam(from: start, to: end, delay: 0, duration: 0.15, now: 0)
  let beam = try #require(findLayer(withAnimation: "beam", under: painter.skyboxBack.superlayer))
  #expect(abs(beam.bounds.width - 14) < 0.1)
  #expect(abs(beam.bounds.height - 86) < 0.1)
  #expect(abs(beam.position.x - start.x) < 0.1)
  #expect(abs(beam.position.y - start.y) < 0.1)
  let scaleY = scalar(beam.value(forKeyPath: "transform.scale.y")) ?? 0
  #expect(abs(scaleY - 10) < 0.01)
}

@Test("Le rayon part du vaisseau et aboutit sur l’ennemi, vers le haut, le bas et les côtés")
@MainActor
func beamReachesTheEnemyInEveryDirection() throws {
  let shots = [
    (start: CGPoint(x: 200, y: 160), end: CGPoint(x: 200, y: 720)),
    (start: CGPoint(x: 200, y: 640), end: CGPoint(x: 200, y: 80)),
    (start: CGPoint(x: 180, y: 240), end: CGPoint(x: 860, y: 240)),
    (start: CGPoint(x: 700, y: 500), end: CGPoint(x: 140, y: 120)),
  ]
  for shot in shots {
    let painter = hostedPainter()
    painter.fireBeam(from: shot.start, to: shot.end, delay: 0, duration: 0.15, now: 0)
    let beam = try #require(findLayer(withAnimation: "beam", under: painter.skyboxBack.superlayer))
    let host = try #require(beam.superlayer)
    let near = beam.convert(CGPoint(x: beam.bounds.midX, y: beam.bounds.minY), to: host)
    let far = beam.convert(CGPoint(x: beam.bounds.midX, y: beam.bounds.maxY), to: host)
    #expect(abs(near.x - shot.start.x) < 0.5)
    #expect(abs(near.y - shot.start.y) < 0.5)
    #expect(abs(far.x - shot.end.x) < 0.5)
    #expect(abs(far.y - shot.end.y) < 0.5)
  }
}

@Test("La visée tourne le vaisseau sans retour")
@MainActor
func aimTurnsTheShipWithoutReversing() throws {
  let painter = hostedPainter()
  painter.aimShip(at: .pi, duration: 0.1)
  let aim = try #require(animation(named: "aim", under: painter.shipRoot) as? CABasicAnimation)
  #expect(aim.keyPath == "transform.rotation.z")
  #expect(aim.autoreverses == false)
  #expect(aim.repeatCount == 0)
}

@MainActor
private func hostedPainter() -> StarshipPainter {
  let painter = StarshipPainter(tuning: .standard, scale: 2)
  let host = CALayer()
  host.addSublayer(painter.skyboxBack)
  host.addSublayer(painter.skyboxFront)
  host.addSublayer(painter.shipRoot)
  return painter
}

private func textLayers(under layer: CALayer) -> [CATextLayer] {
  var found: [CATextLayer] = []
  if let text = layer as? CATextLayer {
    found.append(text)
  }
  for child in layer.sublayers ?? [] {
    found.append(contentsOf: textLayers(under: child))
  }
  return found
}

private func findLayer(withAnimation key: String, under root: CALayer?) -> CALayer? {
  guard let root else { return nil }
  if root.animation(forKey: key) != nil { return root }
  for child in root.sublayers ?? [] {
    if let found = findLayer(withAnimation: key, under: child) { return found }
  }
  return nil
}

private func positionFlight(under layer: CALayer?) -> CABasicAnimation? {
  guard let layer else { return nil }
  if let flight = layer.animation(forKey: "flight") as? CABasicAnimation, flight.keyPath == "position" {
    return flight
  }
  for child in layer.sublayers ?? [] {
    if let flight = positionFlight(under: child) {
      return flight
    }
  }
  return nil
}

private func animation(named key: String, under layer: CALayer) -> CAAnimation? {
  if let found = layer.animation(forKey: key) { return found }
  for child in layer.sublayers ?? [] {
    if let found = animation(named: key, under: child) { return found }
  }
  return nil
}

private func scalar(_ value: Any?) -> Double? {
  (value as? NSNumber)?.doubleValue
}

private func cgPoint(_ value: Any?) -> CGPoint? {
  if let point = value as? CGPoint { return point }
  guard let value = value as? NSValue else { return nil }
  return value.pointValue
}
