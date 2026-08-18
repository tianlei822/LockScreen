import SwiftUI

extension ElementalAnimeScene {
  func drawWater(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    for oceanBand in 0..<5 {
      let baseline = size.height * (0.5 + CGFloat(oceanBand) * 0.095)
      let amplitude = size.height * (0.02 + CGFloat(oceanBand) * 0.006)
      var crest = Path()
      for pointIndex in 0...120 {
        let fraction = CGFloat(pointIndex) / 120
        let phase =
          Double(fraction) * .pi * (2.15 + Double(oceanBand) * 0.33)
          - time * (0.34 + Double(oceanBand) * 0.1)
        let swell = sin(phase)
        let detail = sin(phase * 2.7 + Double(oceanBand) * 0.8) * 0.24
        let point = CGPoint(
          x: size.width * fraction,
          y: baseline + CGFloat(swell + detail) * amplitude
        )
        pointIndex == 0 ? crest.move(to: point) : crest.addLine(to: point)
      }

      var oceanBody = crest
      oceanBody.addLine(to: CGPoint(x: size.width, y: size.height))
      oceanBody.addLine(to: CGPoint(x: 0, y: size.height))
      oceanBody.closeSubpath()
      context.fill(
        oceanBody,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.14, green: 0.54, blue: 0.92).opacity(
              (0.055 + Double(4 - oceanBand) * 0.012) * power),
            element.color.opacity((0.075 + Double(oceanBand) * 0.018) * power),
            Color(red: 0.008, green: 0.035, blue: 0.105).opacity(
              0.28 + Double(oceanBand) * 0.035),
          ]),
          startPoint: CGPoint(x: size.width / 2, y: baseline - amplitude),
          endPoint: CGPoint(x: size.width / 2, y: size.height)
        )
      )
      var oceanGlow = context
      oceanGlow.addFilter(.blur(radius: 6 + CGFloat(oceanBand) * 2))
      oceanGlow.stroke(
        crest,
        with: .color(element.color.opacity((0.07 + Double(oceanBand) * 0.015) * power)),
        style: StrokeStyle(lineWidth: 7 + CGFloat(oceanBand) * 2, lineCap: .round)
      )
      context.stroke(
        crest,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            Color.white.opacity((0.22 + Double(oceanBand % 2) * 0.08) * power),
            element.color.opacity(0.18 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: 0, y: baseline),
          endPoint: CGPoint(x: size.width, y: baseline)
        ),
        style: StrokeStyle(
          lineWidth: 0.75 + CGFloat(oceanBand % 3) * 0.48,
          lineCap: .round,
          lineJoin: .round
        )
      )
    }

    for index in 0..<110 {
      let seed = Double(index + 1)
      let xHash = abs(sin(seed * 17.731) * 4_375.3).truncatingRemainder(dividingBy: 1)
      let x = size.width * CGFloat(xHash)
      let speed = 230 + seed.truncatingRemainder(dividingBy: 7) * 31
      let travel = (time * speed + seed * 43).truncatingRemainder(
        dividingBy: Double(size.height * 1.18))
      let y = -size.height * 0.12 + CGFloat(travel)
      let length = CGFloat(11 + seed.truncatingRemainder(dividingBy: 8) * 4.2)
      let slant = length * 0.19
      var rain = Path()
      rain.move(to: CGPoint(x: x, y: y))
      rain.addLine(to: CGPoint(x: x - slant, y: y + length))

      if index.isMultiple(of: 9) {
        var rainGlow = context
        rainGlow.addFilter(.blur(radius: 3))
        rainGlow.stroke(
          rain,
          with: .color(element.color.opacity(0.2 * power)),
          style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
        )
      }
      context.stroke(
        rain,
        with: .linearGradient(
          Gradient(colors: [
            Color.white.opacity(0),
            Color.white.opacity((0.24 + Double(index % 5) * 0.08) * power),
            element.color.opacity(0.12 * power),
          ]),
          startPoint: CGPoint(x: x, y: y),
          endPoint: CGPoint(x: x - slant, y: y + length)
        ),
        style: StrokeStyle(
          lineWidth: index.isMultiple(of: 7) ? 1.25 : 0.62,
          lineCap: .round
        )
      )
    }

    for index in 0..<34 {
      let seed = Double(index + 1)
      let x =
        size.width
        * CGFloat(
          abs(sin(seed * 11.93) * 6_217).truncatingRemainder(dividingBy: 1))
      let travel = (time * (17 + seed.truncatingRemainder(dividingBy: 9)) + seed * 29)
        .truncatingRemainder(dividingBy: Double(size.height * 1.12))
      let center = CGPoint(
        x: x + sin(time * 0.55 + seed) * 16,
        y: -size.height * 0.08 + CGFloat(travel)
      )
      let radius = CGFloat(2.6 + seed.truncatingRemainder(dividingBy: 4) * 1.2)
      let flake = snowCrystalPath(center: center, radius: radius, rotation: time * 0.36 + seed)
      var flakeGlow = context
      flakeGlow.addFilter(.blur(radius: 2.5))
      flakeGlow.stroke(
        flake,
        with: .color(element.color.opacity(0.2 * power)),
        style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
      )
      context.stroke(
        flake,
        with: .color(Color.white.opacity((0.34 + Double(index % 4) * 0.065) * power)),
        style: StrokeStyle(lineWidth: 0.72, lineCap: .round)
      )
    }

    let tideCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
    let tideRadius = min(size.width, size.height) * 0.31

    for current in 0..<6 {
      let radiusX = tideRadius * (1.08 + CGFloat(current) * 0.18)
      let radiusY = tideRadius * (0.52 + CGFloat(current) * 0.08)
      let phase = time * (current.isMultiple(of: 2) ? 0.19 : -0.14) + Double(current) * 0.84
      var currentPath = Path()
      for point in 0...48 {
        let progress = Double(point) / 48
        let angle = phase + progress * (1.5 + Double(current % 3) * 0.24)
        let currentPoint = CGPoint(
          x: tideCenter.x + cos(angle) * radiusX,
          y: tideCenter.y + sin(angle) * radiusY
        )
        point == 0 ? currentPath.move(to: currentPoint) : currentPath.addLine(to: currentPoint)
      }
      var currentGlow = context
      currentGlow.addFilter(.blur(radius: 5 + CGFloat(current)))
      currentGlow.stroke(
        currentPath,
        with: .color(element.color.opacity((0.08 + Double(current % 3) * 0.025) * power)),
        style: StrokeStyle(lineWidth: 5 + CGFloat(current), lineCap: .round)
      )
      context.stroke(
        currentPath,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            Color.white.opacity(0.34 * power),
            element.color.opacity(0.32 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: tideCenter.x - radiusX, y: tideCenter.y),
          endPoint: CGPoint(x: tideCenter.x + radiusX, y: tideCenter.y)
        ),
        style: StrokeStyle(
          lineWidth: 0.8 + CGFloat(current % 3) * 0.45,
          lineCap: .round
        )
      )
    }

    let tideRect = CGRect(
      x: tideCenter.x - tideRadius,
      y: tideCenter.y - tideRadius,
      width: tideRadius * 2,
      height: tideRadius * 2
    )
    let tideSeal = Path(ellipseIn: tideRect)
    var sealedTide = context
    sealedTide.clip(to: tideSeal)

    for band in 0..<4 {
      let baseline = tideCenter.y - tideRadius * 0.1 + CGFloat(band) * tideRadius * 0.2
      let amplitude = tideRadius * (0.1 + CGFloat(band) * 0.016)
      var wave = Path()
      var foam = Path()
      var drawingFoam = false

      for point in 0...90 {
        let fraction = CGFloat(point) / 90
        let x = tideRect.minX + tideRect.width * fraction
        let phase =
          Double(fraction) * .pi * Double(2.35 + CGFloat(band) * 0.34)
          - time * (1.05 + Double(band) * 0.16)
        let primary = sin(phase)
        let chop = sin(phase * 2.3 + Double(band)) * 0.23
        let crest = max(0, primary) * 0.38
        let y = baseline + CGFloat(primary + chop - crest) * amplitude
        point == 0
          ? wave.move(to: CGPoint(x: x, y: y))
          : wave.addLine(to: CGPoint(x: x, y: y))
        if primary > 0.46 {
          drawingFoam
            ? foam.addLine(to: CGPoint(x: x, y: y))
            : foam.move(to: CGPoint(x: x, y: y))
          drawingFoam = true
        } else {
          drawingFoam = false
        }
      }

      var body = wave
      body.addLine(to: CGPoint(x: tideRect.maxX, y: tideRect.maxY))
      body.addLine(to: CGPoint(x: tideRect.minX, y: tideRect.maxY))
      body.closeSubpath()
      sealedTide.fill(
        body,
        with: .linearGradient(
          Gradient(colors: [
            Color.white.opacity((0.055 - Double(band) * 0.008) * power),
            element.color.opacity((0.11 + Double(band) * 0.028) * power),
            Color(red: 0.015, green: 0.08, blue: 0.19).opacity(0.38),
          ]),
          startPoint: CGPoint(x: tideCenter.x, y: baseline - amplitude),
          endPoint: CGPoint(x: tideCenter.x, y: tideRect.maxY)
        )
      )

      var glow = sealedTide
      glow.addFilter(.blur(radius: 5 + CGFloat(band) * 1.4))
      glow.stroke(
        wave,
        with: .color(element.color.opacity((0.1 + Double(band) * 0.02) * power)),
        lineWidth: 7 + CGFloat(band) * 1.8
      )
      sealedTide.stroke(
        wave,
        with: .color(Color.white.opacity((0.32 - Double(band) * 0.04) * power)),
        style: StrokeStyle(
          lineWidth: 1.45 - CGFloat(band) * 0.16,
          lineCap: .round,
          lineJoin: .round
        )
      )
      var foamGlow = sealedTide
      foamGlow.addFilter(.blur(radius: 4 + CGFloat(band)))
      foamGlow.stroke(
        foam,
        with: .color(Color.white.opacity((0.16 + Double(band) * 0.018) * power)),
        style: StrokeStyle(lineWidth: 6 + CGFloat(band), lineCap: .round)
      )
      sealedTide.stroke(
        foam,
        with: .color(Color.white.opacity((0.48 - Double(band) * 0.05) * power)),
        style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round)
      )
    }

    for band in 0..<3 {
      let baseline = size.height * (0.76 + CGFloat(band) * 0.075)
      let amplitude = size.height * (0.014 + CGFloat(band) * 0.004)
      var ambientWave = Path()
      for point in 0...100 {
        let fraction = CGFloat(point) / 100
        let phase =
          Double(fraction) * .pi * (2.2 + Double(band) * 0.34)
          - time * (0.62 + Double(band) * 0.11)
        let y = baseline + CGFloat(sin(phase)) * amplitude
        let point = CGPoint(x: size.width * fraction, y: y)
        point.x == 0 ? ambientWave.move(to: point) : ambientWave.addLine(to: point)
      }
      context.stroke(
        ambientWave,
        with: .color(element.color.opacity((0.07 + Double(band) * 0.02) * power)),
        style: StrokeStyle(lineWidth: 0.75 + CGFloat(band) * 0.3, lineCap: .round)
      )
    }

    context.stroke(
      tideSeal,
      with: .color(element.color.opacity(0.25 * power)),
      style: StrokeStyle(lineWidth: 1.25, dash: [11, 6, 2, 6])
    )
    context.stroke(
      Path(ellipseIn: tideRect.insetBy(dx: tideRadius * 0.11, dy: tideRadius * 0.11)),
      with: .color(Color.white.opacity(0.1 * power)),
      lineWidth: 0.65
    )

    for index in 0..<10 {
      let angle = Double(index) * 2 * .pi / 10 - .pi / 2
      var connector = Path()
      connector.move(
        to: CGPoint(
          x: tideCenter.x + cos(angle) * tideRadius * 0.3,
          y: tideCenter.y + sin(angle) * tideRadius * 0.3
        )
      )
      connector.addLine(
        to: CGPoint(
          x: tideCenter.x + cos(angle) * tideRadius,
          y: tideCenter.y + sin(angle) * tideRadius
        )
      )
      context.stroke(
        connector,
        with: .color(element.color.opacity((0.08 + Double(index % 3) * 0.025) * power)),
        style: StrokeStyle(lineWidth: index.isMultiple(of: 2) ? 0.9 : 0.45, dash: [5, 7])
      )
    }

    for index in 0..<18 {
      let seed = Double(index + 1)
      let x =
        tideRect.minX + tideRect.width
        * CGFloat(
          abs(sin(seed * 27.17)).truncatingRemainder(dividingBy: 1)
        )
      let y =
        tideCenter.y + tideRadius
        * CGFloat(
          0.16 + seed.truncatingRemainder(dividingBy: 5) * 0.105
        )
      let ripplePhase =
        (time * (0.7 + seed.truncatingRemainder(dividingBy: 3) * 0.12)
        + seed * 0.23).truncatingRemainder(dividingBy: 1)
      let radius = CGFloat(5 + ripplePhase * (24 + seed.truncatingRemainder(dividingBy: 17)))
      let rippleRect = CGRect(
        x: x - radius,
        y: y - radius * 0.18,
        width: radius * 2,
        height: radius * 0.36
      )
      context.stroke(
        Path(ellipseIn: rippleRect),
        with: .color(element.color.opacity((1 - ripplePhase) * 0.34 * power)),
        lineWidth: 0.75
      )
    }
  }

  func snowCrystalPath(
    center: CGPoint,
    radius: CGFloat,
    rotation: Double
  ) -> Path {
    Path { path in
      for arm in 0..<3 {
        let angle = rotation + Double(arm) * .pi / 3
        path.move(
          to: CGPoint(x: center.x - cos(angle) * radius, y: center.y - sin(angle) * radius)
        )
        path.addLine(
          to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        )
      }
    }
  }

}
