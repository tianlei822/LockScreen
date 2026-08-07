import SwiftUI

/// Full-door anime-style phenomena synchronized with the currently active phase.
struct FivePhaseAnimeBackdrop: View {
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    let cycle = FivePhaseCycleState(time: time)

    GeometryReader { proxy in
      ZStack {
        ForEach(FivePhaseElement.allCases) { element in
          ElementalAnimeScene(
            element: element,
            size: proxy.size,
            time: time,
            energy: energy,
            isActivated: isActivated
          )
          .opacity(cycle.opacity(for: element))
        }
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
  }
}

private struct ElementalAnimeScene: View {
  let element: FivePhaseElement
  let size: CGSize
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    let power = (isActivated ? 1.3 : 0.72 + energy * 0.38)

    ZStack {
      RadialGradient(
        colors: [
          element.color.opacity(0.1 * power),
          element.color.opacity(0.025 * power),
          .clear,
        ],
        center: sceneCenter,
        startRadius: 0,
        endRadius: max(size.width, size.height) * 0.7
      )

      Canvas { context, canvasSize in
        switch element {
        case .wood:
          drawWood(in: &context, size: canvasSize, power: power)
        case .fire:
          drawFire(in: &context, size: canvasSize, power: power)
        case .earth:
          drawEarth(in: &context, size: canvasSize, power: power)
        case .metal:
          drawMetal(in: &context, size: canvasSize, power: power)
        case .water:
          drawWater(in: &context, size: canvasSize, power: power)
        }
      }
    }
    .blendMode(element == .earth ? .normal : .plusLighter)
  }

  private var sceneCenter: UnitPoint {
    switch element {
    case .wood: UnitPoint(x: 0.5, y: 0.72)
    case .fire: UnitPoint(x: 0.5, y: 0.78)
    case .earth: UnitPoint(x: 0.5, y: 0.68)
    case .metal: .center
    case .water: UnitPoint(x: 0.5, y: 0.56)
    }
  }

  private func drawWood(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    for index in 0..<11 {
      let fraction = CGFloat(index) / 10
      let start = CGPoint(x: size.width * (0.12 + fraction * 0.76), y: size.height * 1.04)
      let crownX = size.width * (0.5 + sin(Double(index) * 1.7 + time * 0.22) * 0.42)
      let crownY = size.height * (0.1 + CGFloat(index % 4) * 0.07)
      var vine = Path()
      vine.move(to: start)
      vine.addCurve(
        to: CGPoint(x: crownX, y: crownY),
        control1: CGPoint(
          x: start.x + sin(time * 0.42 + Double(index)) * size.width * 0.12,
          y: size.height * 0.76
        ),
        control2: CGPoint(
          x: crownX - cos(time * 0.35 + Double(index)) * size.width * 0.16,
          y: size.height * 0.35
        )
      )

      var glow = context
      glow.addFilter(.blur(radius: 8))
      glow.stroke(
        vine,
        with: .color(element.color.opacity((0.06 + Double(index % 3) * 0.025) * power)),
        style: StrokeStyle(lineWidth: 7 + CGFloat(index % 4) * 2, lineCap: .round)
      )
      context.stroke(
        vine,
        with: .color(element.color.opacity((0.16 + Double(index % 3) * 0.05) * power)),
        style: StrokeStyle(
          lineWidth: 0.7 + CGFloat(index.isMultiple(of: 3) ? 1.4 : 0.45),
          lineCap: .round
        )
      )

      for node in 1...3 {
        let nodeFraction = CGFloat(node) / 4
        let x =
          start.x + (crownX - start.x) * nodeFraction
          + sin(time * 0.7 + Double(index * node)) * 12
        let y = start.y + (crownY - start.y) * nodeFraction
        let radius = CGFloat(1.4 + Double((index + node) % 3))
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: x - radius,
              y: y - radius,
              width: radius * 2,
              height: radius * 2
            )),
          with: .color(Color.white.opacity(0.18 * power))
        )

        let leafLength = CGFloat(10 + (index + node) % 4 * 3)
        let leaf = leafPath(
          center: CGPoint(x: x + (node.isMultiple(of: 2) ? -5 : 5), y: y - 2),
          length: leafLength,
          angle: Double(index * 3 + node) * 0.62 + sin(time * 0.5) * 0.18
        )
        context.fill(
          leaf,
          with: .linearGradient(
            Gradient(colors: [Color.white.opacity(0.55), element.color, Color.green.opacity(0.28)]),
            startPoint: CGPoint(x: x, y: y - leafLength / 2),
            endPoint: CGPoint(x: x, y: y + leafLength / 2)
          )
        )
        context.stroke(
          leaf,
          with: .color(Color(red: 0.025, green: 0.24, blue: 0.1).opacity(0.72 * power)),
          lineWidth: 0.55
        )
        context.stroke(
          leafVeinPath(
            center: CGPoint(x: x + (node.isMultiple(of: 2) ? -5 : 5), y: y - 2),
            length: leafLength,
            angle: Double(index * 3 + node) * 0.62 + sin(time * 0.5) * 0.18
          ),
          with: .color(Color.white.opacity(0.24 * power)),
          lineWidth: 0.42
        )
      }
    }
  }

  private func drawFire(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let sealCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.53)
    let sealRadius = min(size.width, size.height) * 0.3

    for ring in 0..<3 {
      let radius = sealRadius * (0.74 + CGFloat(ring) * 0.13)
      let ringRect = CGRect(
        x: sealCenter.x - radius,
        y: sealCenter.y - radius,
        width: radius * 2,
        height: radius * 2
      )
      var ringGlow = context
      ringGlow.addFilter(.blur(radius: 5 + CGFloat(ring) * 2))
      ringGlow.stroke(
        Path(ellipseIn: ringRect),
        with: .color(Color.red.opacity((0.08 + Double(ring) * 0.025) * power)),
        lineWidth: 7 - CGFloat(ring)
      )
      context.stroke(
        Path(ellipseIn: ringRect),
        with: .color(
          (ring == 1 ? Color.orange : element.color)
            .opacity((0.2 + Double(2 - ring) * 0.07) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.9 + CGFloat(2 - ring) * 0.45,
          dash: ring == 2 ? [12, 7, 3, 7] : []
        )
      )
    }

    for index in 0..<24 {
      let angle = Double(index) * 2 * .pi / 24 - time * 0.08
      let innerRadius = sealRadius * (index.isMultiple(of: 3) ? 0.84 : 0.9)
      let outerRadius = sealRadius * (index.isMultiple(of: 4) ? 1.02 : 0.97)
      var rune = Path()
      rune.move(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * innerRadius,
          y: sealCenter.y + sin(angle) * innerRadius
        )
      )
      rune.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle + 0.025) * outerRadius,
          y: sealCenter.y + sin(angle + 0.025) * outerRadius
        )
      )
      context.stroke(
        rune,
        with: .color(
          (index.isMultiple(of: 6) ? Color.white : Color.orange)
            .opacity((0.19 + Double(index % 4) * 0.035) * power)
        ),
        style: StrokeStyle(lineWidth: index.isMultiple(of: 4) ? 2.1 : 0.8, lineCap: .round)
      )
    }

    let solarRadius = sealRadius * 0.25
    let auraRect = CGRect(
      x: sealCenter.x - solarRadius * 2.8,
      y: sealCenter.y - solarRadius * 2.8,
      width: solarRadius * 5.6,
      height: solarRadius * 5.6
    )
    var solarAura = context
    solarAura.addFilter(.blur(radius: 24))
    solarAura.fill(
      Path(ellipseIn: auraRect),
      with: .radialGradient(
        Gradient(colors: [
          Color.yellow.opacity(0.35 * power),
          Color.orange.opacity(0.22 * power),
          Color.red.opacity(0.08 * power),
          .clear,
        ]),
        center: sealCenter,
        startRadius: 0,
        endRadius: solarRadius * 2.75
      )
    )

    for index in 0..<28 {
      let seed = Double(index + 1)
      let angle = seed * 2 * Double.pi / 28 + time * 0.045
      let innerRadius = solarRadius * 0.9
      let variation = seed.truncatingRemainder(dividingBy: 6) * 0.07
      let pulse = sin(time * 1.45 + seed * 1.7) * 0.065
      let outerRadius = solarRadius * CGFloat(1.38 + variation + pulse)
      let halfWidth: Double = Double.pi / 72
      var ray = Path()
      ray.move(
        to: CGPoint(
          x: sealCenter.x + cos(angle - halfWidth) * innerRadius,
          y: sealCenter.y + sin(angle - halfWidth) * innerRadius
        )
      )
      ray.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * outerRadius,
          y: sealCenter.y + sin(angle) * outerRadius
        )
      )
      ray.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle + halfWidth) * innerRadius,
          y: sealCenter.y + sin(angle + halfWidth) * innerRadius
        )
      )
      ray.closeSubpath()
      context.fill(
        ray,
        with: .color(
          (index.isMultiple(of: 4) ? Color.yellow : Color.orange)
            .opacity((0.22 + Double(index % 3) * 0.055) * power)
        )
      )
    }

    let sunRect = CGRect(
      x: sealCenter.x - solarRadius,
      y: sealCenter.y - solarRadius,
      width: solarRadius * 2,
      height: solarRadius * 2
    )
    context.fill(
      Path(ellipseIn: sunRect),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.56 * power),
          Color.yellow.opacity(0.5 * power),
          Color.orange.opacity(0.34 * power),
          Color.red.opacity(0.16 * power),
        ]),
        center: CGPoint(x: sealCenter.x - solarRadius * 0.22, y: sealCenter.y - solarRadius * 0.2),
        startRadius: 0,
        endRadius: solarRadius
      )
    )

    for index in 0..<5 {
      let startAngle = Double(index) * 1.18 + time * (index.isMultiple(of: 2) ? 0.07 : -0.055)
      var prominence = Path()
      prominence.addArc(
        center: sealCenter,
        radius: solarRadius * (1.08 + CGFloat(index) * 0.075),
        startAngle: .radians(startAngle),
        endAngle: .radians(startAngle + 0.56 + Double(index % 3) * 0.11),
        clockwise: false
      )
      var prominenceGlow = context
      prominenceGlow.addFilter(.blur(radius: 7))
      prominenceGlow.stroke(
        prominence,
        with: .color(Color.orange.opacity(0.3 * power)),
        style: StrokeStyle(lineWidth: 7, lineCap: .round)
      )
      context.stroke(
        prominence,
        with: .color(Color.yellow.opacity(0.48 * power)),
        style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
      )
    }

    for index in 0..<7 {
      let seed = Double(index + 1)
      let base = CGPoint(
        x: sealCenter.x + CGFloat(index - 3) * sealRadius * 0.16,
        y: sealCenter.y + sealRadius * (0.43 + CGFloat(abs(index - 3)) * 0.018)
      )
      let flame = fireBackdropFlamePath(
        base: base,
        width: sealRadius * CGFloat(0.27 + seed.truncatingRemainder(dividingBy: 3) * 0.045),
        height: sealRadius * CGFloat(0.42 + seed.truncatingRemainder(dividingBy: 4) * 0.07),
        phase: time * (1.3 + seed * 0.03) + seed
      )
      var flameGlow = context
      flameGlow.addFilter(.blur(radius: 10))
      flameGlow.fill(flame, with: .color(Color.orange.opacity(0.22 * power)))
      context.fill(
        flame,
        with: .linearGradient(
          Gradient(colors: [
            Color.yellow.opacity(0.5 * power),
            Color.orange.opacity(0.44 * power),
            Color.red.opacity(0.16 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: base.x, y: base.y - sealRadius * 0.5),
          endPoint: base
        )
      )
    }

    for index in 0..<9 {
      let x = size.width * (0.08 + CGFloat(index) * 0.105)
      let height = size.height * (0.18 + CGFloat(index % 4) * 0.045)
      let flame = fireBackdropFlamePath(
        base: CGPoint(x: x, y: size.height * 1.04),
        width: 76 + CGFloat(index % 3) * 18,
        height: height,
        phase: time * (1.18 + Double(index % 4) * 0.08) + Double(index) * 0.73
      )

      var aura = context
      aura.addFilter(.blur(radius: 14))
      aura.fill(
        flame,
        with: .color(Color.orange.opacity((0.045 + Double(index % 3) * 0.018) * power))
      )
      context.fill(
        flame,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.52, green: 0.008, blue: 0.003).opacity(0.16 * power),
            Color.orange.opacity((0.18 + Double(index % 3) * 0.035) * power),
            Color.yellow.opacity(0.1 * power),
          ]),
          startPoint: CGPoint(x: x, y: size.height),
          endPoint: CGPoint(x: x, y: size.height - height)
        )
      )
      let innerFlame = fireBackdropFlamePath(
        base: CGPoint(x: x + CGFloat(index % 2 == 0 ? -4 : 5), y: size.height * 1.04),
        width: 34 + CGFloat(index % 3) * 8,
        height: height * 0.64,
        phase: time * (1.45 + Double(index % 3) * 0.09) + Double(index) * 1.13
      )
      context.fill(
        innerFlame,
        with: .linearGradient(
          Gradient(colors: [
            Color.orange.opacity(0.22 * power),
            Color.yellow.opacity(0.28 * power),
            Color.white.opacity(0.07 * power),
          ]),
          startPoint: CGPoint(x: x, y: size.height),
          endPoint: CGPoint(x: x, y: size.height - height * 0.62)
        )
      )
    }

    for index in 0..<34 {
      let seed = Double(index + 1)
      let x = size.width * CGFloat(abs(sin(seed * 18.31)).truncatingRemainder(dividingBy: 1))
      let travel = (time * (22 + seed.truncatingRemainder(dividingBy: 18)) + seed * 31)
        .truncatingRemainder(dividingBy: Double(size.height))
      let y = size.height - travel
      let radius = CGFloat(0.7 + seed.truncatingRemainder(dividingBy: 3) * 0.5)
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
        with: .color(Color.orange.opacity((0.12 + Double(index % 4) * 0.04) * power))
      )
    }
  }

  private func drawEarth(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let epicenter = CGPoint(x: size.width / 2, y: size.height * 0.7)
    let sealCenter = CGPoint(x: size.width / 2, y: size.height * 0.54)
    let sealRadius = min(size.width, size.height) * 0.31

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

  private func drawMetal(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    let reach = min(size.width, size.height) * 0.46
    let unit = min(size.width, size.height)

    var alloyAura = context
    alloyAura.addFilter(.blur(radius: 42))
    alloyAura.fill(
      Path(
        ellipseIn: CGRect(
          x: center.x - unit * 0.42,
          y: center.y - unit * 0.42,
          width: unit * 0.84,
          height: unit * 0.84
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.08 * power),
          Color(red: 0.24, green: 0.72, blue: 0.56).opacity(0.09 * power),
          Color(red: 0.015, green: 0.2, blue: 0.13).opacity(0.04 * power),
          .clear,
        ]),
        center: center,
        startRadius: 0,
        endRadius: unit * 0.42
      )
    )

    for index in 0..<10 {
      let angle = Double(index) * 2 * Double.pi / 10 + time * 0.04
      let orbit = reach * (0.84 + CGFloat(index % 3) * 0.07)
      let ghostCenter = CGPoint(
        x: center.x + cos(angle) * orbit,
        y: center.y + sin(angle) * orbit
      )
      let ghostLength = unit * (0.28 + CGFloat(index % 4) * 0.026)
      let ghostWidth = ghostLength * 0.16
      let ghost = spiritSwordPath(
        center: ghostCenter,
        length: ghostLength,
        width: ghostWidth,
        angle: angle + Double.pi / 2
      )
      var ghostLayer = context
      ghostLayer.addFilter(.blur(radius: 15 + CGFloat(index % 3) * 5))
      ghostLayer.fill(
        ghost,
        with: .color(
          (index.isMultiple(of: 3) ? Color.white : element.color)
            .opacity((0.045 + Double(index % 3) * 0.014) * power)
        )
      )
    }

    for index in 0..<8 {
      let angle = Double(index) * Double.pi / 4 - time * 0.025
      var beam = Path()
      beam.move(to: center)
      beam.addLine(
        to: CGPoint(
          x: center.x + cos(angle) * reach * 1.55,
          y: center.y + sin(angle) * reach * 1.55
        )
      )
      var beamGlow = context
      beamGlow.addFilter(.blur(radius: 16))
      beamGlow.stroke(
        beam,
        with: .color(
          Color(red: 0.5, green: 0.92, blue: 0.78).opacity(
            (0.035 + Double(index % 2) * 0.018) * power)
        ),
        style: StrokeStyle(lineWidth: 18 + CGFloat(index % 3) * 5, lineCap: .round)
      )
    }

    for ring in 0..<2 {
      let count = ring == 0 ? 10 : 6
      let direction = ring == 0 ? 1.0 : -1.0
      let rotation = time * (ring == 0 ? 0.17 : -0.27)

      for index in 0..<count {
        let angle = Double(index) * 2 * .pi / Double(count) + rotation
        let bob = sin(time * 1.45 + Double(index) * 1.31 + Double(ring))
        let orbit = reach * (ring == 0 ? 0.72 : 0.4) + bob * reach * 0.035
        let swordCenter = CGPoint(
          x: center.x + cos(angle) * orbit,
          y: center.y + sin(angle) * orbit
        )
        let length = min(size.width, size.height) * (ring == 0 ? 0.2 : 0.14)
        let width = length * 0.115
        let bank = sin(time * 1.1 + Double(index) * 0.77) * 0.11
        let swordAngle = angle + .pi / 2 + bank
        let sword = spiritSwordPath(
          center: swordCenter,
          length: length,
          width: width,
          angle: swordAngle
        )

        let trailAngle = angle - direction * .pi / 2
        var trail = Path()
        trail.move(to: swordCenter)
        trail.addCurve(
          to: CGPoint(
            x: swordCenter.x + cos(trailAngle) * length * 0.72,
            y: swordCenter.y + sin(trailAngle) * length * 0.72
          ),
          control1: CGPoint(
            x: swordCenter.x + cos(trailAngle) * length * 0.24,
            y: swordCenter.y + sin(trailAngle) * length * 0.24
          ),
          control2: CGPoint(
            x: swordCenter.x + cos(trailAngle + direction * 0.22) * length * 0.52,
            y: swordCenter.y + sin(trailAngle + direction * 0.22) * length * 0.52
          )
        )
        var trailGlow = context
        trailGlow.addFilter(.blur(radius: 5))
        trailGlow.stroke(
          trail,
          with: .color(element.color.opacity(0.13 * power)),
          style: StrokeStyle(lineWidth: ring == 0 ? 5 : 3, lineCap: .round)
        )

        var glow = context
        glow.addFilter(.blur(radius: 7))
        glow.fill(sword, with: .color(element.color.opacity(0.15 * power)))
        context.fill(
          sword,
          with: .linearGradient(
            Gradient(colors: [
              Color.white.opacity(0.9 * power),
              element.color.opacity(0.72 * power),
              Color(red: 0.02, green: 0.2, blue: 0.13).opacity(0.82 * power),
            ]),
            startPoint: rotatedPoint(
              x: -width * 0.8, y: 0, around: swordCenter, angle: swordAngle),
            endPoint: rotatedPoint(
              x: width * 0.8, y: 0, around: swordCenter, angle: swordAngle)
          )
        )
        context.stroke(
          sword,
          with: .color(Color.white.opacity((0.3 + Double(index % 3) * 0.08) * power)),
          lineWidth: ring == 0 ? 0.85 : 0.6
        )
        context.stroke(
          spiritSwordDetailPath(
            center: swordCenter,
            length: length,
            width: width,
            angle: swordAngle
          ),
          with: .color(Color(red: 0.02, green: 0.3, blue: 0.18).opacity(0.86 * power)),
          style: StrokeStyle(lineWidth: 0.5, lineCap: .round)
        )
      }
    }
  }

  private func drawWater(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
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

  private func leafPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
    let halfLength = length / 2
    let halfWidth = length * 0.24
    let top = rotatedPoint(x: 0, y: -halfLength, around: center, angle: angle)
    let bottom = rotatedPoint(x: 0, y: halfLength, around: center, angle: angle)
    let right = rotatedPoint(x: halfWidth, y: 0, around: center, angle: angle)
    let left = rotatedPoint(x: -halfWidth, y: 0, around: center, angle: angle)

    return Path { path in
      path.move(to: top)
      path.addQuadCurve(to: bottom, control: right)
      path.addQuadCurve(to: top, control: left)
      path.move(to: top)
      path.addLine(to: bottom)
    }
  }

  private func fireBackdropFlamePath(
    base: CGPoint,
    width: CGFloat,
    height: CGFloat,
    phase: Double
  ) -> Path {
    let drift = CGFloat(sin(phase)) * width * 0.34
    let shoulder = CGFloat(cos(phase * 0.71)) * width * 0.14
    return Path { path in
      path.move(to: CGPoint(x: base.x - width / 2, y: base.y))
      path.addCurve(
        to: CGPoint(x: base.x - width * 0.18 + shoulder, y: base.y - height * 0.46),
        control1: CGPoint(x: base.x - width * 0.64, y: base.y - height * 0.16),
        control2: CGPoint(x: base.x - width * 0.42, y: base.y - height * 0.38)
      )
      path.addCurve(
        to: CGPoint(x: base.x + drift, y: base.y - height),
        control1: CGPoint(x: base.x - width * 0.06, y: base.y - height * 0.68),
        control2: CGPoint(x: base.x + drift - width * 0.2, y: base.y - height * 0.88)
      )
      path.addCurve(
        to: CGPoint(x: base.x + width * 0.2 - shoulder, y: base.y - height * 0.38),
        control1: CGPoint(x: base.x + drift + width * 0.24, y: base.y - height * 0.82),
        control2: CGPoint(x: base.x + width * 0.36, y: base.y - height * 0.58)
      )
      path.addCurve(
        to: CGPoint(x: base.x + width / 2, y: base.y),
        control1: CGPoint(x: base.x + width * 0.48, y: base.y - height * 0.24),
        control2: CGPoint(x: base.x + width * 0.64, y: base.y - height * 0.12)
      )
      path.closeSubpath()
    }
  }

  private func fireSpiritBackdropPath(
    center: CGPoint,
    scale: CGFloat,
    phase: Double
  ) -> Path {
    let drift = CGFloat(sin(phase)) * scale * 0.012
    return Path { path in
      path.move(to: CGPoint(x: center.x - scale * 0.32, y: center.y + scale * 0.32))
      path.addCurve(
        to: CGPoint(x: center.x - scale * 0.27, y: center.y - scale * 0.08),
        control1: CGPoint(x: center.x - scale * 0.5, y: center.y + scale * 0.22),
        control2: CGPoint(x: center.x - scale * 0.48, y: center.y - scale * 0.18)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.12 + drift, y: center.y + scale * 0.08),
        control1: CGPoint(x: center.x - scale * 0.08, y: center.y - scale * 0.32),
        control2: CGPoint(x: center.x + scale * 0.36, y: center.y - scale * 0.2)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.04, y: center.y - scale * 0.23),
        control1: CGPoint(x: center.x - scale * 0.06, y: center.y + scale * 0.26),
        control2: CGPoint(x: center.x + scale * 0.38, y: center.y + scale * 0.05)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.23 + drift, y: center.y - scale * 0.26),
        control1: CGPoint(x: center.x - scale * 0.04, y: center.y - scale * 0.39),
        control2: CGPoint(x: center.x + scale * 0.14, y: center.y - scale * 0.4)
      )
    }
  }

  private func fireSpiritBackdropSpines(
    center: CGPoint,
    scale: CGFloat,
    phase: Double
  ) -> Path {
    let flicker = CGFloat(sin(phase * 1.7)) * scale * 0.01
    let fins = [
      (-0.36, 0.24, -0.08, -0.08),
      (-0.39, 0.08, -0.08, -0.06),
      (-0.29, -0.11, -0.03, -0.1),
      (-0.12, -0.18, 0.01, -0.11),
      (0.1, -0.1, 0.08, -0.07),
      (0.16, 0.02, 0.09, -0.045),
      (0.03, -0.26, -0.01, -0.11),
    ]
    return Path { path in
      for fin in fins {
        path.move(
          to: CGPoint(
            x: center.x + scale * fin.0,
            y: center.y + scale * fin.1
          )
        )
        path.addLine(
          to: CGPoint(
            x: center.x + scale * (fin.0 + fin.2) + flicker,
            y: center.y + scale * (fin.1 + fin.3)
          )
        )
      }

      path.move(to: CGPoint(x: center.x - scale * 0.32, y: center.y + scale * 0.32))
      path.addCurve(
        to: CGPoint(x: center.x - scale * 0.5, y: center.y + scale * 0.42),
        control1: CGPoint(x: center.x - scale * 0.39, y: center.y + scale * 0.28),
        control2: CGPoint(x: center.x - scale * 0.47, y: center.y + scale * 0.34)
      )
      path.move(to: CGPoint(x: center.x - scale * 0.31, y: center.y + scale * 0.32))
      path.addCurve(
        to: CGPoint(x: center.x - scale * 0.4, y: center.y + scale * 0.5),
        control1: CGPoint(x: center.x - scale * 0.28, y: center.y + scale * 0.39),
        control2: CGPoint(x: center.x - scale * 0.34, y: center.y + scale * 0.46)
      )
    }
  }

  private func fireSpiritBackdropHead(center: CGPoint, scale: CGFloat) -> Path {
    let points = [
      CGPoint(x: -0.52, y: 0.18),
      CGPoint(x: -0.25, y: -0.05),
      CGPoint(x: 0.0, y: -0.14),
      CGPoint(x: 0.3, y: -0.12),
      CGPoint(x: 0.54, y: 0.0),
      CGPoint(x: 0.4, y: 0.1),
      CGPoint(x: 0.58, y: 0.24),
      CGPoint(x: 0.18, y: 0.18),
      CGPoint(x: 0.02, y: 0.42),
      CGPoint(x: -0.16, y: 0.2),
    ].map { point in
      CGPoint(x: center.x + point.x * scale, y: center.y + point.y * scale)
    }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() {
        path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func fireSpiritBackdropHeadDetails(center: CGPoint, scale: CGFloat) -> Path {
    Path { path in
      path.move(
        to: CGPoint(x: center.x - scale * 0.04, y: center.y - scale * 0.05)
      )
      path.addLine(
        to: CGPoint(x: center.x + scale * 0.22, y: center.y - scale * 0.02)
      )
      path.addLine(
        to: CGPoint(x: center.x + scale * 0.1, y: center.y + scale * 0.07)
      )

      path.move(
        to: CGPoint(x: center.x + scale * 0.18, y: center.y + scale * 0.2)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.58, y: center.y + scale * 0.14),
        control1: CGPoint(x: center.x + scale * 0.34, y: center.y + scale * 0.25),
        control2: CGPoint(x: center.x + scale * 0.47, y: center.y + scale * 0.15)
      )

      path.move(
        to: CGPoint(x: center.x - scale * 0.22, y: center.y - scale * 0.08)
      )
      path.addLine(
        to: CGPoint(x: center.x - scale * 0.34, y: center.y - scale * 0.46)
      )
      path.move(
        to: CGPoint(x: center.x + scale * 0.02, y: center.y - scale * 0.1)
      )
      path.addLine(
        to: CGPoint(x: center.x + scale * 0.14, y: center.y - scale * 0.5)
      )
    }
  }

  private func snowCrystalPath(
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

  private func leafVeinPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
    Path { path in
      let top = rotatedPoint(x: 0, y: -length * 0.38, around: center, angle: angle)
      let bottom = rotatedPoint(x: 0, y: length * 0.4, around: center, angle: angle)
      path.move(to: top)
      path.addLine(to: bottom)

      for index in 0..<3 {
        let y = -length * 0.18 + CGFloat(index) * length * 0.19
        let reach = length * (0.18 - CGFloat(index) * 0.025)
        let node = rotatedPoint(x: 0, y: y, around: center, angle: angle)
        path.move(to: node)
        path.addLine(
          to: rotatedPoint(x: -reach, y: y - length * 0.1, around: center, angle: angle)
        )
        path.move(to: node)
        path.addLine(
          to: rotatedPoint(x: reach, y: y - length * 0.07, around: center, angle: angle)
        )
      }
    }
  }

  private func spiritSwordPath(
    center: CGPoint,
    length: CGFloat,
    width: CGFloat,
    angle: Double
  ) -> Path {
    let points = [
      CGPoint(x: 0, y: -length * 0.5),
      CGPoint(x: width * 0.34, y: length * 0.14),
      CGPoint(x: width * 0.17, y: length * 0.25),
      CGPoint(x: width * 0.82, y: length * 0.28),
      CGPoint(x: width * 0.19, y: length * 0.34),
      CGPoint(x: width * 0.13, y: length * 0.47),
      CGPoint(x: 0, y: length * 0.5),
      CGPoint(x: -width * 0.13, y: length * 0.47),
      CGPoint(x: -width * 0.19, y: length * 0.34),
      CGPoint(x: -width * 0.82, y: length * 0.28),
      CGPoint(x: -width * 0.17, y: length * 0.25),
      CGPoint(x: -width * 0.34, y: length * 0.14),
    ].map { point in
      rotatedPoint(x: point.x, y: point.y, around: center, angle: angle)
    }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() {
        path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func spiritSwordDetailPath(
    center: CGPoint,
    length: CGFloat,
    width: CGFloat,
    angle: Double
  ) -> Path {
    Path { path in
      path.move(
        to: rotatedPoint(x: 0, y: -length * 0.45, around: center, angle: angle)
      )
      path.addLine(
        to: rotatedPoint(x: 0, y: length * 0.24, around: center, angle: angle)
      )
      path.move(
        to: rotatedPoint(x: -width * 0.56, y: length * 0.29, around: center, angle: angle)
      )
      path.addLine(
        to: rotatedPoint(x: width * 0.56, y: length * 0.29, around: center, angle: angle)
      )
      path.move(
        to: rotatedPoint(x: 0, y: length * 0.35, around: center, angle: angle)
      )
      path.addLine(
        to: rotatedPoint(x: 0, y: length * 0.46, around: center, angle: angle)
      )
    }
  }

  private func rotatedPoint(
    x: CGFloat,
    y: CGFloat,
    around center: CGPoint,
    angle: Double
  ) -> CGPoint {
    CGPoint(
      x: center.x + x * cos(angle) - y * sin(angle),
      y: center.y + x * sin(angle) + y * cos(angle)
    )
  }
}
