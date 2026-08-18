import SwiftUI

extension ElementalAnimeScene {
  func drawFire(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let sealCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.53)
    let sealRadius = min(size.width, size.height) * 0.3
    let fierceSunCenter = CGPoint(
      x: size.width * 0.79 + sin(time * 0.055) * size.width * 0.012,
      y: size.height * 0.2 + cos(time * 0.07) * size.height * 0.009
    )
    let fierceSunPulse = 0.88 + CGFloat(0.5 + 0.5 * sin(time * 1.7)) * 0.12
    let fierceSunRadius = min(size.width, size.height) * 0.105 * fierceSunPulse

    var fierceAura = context
    fierceAura.addFilter(.blur(radius: 34))
    fierceAura.fill(
      Path(
        ellipseIn: CGRect(
          x: fierceSunCenter.x - fierceSunRadius * 2.9,
          y: fierceSunCenter.y - fierceSunRadius * 2.9,
          width: fierceSunRadius * 5.8,
          height: fierceSunRadius * 5.8
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.22 * power),
          Color.yellow.opacity(0.25 * power),
          Color.orange.opacity(0.13 * power),
          Color.red.opacity(0.045 * power),
          .clear,
        ]),
        center: fierceSunCenter,
        startRadius: 0,
        endRadius: fierceSunRadius * 2.9
      )
    )

    for rayIndex in 0..<44 {
      let angle = Double(rayIndex) * 2 * .pi / 44 + time * 0.025
      let rayPulse = 0.5 + 0.5 * sin(time * (1.25 + Double(rayIndex % 5) * 0.06) + Double(rayIndex))
      let innerRadius = fierceSunRadius * 1.02
      let outerRadius = fierceSunRadius * CGFloat(1.3 + rayPulse * 0.66)
      var ray = Path()
      ray.move(
        to: CGPoint(
          x: fierceSunCenter.x + cos(angle) * innerRadius,
          y: fierceSunCenter.y + sin(angle) * innerRadius
        )
      )
      ray.addLine(
        to: CGPoint(
          x: fierceSunCenter.x + cos(angle) * outerRadius,
          y: fierceSunCenter.y + sin(angle) * outerRadius
        )
      )
      context.stroke(
        ray,
        with: .color(
          (rayIndex.isMultiple(of: 4) ? Color.yellow : Color.orange)
            .opacity((0.12 + rayPulse * 0.22) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.6 + CGFloat(rayIndex % 4) * 0.42,
          lineCap: .round
        )
      )
    }

    context.fill(
      Path(
        ellipseIn: CGRect(
          x: fierceSunCenter.x - fierceSunRadius,
          y: fierceSunCenter.y - fierceSunRadius,
          width: fierceSunRadius * 2,
          height: fierceSunRadius * 2
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.72 * power),
          Color.yellow.opacity(0.66 * power),
          Color.orange.opacity(0.44 * power),
          Color.red.opacity(0.17 * power),
        ]),
        center: CGPoint(
          x: fierceSunCenter.x - fierceSunRadius * 0.24,
          y: fierceSunCenter.y - fierceSunRadius * 0.26
        ),
        startRadius: 0,
        endRadius: fierceSunRadius
      )
    )

    for coronaIndex in 0..<7 {
      let start = Double(coronaIndex) * 0.91 + time * (coronaIndex.isMultiple(of: 2) ? 0.08 : -0.06)
      var corona = Path()
      corona.addArc(
        center: fierceSunCenter,
        radius: fierceSunRadius * (1.06 + CGFloat(coronaIndex % 3) * 0.1),
        startAngle: .radians(start),
        endAngle: .radians(start + 0.42 + Double(coronaIndex % 3) * 0.12),
        clockwise: false
      )
      context.stroke(
        corona,
        with: .color(Color.yellow.opacity((0.22 + Double(coronaIndex % 3) * 0.06) * power)),
        style: StrokeStyle(
          lineWidth: 1 + CGFloat(coronaIndex % 3) * 0.65,
          lineCap: .round
        )
      )
    }

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

    for index in 0..<14 {
      let onLeft = index.isMultiple(of: 2)
      let row = index / 2
      let base = CGPoint(
        x: size.width * (onLeft ? 0.025 : 0.975),
        y: size.height * (0.28 + CGFloat(row) * 0.105)
      )
      let height = size.height * (0.16 + CGFloat(index % 4) * 0.028)
      let flame = fireBackdropFlamePath(
        base: base,
        width: size.width * (0.075 + CGFloat(index % 3) * 0.014),
        height: height,
        phase: time * (1.05 + Double(index % 5) * 0.09) + Double(index) * 0.67
      )
      var edgeGlow = context
      edgeGlow.addFilter(.blur(radius: 18 + CGFloat(index % 3) * 4))
      edgeGlow.fill(
        flame,
        with: .color(Color.orange.opacity((0.055 + Double(index % 3) * 0.018) * power))
      )
      context.fill(
        flame,
        with: .linearGradient(
          Gradient(colors: [
            Color.yellow.opacity(0.16 * power),
            Color.orange.opacity(0.2 * power),
            Color.red.opacity(0.08 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: base.x, y: base.y - height),
          endPoint: base
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

  func fireBackdropFlamePath(
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

}
