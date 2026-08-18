import SwiftUI

extension ElementalAnimeScene {
  func drawEarth(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let epicenter = CGPoint(x: size.width / 2, y: size.height * 0.7)
    let sealCenter = CGPoint(x: size.width / 2, y: size.height * 0.54)
    let sealRadius = min(size.width, size.height) * 0.31

    for orbit in 0..<3 {
      let orbitRect = CGRect(
        x: sealCenter.x - sealRadius * (1.25 + CGFloat(orbit) * 0.38),
        y: sealCenter.y - sealRadius * (0.58 + CGFloat(orbit) * 0.18),
        width: sealRadius * (2.5 + CGFloat(orbit) * 0.76),
        height: sealRadius * (1.16 + CGFloat(orbit) * 0.36)
      )
      context.stroke(
        Path(ellipseIn: orbitRect),
        with: .color(
          element.color.opacity((0.045 + Double(orbit) * 0.018) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.55 + CGFloat(orbit) * 0.28,
          dash: orbit == 1 ? [8, 7, 2, 7] : []
        )
      )
    }

    for planet in 0..<7 {
      let direction = planet.isMultiple(of: 2) ? 1.0 : -1.0
      let angle = Double(planet) * 2 * .pi / 7 + time * (0.035 + Double(planet) * 0.006) * direction
      let orbitX = sealRadius * (1.32 + CGFloat(planet % 3) * 0.34)
      let orbitY = sealRadius * (0.64 + CGFloat(planet % 3) * 0.16)
      let planetCenter = CGPoint(
        x: sealCenter.x + cos(angle) * orbitX,
        y: sealCenter.y + sin(angle) * orbitY
      )
      let planetRadius = CGFloat(3.8 + Double(planet % 4) * 2)
      let planetRect = CGRect(
        x: planetCenter.x - planetRadius,
        y: planetCenter.y - planetRadius,
        width: planetRadius * 2,
        height: planetRadius * 2
      )
      if planet.isMultiple(of: 3) {
        context.stroke(
          Path(
            ellipseIn: planetRect.insetBy(
              dx: -planetRadius * 0.72,
              dy: planetRadius * 0.5
            )
          ),
          with: .color(Color(red: 0.92, green: 0.66, blue: 0.36).opacity(0.3 * power)),
          lineWidth: 0.65
        )
      }
      context.fill(
        Path(ellipseIn: planetRect),
        with: .radialGradient(
          Gradient(colors: [
            Color(red: 0.96, green: 0.72, blue: 0.42).opacity(0.74 * power),
            element.color.opacity(0.62 * power),
            Color(red: 0.12, green: 0.045, blue: 0.015).opacity(0.86),
          ]),
          center: CGPoint(
            x: planetCenter.x - planetRadius * 0.28,
            y: planetCenter.y - planetRadius * 0.32
          ),
          startRadius: 0,
          endRadius: planetRadius
        )
      )
    }

    let saturnCenter = CGPoint(
      x: size.width * 0.82 + sin(time * 0.075) * size.width * 0.012,
      y: size.height * 0.22 + cos(time * 0.09) * size.height * 0.009
    )
    let saturnRadius = sealRadius * 0.115
    let saturnRect = CGRect(
      x: saturnCenter.x - saturnRadius,
      y: saturnCenter.y - saturnRadius,
      width: saturnRadius * 2,
      height: saturnRadius * 2
    )
    var saturnAura = context
    saturnAura.addFilter(.blur(radius: 16))
    saturnAura.fill(
      Path(ellipseIn: saturnRect.insetBy(dx: -saturnRadius, dy: -saturnRadius)),
      with: .color(Color.orange.opacity(0.055 * power))
    )
    context.stroke(
      Path(
        ellipseIn: CGRect(
          x: saturnCenter.x - saturnRadius * 2.25,
          y: saturnCenter.y - saturnRadius * 0.48,
          width: saturnRadius * 4.5,
          height: saturnRadius * 0.96
        )
      ),
      with: .linearGradient(
        Gradient(colors: [
          .clear,
          Color(red: 0.95, green: 0.73, blue: 0.45).opacity(0.42 * power),
          element.color.opacity(0.26 * power),
          .clear,
        ]),
        startPoint: CGPoint(x: saturnCenter.x - saturnRadius * 2.2, y: saturnCenter.y),
        endPoint: CGPoint(x: saturnCenter.x + saturnRadius * 2.2, y: saturnCenter.y)
      ),
      style: StrokeStyle(lineWidth: saturnRadius * 0.2, lineCap: .round)
    )
    context.fill(
      Path(ellipseIn: saturnRect),
      with: .radialGradient(
        Gradient(colors: [
          Color(red: 0.98, green: 0.76, blue: 0.46).opacity(0.78 * power),
          Color(red: 0.55, green: 0.28, blue: 0.09).opacity(0.7 * power),
          Color(red: 0.12, green: 0.045, blue: 0.015).opacity(0.9),
        ]),
        center: CGPoint(
          x: saturnCenter.x - saturnRadius * 0.3,
          y: saturnCenter.y - saturnRadius * 0.32
        ),
        startRadius: 0,
        endRadius: saturnRadius
      )
    )

    let brokenCenter = CGPoint(
      x: size.width * 0.16 + cos(time * 0.065) * size.width * 0.01,
      y: size.height * 0.28 + sin(time * 0.085) * size.height * 0.008
    )
    let brokenRadius = sealRadius * 0.13
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: brokenCenter.x - brokenRadius,
          y: brokenCenter.y - brokenRadius,
          width: brokenRadius * 2,
          height: brokenRadius * 2
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color(red: 0.84, green: 0.54, blue: 0.27).opacity(0.58 * power),
          Color(red: 0.28, green: 0.12, blue: 0.04).opacity(0.78 * power),
          Color.black.opacity(0.84),
        ]),
        center: CGPoint(
          x: brokenCenter.x - brokenRadius * 0.25,
          y: brokenCenter.y - brokenRadius * 0.3
        ),
        startRadius: 0,
        endRadius: brokenRadius
      )
    )
    for crackIndex in 0..<7 {
      let angle = Double(crackIndex) * 2 * .pi / 7 + 0.34
      var planetCrack = Path()
      planetCrack.move(to: brokenCenter)
      planetCrack.addLine(
        to: CGPoint(
          x: brokenCenter.x + cos(angle) * brokenRadius * 0.45,
          y: brokenCenter.y + sin(angle) * brokenRadius * 0.45
        )
      )
      planetCrack.addLine(
        to: CGPoint(
          x: brokenCenter.x + cos(angle + 0.15) * brokenRadius * 0.94,
          y: brokenCenter.y + sin(angle + 0.15) * brokenRadius * 0.94
        )
      )
      context.stroke(
        planetCrack,
        with: .color(Color.orange.opacity((0.22 + Double(crackIndex % 3) * 0.06) * power)),
        lineWidth: 0.65 + CGFloat(crackIndex % 2) * 0.55
      )
    }
    for fragment in 0..<9 {
      let angle = Double(fragment) * 2 * .pi / 9 - time * 0.08
      let distance = brokenRadius * (1.35 + CGFloat(fragment % 3) * 0.34)
      let fragmentCenter = CGPoint(
        x: brokenCenter.x + cos(angle) * distance,
        y: brokenCenter.y + sin(angle) * distance * 0.68
      )
      let fragmentSize = brokenRadius * (0.13 + CGFloat(fragment % 3) * 0.045)
      var shard = Path()
      shard.move(to: CGPoint(x: fragmentCenter.x, y: fragmentCenter.y - fragmentSize))
      shard.addLine(
        to: CGPoint(x: fragmentCenter.x + fragmentSize * 0.72, y: fragmentCenter.y)
      )
      shard.addLine(
        to: CGPoint(x: fragmentCenter.x - fragmentSize * 0.42, y: fragmentCenter.y + fragmentSize)
      )
      shard.closeSubpath()
      context.fill(
        shard,
        with: .color(
          Color(red: 0.68, green: 0.38, blue: 0.17)
            .opacity((0.25 + Double(fragment % 3) * 0.06) * power)
        )
      )
    }

    for comet in 0..<5 {
      let seed = Double(comet + 1)
      let progress =
        (time * (0.028 + seed * 0.003) + seed * 0.19)
        .truncatingRemainder(dividingBy: 1.35) - 0.18
      let head = CGPoint(
        x: size.width * CGFloat(progress),
        y: size.height * CGFloat(0.08 + seed * 0.065 + progress * 0.24)
      )
      let tail = CGPoint(
        x: head.x - size.width * (0.1 + CGFloat(comet % 3) * 0.035),
        y: head.y - size.height * (0.055 + CGFloat(comet % 2) * 0.025)
      )
      var cometTrail = Path()
      cometTrail.move(to: tail)
      cometTrail.addLine(to: head)
      var cometGlow = context
      cometGlow.addFilter(.blur(radius: 7))
      cometGlow.stroke(
        cometTrail,
        with: .color(Color.orange.opacity(0.13 * power)),
        style: StrokeStyle(lineWidth: 7 + CGFloat(comet % 3) * 2, lineCap: .round)
      )
      context.stroke(
        cometTrail,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            element.color.opacity(0.28 * power),
            Color.white.opacity(0.62 * power),
          ]),
          startPoint: tail,
          endPoint: head
        ),
        style: StrokeStyle(lineWidth: 0.75 + CGFloat(comet % 3) * 0.4, lineCap: .round)
      )
      context.fill(
        Path(ellipseIn: CGRect(x: head.x - 2.4, y: head.y - 2.4, width: 4.8, height: 4.8)),
        with: .color(Color.white.opacity(0.72 * power))
      )
    }

    for ridge in 0..<4 {
      let horizontalShift =
        sin(time * (0.065 + Double(ridge) * 0.018) + Double(ridge) * 1.7)
        * size.width * (0.012 + CGFloat(ridge) * 0.004)
      let verticalShift =
        cos(time * (0.11 + Double(ridge) * 0.02) + Double(ridge))
        * size.height * (0.004 + CGFloat(ridge) * 0.0015)
      let baseline = size.height * (0.46 + CGFloat(ridge) * 0.085) + verticalShift
      var distantRange = Path()
      distantRange.move(to: CGPoint(x: 0, y: size.height))
      distantRange.addLine(to: CGPoint(x: 0, y: baseline))
      for peak in 0...9 {
        let fraction = CGFloat(peak) / 9
        let heightHash = abs(sin(Double(peak * 7 + ridge * 13) * 0.79))
        let height = size.height * CGFloat(0.09 + heightHash * (0.13 - Double(ridge) * 0.014))
        distantRange.addLine(
          to: CGPoint(x: size.width * fraction + horizontalShift, y: baseline - height)
        )
      }
      distantRange.addLine(to: CGPoint(x: size.width, y: size.height))
      distantRange.closeSubpath()

      var distantEarth = context
      distantEarth.addFilter(.blur(radius: 22 + CGFloat(ridge) * 9))
      distantEarth.fill(
        distantRange,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.68, green: 0.43, blue: 0.22).opacity(
              (0.09 - Double(ridge) * 0.015) * power),
            Color(red: 0.16, green: 0.07, blue: 0.025).opacity(
              0.2 + Double(ridge) * 0.04),
          ]),
          startPoint: CGPoint(x: size.width / 2, y: baseline - size.height * 0.18),
          endPoint: CGPoint(x: size.width / 2, y: size.height)
        )
      )
    }

    var earthMist = context
    earthMist.addFilter(.blur(radius: 38))
    for index in 0..<6 {
      let seed = Double(index + 1)
      let mistCenter = CGPoint(
        x: size.width * CGFloat(0.08 + seed.truncatingRemainder(dividingBy: 5) * 0.205)
          + sin(time * 0.1 + seed) * size.width * 0.035,
        y: size.height * CGFloat(0.38 + seed.truncatingRemainder(dividingBy: 3) * 0.14)
          + cos(time * 0.14 + seed) * size.height * 0.012
      )
      let mistWidth = size.width * CGFloat(0.18 + seed.truncatingRemainder(dividingBy: 3) * 0.06)
      let mistHeight = size.height * CGFloat(0.08 + seed.truncatingRemainder(dividingBy: 2) * 0.035)
      earthMist.fill(
        Path(
          ellipseIn: CGRect(
            x: mistCenter.x - mistWidth / 2,
            y: mistCenter.y - mistHeight / 2,
            width: mistWidth,
            height: mistHeight
          )
        ),
        with: .color(
          Color(red: 0.72, green: 0.48, blue: 0.29).opacity(
            (0.035 + Double(index % 3) * 0.012) * power)
        )
      )
    }

    let earthSeal = Path(
      ellipseIn: CGRect(
        x: sealCenter.x - sealRadius,
        y: sealCenter.y - sealRadius,
        width: sealRadius * 2,
        height: sealRadius * 2
      )
    )
    var sealedEarth = context
    sealedEarth.clip(to: earthSeal)

    for ring in 0..<3 {
      let radius = sealRadius * (0.72 + CGFloat(ring) * 0.14)
      context.stroke(
        Path(
          ellipseIn: CGRect(
            x: sealCenter.x - radius,
            y: sealCenter.y - radius,
            width: radius * 2,
            height: radius * 2
          )
        ),
        with: .color(
          element.color.opacity((0.11 + Double(2 - ring) * 0.035) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.65 + CGFloat(2 - ring) * 0.35,
          dash: ring == 2 ? [10, 7, 2, 7] : []
        )
      )
    }

    for index in 0..<12 {
      let angle = Double(index) * 2 * .pi / 12 - .pi / 2
      var meridian = Path()
      meridian.move(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * sealRadius * 0.22,
          y: sealCenter.y + sin(angle) * sealRadius * 0.22
        )
      )
      meridian.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * sealRadius,
          y: sealCenter.y + sin(angle) * sealRadius
        )
      )
      context.stroke(
        meridian,
        with: .color(element.color.opacity((0.08 + Double(index % 3) * 0.025) * power)),
        style: StrokeStyle(
          lineWidth: index.isMultiple(of: 3) ? 1.15 : 0.48,
          dash: index.isMultiple(of: 3) ? [] : [5, 7]
        )
      )
    }

    let ground = CGRect(
      x: 0,
      y: size.height * 0.66,
      width: size.width,
      height: size.height * 0.34
    )
    context.fill(
      Path(ground),
      with: .linearGradient(
        Gradient(colors: [
          Color(red: 0.42, green: 0.24, blue: 0.11).opacity(0.11 * power),
          Color(red: 0.12, green: 0.055, blue: 0.025).opacity(0.34),
        ]),
        startPoint: CGPoint(x: ground.midX, y: ground.minY),
        endPoint: CGPoint(x: ground.midX, y: ground.maxY)
      )
    )

    for ridge in 0..<4 {
      let parallax =
        sin(time * (0.085 + Double(ridge) * 0.023) + Double(ridge) * 1.3)
        * size.width * (0.008 + CGFloat(ridge) * 0.003)
      let lift =
        cos(time * (0.16 + Double(ridge) * 0.025) + Double(ridge) * 0.9)
        * size.height * (0.004 + CGFloat(ridge) * 0.0015)
      let y = size.height * (0.48 + CGFloat(ridge) * 0.1) + lift
      var mountains = Path()
      mountains.move(to: CGPoint(x: 0, y: size.height))
      mountains.addLine(to: CGPoint(x: 0, y: y))
      let pointCount = 14
      for peak in 0...pointCount {
        let fraction = CGFloat(peak) / CGFloat(pointCount)
        let xJitter =
          peak == 0 || peak == pointCount
          ? 0
          : sin(Double(peak * 11 + ridge * 17)) * Double(size.width) * 0.012
        let x = size.width * fraction + CGFloat(xJitter) + parallax
        let hash = abs(sin(Double((peak + 3) * (ridge + 5)) * 1.913))
        let accent = (peak + ridge * 2) % 6 == 0 ? 0.11 : 0
        let prominence = 0.025 + hash * (0.08 + Double(3 - ridge) * 0.022) + accent
        let peakY = y - size.height * CGFloat(prominence)
        mountains.addLine(to: CGPoint(x: x, y: peakY))
      }
      mountains.addLine(to: CGPoint(x: size.width, y: size.height))
      mountains.closeSubpath()
      sealedEarth.fill(
        mountains,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.72, green: 0.46, blue: 0.25).opacity(
              (0.1 + Double(3 - ridge) * 0.036) * power),
            Color(red: 0.18, green: 0.085, blue: 0.036).opacity(
              0.18 + Double(ridge) * 0.075),
          ]),
          startPoint: CGPoint(x: size.width / 2, y: y - size.height * 0.12),
          endPoint: CGPoint(x: size.width / 2, y: size.height)
        )
      )
      sealedEarth.stroke(
        mountains,
        with: .color(
          Color(red: 0.9, green: 0.65, blue: 0.36).opacity(
            (0.1 + Double(3 - ridge) * 0.035) * power)),
        style: StrokeStyle(lineWidth: 0.8 + CGFloat(ridge) * 0.42, lineJoin: .round)
      )
    }

    for ridge in 0..<3 {
      let baseline = size.height * (0.72 + CGFloat(ridge) * 0.085)
      let amplitude = size.height * (0.022 + CGFloat(ridge) * 0.006)
      var contour = Path()
      for point in 0...80 {
        let fraction = CGFloat(point) / 80
        let hash = abs(sin(Double(point + ridge * 11) * 0.73))
        let accent = (point + ridge) % 17 == 0 ? 0.7 : 0
        let y = baseline - amplitude * CGFloat(0.18 + hash * 0.58 + accent)
        let contourPoint = CGPoint(x: size.width * fraction, y: y)
        point == 0 ? contour.move(to: contourPoint) : contour.addLine(to: contourPoint)
      }
      context.stroke(
        contour,
        with: .color(element.color.opacity((0.055 + Double(ridge) * 0.018) * power)),
        style: StrokeStyle(lineWidth: 0.7 + CGFloat(ridge) * 0.28, lineJoin: .round)
      )
    }

    for index in 0..<16 {
      let angle = -.pi * 0.96 + Double(index) / 15 * .pi * 0.92
      var crack = Path()
      crack.move(to: epicenter)
      var current = epicenter
      for step in 1...6 {
        let length = CGFloat(step) * size.height * 0.055
        current = CGPoint(
          x: epicenter.x + cos(angle) * length + sin(Double(step * index) * 2.1) * 11,
          y: epicenter.y - sin(angle) * length
        )
        crack.addLine(to: current)
      }
      var glow = context
      glow.addFilter(.blur(radius: 5))
      glow.stroke(
        crack,
        with: .color(element.color.opacity(0.1 * power)),
        lineWidth: 5
      )
      context.stroke(
        crack,
        with: .color(element.color.opacity((0.2 + Double(index % 3) * 0.07) * power)),
        lineWidth: 0.7 + CGFloat(index % 3) * 0.5
      )
    }
  }

}
