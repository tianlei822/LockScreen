import LockScreenCore
import SwiftUI

struct SolarFireDragonFormation: View {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height) * 0.62
      let solarRadius = unit * 0.145
      let auraRect = CGRect(
        x: center.x - solarRadius * 2.25,
        y: center.y - solarRadius * 2.25,
        width: solarRadius * 4.5,
        height: solarRadius * 4.5
      )

      var solarAura = context
      solarAura.addFilter(.blur(radius: 18 + energy * 10))
      solarAura.fill(
        Path(ellipseIn: auraRect),
        with: .radialGradient(
          Gradient(colors: [
            Color.white.opacity(0.72),
            Color.yellow.opacity(0.82),
            Color.orange.opacity(0.5),
            Color.red.opacity(0.12),
            .clear,
          ]),
          center: center,
          startRadius: 0,
          endRadius: solarRadius * 2.2
        )
      )

      for index in 0..<20 {
        let seed = Double(index + 1)
        let angle = seed * 2 * .pi / 20 + time * 0.055
        let innerRadius = solarRadius * 0.96
        let rayVariation = seed.truncatingRemainder(dividingBy: 5) * 0.07
        let rayPulse = sin(time * 1.8 + seed) * 0.045
        let outerRadius = solarRadius * CGFloat(1.32 + rayVariation + rayPulse)
        let halfWidth: Double = Double.pi / 55.0
        var ray = Path()
        ray.move(
          to: CGPoint(
            x: center.x + cos(angle - halfWidth) * innerRadius,
            y: center.y + sin(angle - halfWidth) * innerRadius
          )
        )
        ray.addLine(
          to: CGPoint(
            x: center.x + cos(angle) * outerRadius,
            y: center.y + sin(angle) * outerRadius
          )
        )
        ray.addLine(
          to: CGPoint(
            x: center.x + cos(angle + halfWidth) * innerRadius,
            y: center.y + sin(angle + halfWidth) * innerRadius
          )
        )
        ray.closeSubpath()
        context.fill(
          ray,
          with: .linearGradient(
            Gradient(colors: [Color.yellow.opacity(0.72), Color.orange.opacity(0.08)]),
            startPoint: center,
            endPoint: CGPoint(
              x: center.x + cos(angle) * outerRadius,
              y: center.y + sin(angle) * outerRadius
            )
          )
        )
      }

      let sunRect = CGRect(
        x: center.x - solarRadius,
        y: center.y - solarRadius,
        width: solarRadius * 2,
        height: solarRadius * 2
      )
      context.fill(
        Path(ellipseIn: sunRect),
        with: .radialGradient(
          Gradient(colors: [
            Color.white,
            Color(red: 1, green: 0.91, blue: 0.32),
            Color.orange,
            Color(red: 0.78, green: 0.07, blue: 0.01),
          ]),
          center: CGPoint(x: center.x - solarRadius * 0.22, y: center.y - solarRadius * 0.2),
          startRadius: 0,
          endRadius: solarRadius
        )
      )
      context.stroke(
        Path(ellipseIn: sunRect.insetBy(dx: solarRadius * 0.16, dy: solarRadius * 0.16)),
        with: .color(Color.white.opacity(0.58 + energy * 0.16)),
        lineWidth: 1.2 + energy
      )

      for index in 0..<4 {
        let start = Double(index) * 1.43 + time * (index.isMultiple(of: 2) ? 0.12 : -0.09)
        var prominence = Path()
        prominence.addArc(
          center: center,
          radius: solarRadius * (1.12 + CGFloat(index) * 0.08),
          startAngle: .radians(start),
          endAngle: .radians(start + 0.62 + Double(index) * 0.08),
          clockwise: false
        )
        var prominenceGlow = context
        prominenceGlow.addFilter(.blur(radius: 5 + CGFloat(index)))
        prominenceGlow.stroke(
          prominence,
          with: .color(Color.orange.opacity(0.48)),
          style: StrokeStyle(lineWidth: 7 - CGFloat(index), lineCap: .round)
        )
        context.stroke(
          prominence,
          with: .color(Color.yellow.opacity(0.68)),
          style: StrokeStyle(lineWidth: 1.35, lineCap: .round)
        )
      }

      for index in 0..<7 {
        let seed = Double(index + 1)
        let base = CGPoint(
          x: center.x + CGFloat(index - 3) * unit * 0.044,
          y: center.y + unit * (0.18 + CGFloat(abs(index - 3)) * 0.006)
        )
        let flame = naturalFlamePath(
          base: base,
          width: unit * CGFloat(0.1 + seed.truncatingRemainder(dividingBy: 3) * 0.016),
          height: unit * CGFloat(0.14 + seed.truncatingRemainder(dividingBy: 4) * 0.032),
          phase: time * (1.55 + seed * 0.025) + seed
        )
        context.fill(
          flame,
          with: .linearGradient(
            Gradient(colors: [
              Color.yellow.opacity(0.88),
              Color.orange.opacity(0.92),
              Color(red: 0.72, green: 0.025, blue: 0.006).opacity(0.68),
              .clear,
            ]),
            startPoint: CGPoint(x: base.x, y: base.y - unit * 0.22),
            endPoint: base
          )
        )
      }

      let dragon = dragonBodyPath(center: center, unit: unit)
      var dragonAura = context
      dragonAura.addFilter(.blur(radius: 9 + energy * 6))
      dragonAura.stroke(
        dragon,
        with: .color(Color(red: 0.74, green: 0.02, blue: 0.006).opacity(0.58)),
        style: StrokeStyle(lineWidth: unit * 0.072, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragon,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.58, green: 0.015, blue: 0.004),
            Color.orange,
            Color(red: 0.82, green: 0.11, blue: 0.008),
          ]),
          startPoint: CGPoint(x: center.x - unit * 0.35, y: center.y + unit * 0.32),
          endPoint: CGPoint(x: center.x + unit * 0.35, y: center.y - unit * 0.3)
        ),
        style: StrokeStyle(lineWidth: unit * 0.052, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragon,
        with: .color(Color.yellow.opacity(0.34 + energy * 0.12)),
        style: StrokeStyle(lineWidth: 0.9 + energy * 0.6, lineCap: .round)
      )

      for index in 2..<19 {
        let fraction = Double(index) / 20
        let bodyPoint = dragonPoint(center: center, unit: unit, fraction: fraction)
        let normalAngle = dragonTangentAngle(fraction: fraction) + Double.pi / 2
        let normal = CGPoint(x: cos(normalAngle), y: sin(normalAngle))
        let radial = CGPoint(x: bodyPoint.x - center.x, y: bodyPoint.y - center.y)
        let direction: CGFloat = radial.x * normal.x + radial.y * normal.y >= 0 ? 1 : -1
        let outward = CGPoint(x: normal.x * direction, y: normal.y * direction)
        let inner = CGPoint(
          x: bodyPoint.x - outward.x * unit * 0.021,
          y: bodyPoint.y - outward.y * unit * 0.021
        )
        let outer = CGPoint(
          x: bodyPoint.x + outward.x * unit * 0.021,
          y: bodyPoint.y + outward.y * unit * 0.021
        )
        var scaleBand = Path()
        scaleBand.move(to: inner)
        scaleBand.addQuadCurve(
          to: outer,
          control: bodyPoint
        )
        context.stroke(
          scaleBand,
          with: .color(Color(red: 0.42, green: 0.01, blue: 0.004).opacity(0.72)),
          style: StrokeStyle(lineWidth: 0.75, lineCap: .round)
        )

        let bodyScale = dragonScalePath(
          center: bodyPoint,
          scale: unit * (index.isMultiple(of: 3) ? 0.032 : 0.025),
          angle: dragonTangentAngle(fraction: fraction)
        )
        context.fill(
          bodyScale,
          with: .linearGradient(
            Gradient(colors: [
              Color.yellow.opacity(0.72),
              Color.orange.opacity(0.52),
              Color(red: 0.34, green: 0.006, blue: 0.002).opacity(0.82),
            ]),
            startPoint: inner,
            endPoint: outer
          )
        )
        context.stroke(
          bodyScale,
          with: .color(Color(red: 0.26, green: 0.004, blue: 0.002).opacity(0.78)),
          lineWidth: 0.55
        )

        if index.isMultiple(of: 2) {
          var spine = Path()
          spine.move(to: outer)
          spine.addLine(
            to: CGPoint(
              x: bodyPoint.x + outward.x * unit * (0.047 + CGFloat(index % 3) * 0.008),
              y: bodyPoint.y + outward.y * unit * (0.047 + CGFloat(index % 3) * 0.008)
            )
          )
          context.stroke(
            spine,
            with: .color(Color.orange.opacity(0.78)),
            style: StrokeStyle(lineWidth: 1.3, lineCap: .round)
          )
        }
      }

      let tailCenter = dragonPoint(center: center, unit: unit, fraction: 0)
      let tailFlame = dragonTailFlamePath(
        center: tailCenter,
        scale: unit * 0.12,
        angle: dragonTangentAngle(fraction: 0) + .pi
      )
      context.fill(
        tailFlame,
        with: .linearGradient(
          Gradient(colors: [Color.white, Color.yellow, Color.orange, Color.red.opacity(0.1)]),
          startPoint: tailCenter,
          endPoint: CGPoint(x: tailCenter.x - unit * 0.14, y: tailCenter.y)
        )
      )

      for fraction in [0.22, 0.4, 0.61, 0.78] {
        let claw = dragonClawPath(center: center, unit: unit, fraction: fraction)
        var clawGlow = context
        clawGlow.addFilter(.blur(radius: 3.5))
        clawGlow.stroke(
          claw,
          with: .color(Color.orange.opacity(0.52)),
          style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
          claw,
          with: .color(Color(red: 0.42, green: 0.008, blue: 0.003).opacity(0.98)),
          style: StrokeStyle(lineWidth: 6.4, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
          claw,
          with: .color(Color.yellow.opacity(0.92)),
          style: StrokeStyle(lineWidth: 1.45, lineCap: .round, lineJoin: .round)
        )
      }

      let headCenter = dragonPoint(center: center, unit: unit, fraction: 1)
      let headAngle = dragonTangentAngle(fraction: 1) + sin(time * 1.7) * 0.065
      let headScale = unit * (0.225 + sin(time * 1.25) * 0.008)
      let mane = dragonManePath(center: headCenter, scale: headScale, angle: headAngle)
      var maneGlow = context
      maneGlow.addFilter(.blur(radius: 7 + energy * 4))
      maneGlow.fill(mane, with: .color(Color.orange.opacity(0.58)))
      context.fill(
        mane,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.42, green: 0.006, blue: 0.003),
            Color.orange,
            Color(red: 0.22, green: 0.002, blue: 0.001),
          ]),
          startPoint: CGPoint(x: headCenter.x, y: headCenter.y - headScale),
          endPoint: CGPoint(x: headCenter.x - headScale, y: headCenter.y + headScale)
        )
      )
      let ears = dragonEarPath(center: headCenter, scale: headScale, angle: headAngle)
      context.fill(
        ears,
        with: .linearGradient(
          Gradient(colors: [
            Color.yellow.opacity(0.86),
            Color.orange,
            Color(red: 0.36, green: 0.005, blue: 0.002),
          ]),
          startPoint: CGPoint(x: headCenter.x, y: headCenter.y - headScale),
          endPoint: CGPoint(x: headCenter.x, y: headCenter.y + headScale)
        )
      )
      context.stroke(
        ears,
        with: .color(Color(red: 0.28, green: 0.004, blue: 0.002).opacity(0.9)),
        style: StrokeStyle(lineWidth: 1.4, lineJoin: .round)
      )
      let head = dragonHeadPath(
        center: headCenter,
        scale: headScale,
        angle: headAngle
      )
      var headGlow = context
      headGlow.addFilter(.blur(radius: 8 + energy * 5))
      headGlow.fill(head, with: .color(Color.orange.opacity(0.72)))
      context.fill(
        head,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.95, green: 0.2, blue: 0.01),
            Color.orange,
            Color(red: 0.48, green: 0.008, blue: 0.003),
          ]
          ),
          startPoint: CGPoint(x: headCenter.x - unit * 0.08, y: headCenter.y),
          endPoint: CGPoint(x: headCenter.x + unit * 0.08, y: headCenter.y)
        )
      )
      context.stroke(
        head,
        with: .color(Color(red: 0.34, green: 0.006, blue: 0.002).opacity(0.9)),
        style: StrokeStyle(lineWidth: 1.7, lineJoin: .round)
      )
      let jaw = dragonJawPath(center: headCenter, scale: headScale, angle: headAngle)
      context.fill(
        jaw,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 1, green: 0.62, blue: 0.16),
            Color(red: 0.55, green: 0.018, blue: 0.006),
          ]),
          startPoint: headCenter,
          endPoint: CGPoint(x: headCenter.x + headScale, y: headCenter.y + headScale)
        )
      )
      context.stroke(
        jaw,
        with: .color(Color(red: 0.25, green: 0.003, blue: 0.001).opacity(0.94)),
        style: StrokeStyle(lineWidth: 1.35, lineJoin: .round)
      )
      var hornGlow = context
      hornGlow.addFilter(.blur(radius: 5))
      hornGlow.stroke(
        dragonHornPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color.orange.opacity(0.56)),
        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonHornPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .linearGradient(
          Gradient(colors: [Color(red: 0.56, green: 0.2, blue: 0.03), Color.yellow, Color.white]),
          startPoint: CGPoint(x: headCenter.x - headScale, y: headCenter.y),
          endPoint: CGPoint(x: headCenter.x + headScale, y: headCenter.y - headScale)
        ),
        style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonHeadDetails(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color(red: 0.28, green: 0.004, blue: 0.002).opacity(0.96)),
        style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonWhiskerPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color(red: 1, green: 0.9, blue: 0.46).opacity(0.96)),
        style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonNostrilSmokePath(center: headCenter, scale: headScale, angle: headAngle),
        with: .linearGradient(
          Gradient(colors: [Color.white.opacity(0.78), Color.yellow.opacity(0.5), .clear]),
          startPoint: headCenter,
          endPoint: CGPoint(x: headCenter.x + headScale * 1.7, y: headCenter.y)
        ),
        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonFangPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color.white.opacity(0.96)),
        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
      )
      let eye = transform(
        point: CGPoint(x: 0.13, y: -0.055),
        center: headCenter,
        scale: headScale,
        angle: headAngle
      )
      let eyeRect = CGRect(x: eye.x - 2.8, y: eye.y - 2.8, width: 5.6, height: 5.6)
      context.fill(
        Path(ellipseIn: eyeRect), with: .color(Color(red: 0.08, green: 0.16, blue: 0.18)))
      context.fill(
        Path(ellipseIn: eyeRect.insetBy(dx: 1, dy: 1)),
        with: .color(Color(red: 0.88, green: 1, blue: 0.78).opacity(0.98))
      )

      for index in 0..<18 {
        let seed = Double(index + 1)
        let angle = seed * 2.17 + time * (index.isMultiple(of: 2) ? 0.44 : -0.31)
        let radius = unit * CGFloat(0.29 + seed.truncatingRemainder(dividingBy: 5) * 0.027)
        let spark = CGPoint(
          x: center.x + cos(angle) * radius,
          y: center.y + sin(angle) * radius
        )
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: spark.x - CGFloat(index.isMultiple(of: 4) ? 1.5 : 0.7),
              y: spark.y - CGFloat(index.isMultiple(of: 4) ? 1.5 : 0.7),
              width: CGFloat(index.isMultiple(of: 4) ? 3 : 1.4),
              height: CGFloat(index.isMultiple(of: 4) ? 3 : 1.4)
            )
          ),
          with: .color(
            (index.isMultiple(of: 4) ? Color.white : Color.orange)
              .opacity(0.42 + energy * 0.18)
          )
        )
      }
    }
    .frame(width: diameter, height: diameter)
    .scaleEffect(0.98 + sin(time * 1.6) * 0.018 + energy * 0.025)
  }

  private func dragonBodyPath(center: CGPoint, unit: CGFloat) -> Path {
    Path { path in
      for index in 0...96 {
        let fraction = Double(index) / 96
        let point = dragonPoint(center: center, unit: unit, fraction: fraction)
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
    }
  }

  private func dragonPoint(center: CGPoint, unit: CGFloat, fraction: Double) -> CGPoint {
    let point = normalizedDragonPoint(fraction: fraction)
    let orbitAngle = dragonOrbitAngle
    let orbitScale = 0.96 + sin(time * 0.74) * 0.035
    let flightX = cos(time * 0.47) * unit * 0.018
    let flightY = sin(time * 0.61) * unit * 0.026
    return CGPoint(
      x: center.x + flightX
        + (point.x * cos(orbitAngle) - point.y * sin(orbitAngle)) * unit * orbitScale,
      y: center.y + flightY
        + (point.x * sin(orbitAngle) + point.y * cos(orbitAngle)) * unit * orbitScale
    )
  }

  private var dragonOrbitAngle: Double {
    time * 0.15 + sin(time * 0.72) * 0.09
  }

  private func normalizedDragonPoint(fraction: Double) -> CGPoint {
    let sway = CGFloat(sin(time * 0.62)) * 0.008
    let points = [
      CGPoint(x: -0.4, y: 0.31),
      CGPoint(x: -0.43, y: 0.08),
      CGPoint(x: -0.29, y: -0.26),
      CGPoint(x: 0.02 + sway, y: -0.34),
      CGPoint(x: 0.3, y: -0.18),
      CGPoint(x: 0.31, y: 0.1),
      CGPoint(x: 0.08 - sway, y: 0.27),
      CGPoint(x: -0.14, y: 0.13),
      CGPoint(x: -0.04, y: -0.08),
      CGPoint(x: 0.21, y: -0.17),
      CGPoint(x: 0.39, y: -0.31),
    ]
    let clamped = max(0, min(1, fraction))
    let progress = clamped * Double(points.count - 1)
    let index = min(Int(progress), points.count - 2)
    let local = CGFloat(progress - Double(index))
    let p0 = points[max(index - 1, 0)]
    let p1 = points[index]
    let p2 = points[index + 1]
    let p3 = points[min(index + 2, points.count - 1)]
    let base = catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: local)
    let wave = sin(time * 2.05 - fraction * 11.5) * (0.026 - fraction * 0.009)
    return CGPoint(
      x: base.x + cos(time * 1.3 - fraction * 7.2) * 0.008,
      y: base.y + wave
    )
  }

  private func catmullRom(
    p0: CGPoint,
    p1: CGPoint,
    p2: CGPoint,
    p3: CGPoint,
    t: CGFloat
  ) -> CGPoint {
    let t2 = t * t
    let t3 = t2 * t
    let x =
      0.5
      * ((2 * p1.x) + (-p0.x + p2.x) * t
        + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2
        + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
    let y =
      0.5
      * ((2 * p1.y) + (-p0.y + p2.y) * t
        + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
        + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
    return CGPoint(x: x, y: y)
  }

  private func dragonTangentAngle(fraction: Double) -> Double {
    let start = normalizedDragonPoint(fraction: max(0, fraction - 0.006))
    let end = normalizedDragonPoint(fraction: min(1, fraction + 0.006))
    return atan2(end.y - start.y, end.x - start.x) + dragonOrbitAngle
  }

  private func naturalFlamePath(
    base: CGPoint,
    width: CGFloat,
    height: CGFloat,
    phase: Double
  ) -> Path {
    let drift = CGFloat(sin(phase)) * width * 0.38
    let notch = CGFloat(cos(phase * 0.73)) * width * 0.16
    return Path { path in
      path.move(to: CGPoint(x: base.x - width / 2, y: base.y))
      path.addCurve(
        to: CGPoint(x: base.x - width * 0.18 + notch, y: base.y - height * 0.46),
        control1: CGPoint(x: base.x - width * 0.64, y: base.y - height * 0.16),
        control2: CGPoint(x: base.x - width * 0.42, y: base.y - height * 0.38)
      )
      path.addCurve(
        to: CGPoint(x: base.x + drift, y: base.y - height),
        control1: CGPoint(x: base.x - width * 0.06, y: base.y - height * 0.68),
        control2: CGPoint(x: base.x + drift - width * 0.2, y: base.y - height * 0.88)
      )
      path.addCurve(
        to: CGPoint(x: base.x + width * 0.2 - notch, y: base.y - height * 0.38),
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

  private func dragonManePath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let flutter = CGFloat(sin(time * 2.35)) * 0.08
    let points = [
      CGPoint(x: -0.58, y: 0.3), CGPoint(x: -0.7, y: 0.02),
      CGPoint(x: -1.02 - flutter, y: -0.16), CGPoint(x: -0.72, y: -0.34),
      CGPoint(x: -0.92 + flutter, y: -0.68), CGPoint(x: -0.48, y: -0.58),
      CGPoint(x: -0.26, y: -0.32), CGPoint(x: 0.08, y: 0.08),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() { path.addLine(to: point) }
      path.closeSubpath()
    }
  }

  private func dragonScalePath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let points = [
      CGPoint(x: -0.72, y: 0),
      CGPoint(x: 0, y: -0.58),
      CGPoint(x: 0.72, y: 0),
      CGPoint(x: 0, y: 0.58),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      path.move(to: points[0])
      for point in points.dropFirst() { path.addLine(to: point) }
      path.closeSubpath()
    }
  }

  private func dragonTailFlamePath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let points = [
      CGPoint(x: 0.12, y: 0), CGPoint(x: -0.18, y: -0.24),
      CGPoint(x: -0.82, y: -0.06), CGPoint(x: -0.42, y: 0.13),
      CGPoint(x: -0.7, y: 0.42), CGPoint(x: -0.08, y: 0.2),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() { path.addLine(to: point) }
      path.closeSubpath()
    }
  }

  private func dragonHeadPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let points = [
      CGPoint(x: -0.62, y: 0.18),
      CGPoint(x: -0.28, y: -0.15),
      CGPoint(x: 0.18, y: -0.18),
      CGPoint(x: 0.5, y: -0.04),
      CGPoint(x: 0.72, y: 0.06),
      CGPoint(x: 0.5, y: 0.18),
      CGPoint(x: 0.7, y: 0.4),
      CGPoint(x: 0.24, y: 0.31),
      CGPoint(x: 0.02, y: 0.58),
      CGPoint(x: -0.22, y: 0.27),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() {
        path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func dragonEarPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let points = [
      CGPoint(x: -0.22, y: -0.18),
      CGPoint(x: -0.72, y: -0.62),
      CGPoint(x: -0.62, y: -0.04),
      CGPoint(x: -0.16, y: 0.14),
      CGPoint(x: -0.58, y: 0.58),
      CGPoint(x: -0.04, y: 0.42),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      path.move(to: points[0])
      path.addLine(to: points[1])
      path.addLine(to: points[2])
      path.closeSubpath()
      path.move(to: points[3])
      path.addLine(to: points[4])
      path.addLine(to: points[5])
      path.closeSubpath()
    }
  }

  private func dragonJawPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let points = [
      CGPoint(x: 0.08, y: 0.2),
      CGPoint(x: 0.7, y: 0.17),
      CGPoint(x: 0.58, y: 0.42),
      CGPoint(x: 0.18, y: 0.38),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      path.move(to: points[0])
      for point in points.dropFirst() { path.addLine(to: point) }
      path.closeSubpath()
    }
  }

  private func dragonHeadDetails(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(-0.08, -0.05))
      path.addLine(to: point(0.24, -0.03))
      path.addLine(to: point(0.08, 0.08))

      path.move(to: point(0.18, 0.22))
      path.addCurve(
        to: point(0.68, 0.17),
        control1: point(0.36, 0.28),
        control2: point(0.54, 0.17)
      )

      path.move(to: point(-0.52, 0.16))
      path.addCurve(
        to: point(0.08, 0.46),
        control1: point(-0.32, 0.42),
        control2: point(-0.06, 0.18)
      )
    }
  }

  private func dragonHornPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(-0.3, -0.1))
      path.addCurve(
        to: point(-0.6, -0.88),
        control1: point(-0.5, -0.36),
        control2: point(-0.72, -0.68)
      )
      path.addLine(to: point(-0.38, -0.72))

      path.move(to: point(0.0, -0.15))
      path.addCurve(
        to: point(0.22, -0.9),
        control1: point(-0.02, -0.44),
        control2: point(0.08, -0.76)
      )
      path.addLine(to: point(0.36, -0.68))
    }
  }

  private func dragonWhiskerPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(0.43, 0.1))
      path.addCurve(
        to: point(1.36, -0.15),
        control1: point(0.76, -0.08),
        control2: point(1.02, 0.1)
      )
      path.move(to: point(0.4, 0.24))
      path.addCurve(
        to: point(1.25, 0.64),
        control1: point(0.7, 0.48),
        control2: point(0.98, 0.34)
      )
    }
  }

  private func dragonNostrilSmokePath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      let flutter = CGFloat(sin(time * 2.6)) * 0.12
      path.move(to: point(0.62, 0.01))
      path.addCurve(
        to: point(1.42, -0.18 + flutter),
        control1: point(0.88, -0.2),
        control2: point(1.12, 0.08 + flutter)
      )
      path.move(to: point(0.64, 0.09))
      path.addCurve(
        to: point(1.34, 0.35 - flutter),
        control1: point(0.9, 0.28),
        control2: point(1.12, 0.08 - flutter)
      )
    }
  }

  private func dragonFangPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(0.35, 0.14))
      path.addLine(to: point(0.42, 0.34))
      path.move(to: point(0.54, 0.15))
      path.addLine(to: point(0.58, 0.3))
    }
  }

  private func dragonClawPath(center: CGPoint, unit: CGFloat, fraction: Double) -> Path {
    let base = dragonPoint(center: center, unit: unit, fraction: fraction)
    let tangentAngle = dragonTangentAngle(fraction: fraction)
    let tangent = CGPoint(x: cos(tangentAngle), y: sin(tangentAngle))
    var outward = CGPoint(x: -tangent.y, y: tangent.x)
    let radial = CGPoint(x: base.x - center.x, y: base.y - center.y)
    if radial.x * outward.x + radial.y * outward.y < 0 {
      outward = CGPoint(x: -outward.x, y: -outward.y)
    }
    let flex = CGFloat(sin(time * 2.2 + fraction * 12))
    let reach = unit * (0.068 + flex * 0.009)
    let elbow = CGPoint(
      x: base.x + outward.x * reach + tangent.x * unit * (0.018 + flex * 0.006),
      y: base.y + outward.y * reach + tangent.y * unit * (0.018 + flex * 0.006)
    )
    let palm = CGPoint(
      x: elbow.x + outward.x * unit * 0.052 - tangent.x * unit * 0.03,
      y: elbow.y + outward.y * unit * 0.052 - tangent.y * unit * 0.03
    )

    return Path { path in
      path.move(to: base)
      path.addQuadCurve(to: palm, control: elbow)
      for toe in -1...1 {
        path.move(to: palm)
        path.addLine(
          to: CGPoint(
            x: palm.x + outward.x * unit * 0.042 + tangent.x * CGFloat(toe) * unit * 0.025,
            y: palm.y + outward.y * unit * 0.042 + tangent.y * CGFloat(toe) * unit * 0.025
          )
        )
      }
    }
  }

  nonisolated private func transform(
    point: CGPoint,
    center: CGPoint,
    scale: CGFloat,
    angle: Double
  ) -> CGPoint {
    CGPoint(
      x: center.x + (point.x * cos(angle) - point.y * sin(angle)) * scale,
      y: center.y + (point.x * sin(angle) + point.y * cos(angle)) * scale
    )
  }
}
