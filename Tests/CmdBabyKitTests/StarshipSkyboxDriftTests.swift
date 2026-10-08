import AppKit
import QuartzCore
import Testing

@testable import CmdBaby
@testable import CmdBabyKit

@Test("La dérive du ciel descend une fois, sans retour ni saut vers le haut")
@MainActor
func skyboxDriftDescendsOnceWithoutReversingOrJumping() throws {
  let tuning = StarshipTuning.standard
  let painter = StarshipPainter(tuning: tuning, scale: 2)
  let screens = [TerminalScreen(index: 0, x: 0, y: 0, width: 1440, height: 900)]
  let from = try #require(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 0, verticalMargin: tuning.skyboxDriftMargin
    )
  )
  let to = try #require(
    StarshipSkyboxFraming.contentsRect(
      forScreen: 0, among: screens, drift: 1, verticalMargin: tuning.skyboxDriftMargin
    )
  )
  #expect(to.y > from.y)
  #expect(abs(tuning.skyboxDriftDuration - 180) < 1e-6)
  painter.showSkybox(
    image: try #require(onePixelSky()),
    driftFrom: from,
    driftTo: to,
    driftDuration: tuning.skyboxDriftDuration,
    mediaBeginTime: CACurrentMediaTime()
  )

  let back = try #require(contentsRectDrift(on: painter.skyboxBack))
  let front = try #require(contentsRectDrift(on: painter.skyboxFront))
  for animation in [back, front] {
    #expect(animation.autoreverses == false)
    // 0 joue une fois. Répéter, même sans retour, ramène y au départ : le ciel saute vers le haut.
    #expect(animation.repeatCount == 0)
    #expect(animation.repeatDuration == 0)
    #expect(abs(animation.duration - 180) < 1e-6)
  }

  let backFrom = try #require(unitRect(back.fromValue))
  let backTo = try #require(unitRect(back.toValue))
  #expect(backTo.origin.y > backFrom.origin.y)
  #expect(abs(backFrom.origin.y - from.y) < 1e-5)
  #expect(abs(backTo.origin.y - to.y) < 1e-5)
}

private func contentsRectDrift(on layer: CALayer) -> CABasicAnimation? {
  for key in layer.animationKeys() ?? [] {
    guard let animation = layer.animation(forKey: key) as? CABasicAnimation,
      animation.keyPath == "contentsRect"
    else { continue }
    return animation
  }
  return nil
}

private func unitRect(_ value: Any?) -> CGRect? {
  if let rect = value as? CGRect { return rect }
  guard let value = value as? NSValue else { return nil }
  return value.rectValue
}

private func onePixelSky() -> CGImage? {
  let space = CGColorSpaceCreateDeviceRGB()
  let context = CGContext(
    data: nil,
    width: 1,
    height: 1,
    bitsPerComponent: 8,
    bytesPerRow: 4,
    space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
  )
  return context?.makeImage()
}
