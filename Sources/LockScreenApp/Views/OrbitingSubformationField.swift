import SwiftUI

enum OrbitingFormationDiscipline {
  case bagua
  case thunder
}

/// Independent edge formations that orbit the main seal without expanding the SwiftUI hierarchy.
struct OrbitingSubformationField: View {
  let discipline: OrbitingFormationDiscipline
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool
  let style: FormationVisualStyle

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let count = discipline == .bagua ? 8 : 9
      let direction = discipline == .bagua ? 1.0 : -1.0
      let orbitSpeed =
        discipline == .bagua
        ? (isActivated ? 0.22 : 0.055)
        : (isActivated ? 0.25 : 0.072)
      let orbitRotation = time * orbitSpeed * direction
      let orbitRadius = unit * (discipline == .bagua ? 0.44 : 0.422)

      for index in 0..<count {
        let sectorOffset = discipline == .bagua ? Double.pi / Double(count) : 0
        let baseAngle = Double(index) * 2 * Double.pi / Double(count) + sectorOffset
        let angle = baseAngle + orbitRotation
        let wave = 0.5 + 0.5 * sin(time * flashFrequency(for: index) - Double(index) * 0.92)
        let flash = 0.24 + 0.76 * pow(wave, discipline == .thunder ? 3.1 : 2.35)
        let localRadius =
          unit * (discipline == .bagua ? 0.047 : 0.044)
          * (0.9 + CGFloat(flash) * 0.16)
        let breathingRadius = orbitRadius * (1 + CGFloat(sin(time * 1.7 + baseAngle)) * 0.008)
        let nodeCenter = polarPoint(center: center, radius: breathingRadius, angle: angle)
        let tint = color(for: index)

        drawOrbitSegment(
          in: &context,
          center: center,
          radius: orbitRadius,
          angle: angle,
          count: count,
          flash: flash,
          tint: tint
        )
        drawNodeRings(
          in: &context,
          center: nodeCenter,
          radius: localRadius,
          flash: flash,
          tint: tint
        )

        let localRotation =
          -orbitRotation * 2.8
          + time * (index.isMultiple(of: 2) ? -0.17 : 0.13)
          + Double(index) * 0.31
        drawSigil(
          in: &context,
          kind: index % 3,
          center: nodeCenter,
          radius: localRadius * 0.7,
          rotation: localRotation,
          flash: flash,
          tint: tint
        )
      }
    }
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func flashFrequency(for index: Int) -> Double {
    let base = discipline == .bagua ? 2.9 : 4.4
    return base + Double(index % (discipline == .bagua ? 3 : 4)) * 0.37
  }

  private func color(for index: Int) -> Color {
    if discipline == .thunder, index.isMultiple(of: 3) {
      return style.flare
    }
    return index.isMultiple(of: 2) ? style.primary : style.secondary
  }

  private func drawOrbitSegment(
    in context: inout GraphicsContext,
    center: CGPoint,
    radius: CGFloat,
    angle: Double,
    count: Int,
    flash: Double,
    tint: Color
  ) {
    let halfSpan = Double.pi / Double(count) * 0.58
    var segment = Path()
    segment.addArc(
      center: center,
      radius: radius,
      startAngle: .radians(angle - halfSpan),
      endAngle: .radians(angle + halfSpan),
      clockwise: false
    )
    context.stroke(
      segment,
      with: .color(tint.opacity(0.035 + energy * 0.1 + flash * 0.28)),
      style: StrokeStyle(
        lineWidth: 0.55 + CGFloat(flash) * (discipline == .thunder ? 2.6 : 1.8),
        lineCap: .square
      )
    )
  }

  private func drawNodeRings(
    in context: inout GraphicsContext,
    center: CGPoint,
    radius: CGFloat,
    flash: Double,
    tint: Color
  ) {
    let ring = Path(
      ellipseIn: CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
      )
    )
    if flash > 0.42 {
      var glow = context
      glow.addFilter(.blur(radius: 3 + CGFloat(flash) * 5))
      glow.stroke(
        ring,
        with: .color(tint.opacity(0.08 + energy * 0.14 + flash * 0.22)),
        lineWidth: 3 + CGFloat(flash) * 5
      )
    }
    context.stroke(
      ring,
      with: .color(tint.opacity(0.1 + energy * 0.12 + flash * 0.42)),
      style: StrokeStyle(
        lineWidth: 0.65 + CGFloat(flash) * 1.25,
        dash: [radius * 0.48, radius * 0.22]
      )
    )

    let innerRadius = radius * 0.82
    context.stroke(
      Path(
        ellipseIn: CGRect(
          x: center.x - innerRadius,
          y: center.y - innerRadius,
          width: innerRadius * 2,
          height: innerRadius * 2
        )
      ),
      with: .color(Color.white.opacity(0.04 + energy * 0.08 + flash * 0.22)),
      lineWidth: 0.45 + CGFloat(flash) * 0.55
    )
  }

  private func drawSigil(
    in context: inout GraphicsContext,
    kind: Int,
    center: CGPoint,
    radius: CGFloat,
    rotation: Double,
    flash: Double,
    tint: Color
  ) {
    let path: Path
    switch kind {
    case 0:
      path = nestedTrianglePath(center: center, radius: radius, rotation: rotation)
    case 1:
      path = pentagramPath(center: center, radius: radius, rotation: rotation)
    default:
      path = hexagramPath(center: center, radius: radius, rotation: rotation)
    }
    context.stroke(
      path,
      with: .color(tint.opacity(0.16 + energy * 0.14 + flash * 0.62)),
      style: StrokeStyle(
        lineWidth: 0.7 + CGFloat(flash) * (discipline == .thunder ? 1.35 : 1.05),
        lineCap: .round,
        lineJoin: .miter
      )
    )

    let coreRadius = radius * (0.08 + CGFloat(flash) * 0.08)
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: center.x - coreRadius,
          y: center.y - coreRadius,
          width: coreRadius * 2,
          height: coreRadius * 2
        )
      ),
      with: .color(Color.white.opacity(0.1 + energy * 0.12 + flash * 0.48))
    )
  }

  private func nestedTrianglePath(center: CGPoint, radius: CGFloat, rotation: Double) -> Path {
    var path = regularPolygon(center: center, radius: radius, sides: 3, rotation: rotation)
    path.addPath(
      Path(
        ellipseIn: CGRect(
          x: center.x - radius * 0.48,
          y: center.y - radius * 0.48,
          width: radius * 0.96,
          height: radius * 0.96
        )
      )
    )
    return path
  }

  private func pentagramPath(center: CGPoint, radius: CGFloat, rotation: Double) -> Path {
    let order = [0, 2, 4, 1, 3, 0]
    return Path { path in
      for (position, vertex) in order.enumerated() {
        let angle = rotation - Double.pi / 2 + Double(vertex) * 2 * Double.pi / 5
        let point = polarPoint(center: center, radius: radius, angle: angle)
        position == 0 ? path.move(to: point) : path.addLine(to: point)
      }
    }
  }

  private func hexagramPath(center: CGPoint, radius: CGFloat, rotation: Double) -> Path {
    var path = regularPolygon(center: center, radius: radius, sides: 3, rotation: rotation)
    path.addPath(
      regularPolygon(
        center: center,
        radius: radius,
        sides: 3,
        rotation: rotation + Double.pi
      )
    )
    return path
  }

  private func regularPolygon(
    center: CGPoint,
    radius: CGFloat,
    sides: Int,
    rotation: Double
  ) -> Path {
    Path { path in
      for index in 0..<sides {
        let angle = rotation - Double.pi / 2 + Double(index) * 2 * Double.pi / Double(sides)
        let point = polarPoint(center: center, radius: radius, angle: angle)
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func polarPoint(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
    CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
  }
}
