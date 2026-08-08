import LockScreenCore
import SwiftUI

/// The school-specific layer that makes each tracing option feel like a distinct formation.
struct FormationDisciplineLayer: View {
  let trajectory: FormationTrajectory
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    switch trajectory {
    case .circle:
      fivePhaseFormation
    case .infinity:
      baguaFormation
    case .triangle:
      thunderFormation
    }
  }

  private var fivePhaseFormation: some View {
    FivePhaseCycleField(
      diameter: diameter,
      time: time,
      energy: energy,
      isActivated: isActivated
    )
  }

  private var baguaFormation: some View {
    let rotation = time * (isActivated ? -20 : -5)
    let style = trajectory.visualStyle

    return ZStack {
      BaguaPeripheralField(
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )
      .frame(width: diameter * 1.28, height: diameter * 1.28)

      OrbitingSubformationField(
        discipline: .bagua,
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )
      .frame(width: diameter * 1.18, height: diameter * 1.18)

      BaguaFormationCanvas(
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )

      Text("☯")
        .font(.system(size: diameter * 0.14, weight: .light))
        .foregroundStyle(
          LinearGradient(
            colors: [style.flare, style.primary, style.secondary],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .rotationEffect(.degrees(rotation))
        .shadow(color: style.primary.opacity(0.72), radius: 12 + energy * 12)

      ForEach(0..<2, id: \.self) { index in
        Circle()
          .fill(index == 0 ? Color.white : style.secondary)
          .frame(width: 5 + energy * 4, height: 5 + energy * 4)
          .shadow(color: style.primary, radius: 8)
          .offset(y: -diameter * 0.19)
          .rotationEffect(.degrees(Double(index) * 180 - rotation * 2))
      }
    }
    .frame(width: diameter, height: diameter)
  }

  private var thunderFormation: some View {
    let style = trajectory.visualStyle
    let flash = pow(max(0, sin(time * 5.7)), 14)
    let boltBeat = 0.5 + 0.5 * sin(time * 5.2)
    let boltBounce = abs(sin(time * 3.4))

    return ZStack {
      OrbitingSubformationField(
        discipline: .thunder,
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )
      .frame(width: diameter * 1.18, height: diameter * 1.18)

      ThunderFormationCanvas(
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )

      LightningStormField(
        style: style,
        time: time,
        energy: energy,
        isActivated: isActivated,
        seedOffset: 8_111,
        presentation: .core
      )
      .frame(width: diameter * 0.74, height: diameter * 0.74)

      ZStack {
        Circle()
          .fill(style.primary.opacity(0.2 + energy * 0.32 + flash * 0.28))
          .blur(radius: 10 + energy * 10)

        Circle()
          .stroke(Color.white.opacity(0.58 + flash * 0.4), lineWidth: 1 + energy * 1.5)

        Image(systemName: "bolt.fill")
          .font(.system(size: diameter * 0.057, weight: .black))
          .foregroundStyle(
            LinearGradient(
              colors: [.white, style.flare, style.primary],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .shadow(color: style.primary.opacity(0.88), radius: 5 + energy * 8)
          .scaleEffect(0.9 + boltBeat * 0.2 + flash * 0.16)
          .offset(y: -diameter * 0.009 * boltBounce)
          .rotationEffect(.degrees(sin(time * 2.3) * 3.5))
      }
      .frame(width: diameter * 0.105, height: diameter * 0.105)
      .shadow(color: style.primary, radius: 12 + energy * 15)
      .scaleEffect(1 + flash * 0.14 + sin(time * 4.4) * 0.025)
    }
    .frame(width: diameter, height: diameter)
    .blendMode(.plusLighter)
  }

}

private struct BaguaPeripheralField: View {
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool
  let style: FormationVisualStyle

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let speed = isActivated ? 1.35 : 0.82

      for ring in 0..<6 {
        let wave = max(0, sin(time * speed * 2.35 - Double(ring) * 1.05))
        let flash = 0.12 + 0.88 * pow(wave, 2.4)
        let radius = unit * (0.315 + CGFloat(ring) * 0.029)
        let segmentCount = ring.isMultiple(of: 2) ? 16 : 12

        for segment in 0..<segmentCount {
          let segmentPhase =
            Double(segment) * 2 * .pi / Double(segmentCount)
            + time * (ring.isMultiple(of: 2) ? 0.032 : -0.024)
          let gap = Double.pi / Double(segmentCount) * (ring.isMultiple(of: 2) ? 0.23 : 0.38)
          var arc = Path()
          arc.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(segmentPhase + gap),
            endAngle: .radians(
              segmentPhase + 2 * .pi / Double(segmentCount) - gap
            ),
            clockwise: false
          )
          let segmentPulse =
            0.52 + 0.48 * (0.5 + 0.5 * sin(time * 3.15 - Double(segment) * 0.63))
          context.stroke(
            arc,
            with: .color(
              (ring.isMultiple(of: 2) ? style.primary : style.secondary)
                .opacity((0.06 + energy * 0.12 + flash * 0.28) * segmentPulse)
            ),
            style: StrokeStyle(
              lineWidth: 0.45 + CGFloat(flash) * (ring.isMultiple(of: 2) ? 3.6 : 2.45),
              lineCap: .square
            )
          )
        }

        if flash > 0.38 {
          var ringGlow = context
          ringGlow.addFilter(.blur(radius: 5 + CGFloat(flash) * 5))
          ringGlow.stroke(
            Path(
              ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
              )
            ),
            with: .color(style.primary.opacity(flash * (0.08 + energy * 0.08))),
            lineWidth: 4 + CGFloat(flash) * 6
          )
        }
      }

      for ray in 0..<24 {
        let angle = Double(ray) * 2 * .pi / 24 - time * 0.045
        let pulse = 0.18 + 0.82 * pow(max(0, sin(time * 2.7 - Double(ray) * 0.4)), 2)
        let inner = unit * (ray.isMultiple(of: 3) ? 0.405 : 0.432)
        let outer = unit * (ray.isMultiple(of: 3) ? 0.475 : 0.462)
        var tick = Path()
        tick.move(
          to: CGPoint(
            x: center.x + cos(angle) * inner,
            y: center.y + sin(angle) * inner
          )
        )
        tick.addLine(
          to: CGPoint(
            x: center.x + cos(angle) * outer,
            y: center.y + sin(angle) * outer
          )
        )
        context.stroke(
          tick,
          with: .color(
            (ray.isMultiple(of: 3) ? style.secondary : style.primary)
              .opacity((0.07 + energy * 0.12) * pulse)
          ),
          style: StrokeStyle(
            lineWidth: (ray.isMultiple(of: 3) ? 2.1 : 0.65) * (0.65 + CGFloat(pulse)),
            lineCap: .square
          )
        )
      }
    }
    .blendMode(.plusLighter)
  }
}

private struct BaguaFormationCanvas: View {
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool
  let style: FormationVisualStyle

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let rotation = time * (isActivated ? 0.22 : 0.055)

      for ring in 0..<5 {
        let ringWave = max(0, sin(time * 2.8 - Double(ring) * 1.08))
        let ringFlash = 0.16 + 0.84 * pow(ringWave, 2.35)
        let radius = unit * (0.2 + CGFloat(ring) * 0.064)
        let ringPath = Path(
          ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
          )
        )
        context.stroke(
          ringPath,
          with: .color(
            (ring.isMultiple(of: 2) ? style.primary : style.secondary)
              .opacity((0.15 + Double(4 - ring) * 0.04 + energy * 0.18) * ringFlash)
          ),
          style: StrokeStyle(
            lineWidth: (ring == 4 ? 2.8 : ring == 2 ? 1.8 : 0.75)
              * (0.58 + CGFloat(ringFlash) * 1.02),
            dash: ring == 3 ? [unit * 0.014, unit * 0.01] : []
          )
        )
      }

      for sector in 0..<8 {
        let angle = Double(sector) * Double.pi / 4 + rotation
        let sectorFlash = 0.26 + 0.74 * (0.5 + 0.5 * sin(time * 3.9 - Double(sector) * 0.88))
        let flashScale = 0.74 + CGFloat(sectorFlash) * 0.5
        var segment = Path()
        segment.addArc(
          center: center,
          radius: unit * 0.458,
          startAngle: .radians(angle - 0.29),
          endAngle: .radians(angle + 0.29),
          clockwise: false
        )
        context.stroke(
          segment,
          with: .color(style.primary.opacity((0.34 + energy * 0.28) * sectorFlash)),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 5.2 : 3.2) * flashScale,
            lineCap: .square
          )
        )

        context.stroke(
          circuitRunePath(center: center, unit: unit, angle: angle),
          with: .color(style.secondary.opacity((0.4 + energy * 0.22) * sectorFlash)),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 1.9 : 1.25) * flashScale,
            lineJoin: .miter
          )
        )

        let crystal = crystalPath(center: center, unit: unit, angle: angle)
        var crystalGlow = context
        crystalGlow.addFilter(.blur(radius: 6 + energy * 6))
        crystalGlow.stroke(
          crystal,
          with: .color(style.primary.opacity((0.32 + energy * 0.25) * sectorFlash)),
          lineWidth: 5 + CGFloat(sectorFlash) * 4
        )
        context.stroke(
          crystal,
          with: .color(Color.white.opacity((0.38 + energy * 0.22) * sectorFlash)),
          style: StrokeStyle(lineWidth: 1.05 + CGFloat(sectorFlash) * 0.7, lineJoin: .miter)
        )

        context.stroke(
          trigramPath(center: center, unit: unit, angle: angle, sector: sector),
          with: .color(style.primary.opacity((0.48 + energy * 0.24) * sectorFlash)),
          style: StrokeStyle(lineWidth: 1.55 + CGFloat(sectorFlash) * 1.25, lineCap: .square)
        )
      }

      for layer in 0..<3 {
        let layerFlash = 0.36 + 0.64 * (0.5 + 0.5 * sin(time * 3.25 + Double(layer) * 1.6))
        context.stroke(
          regularPolygon(
            center: center,
            radius: unit * (0.225 + CGFloat(layer) * 0.046),
            sides: layer == 2 ? 8 : 4,
            rotation: rotation * (layer.isMultiple(of: 2) ? -0.7 : 0.9)
              + Double(layer) * Double.pi / 4
          ),
          with: .color(
            (layer == 1 ? style.secondary : style.primary)
              .opacity((0.18 + energy * 0.22) * layerFlash)
          ),
          style: StrokeStyle(
            lineWidth: (layer == 1 ? 1.8 : 0.85) * (0.76 + CGFloat(layerFlash) * 0.48),
            lineJoin: .miter
          )
        )
      }

      let lensFlash = 0.38 + 0.62 * (0.5 + 0.5 * sin(time * 4.1))
      context.stroke(
        lensPath(center: center, unit: unit),
        with: .color(style.secondary.opacity((0.34 + energy * 0.26) * lensFlash)),
        style: StrokeStyle(
          lineWidth: 1.6 + CGFloat(lensFlash) * 1.25,
          lineJoin: .round
        )
      )
    }
    .blendMode(.plusLighter)
  }

  private func polarPoint(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
    CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
  }

  private func circuitRunePath(center: CGPoint, unit: CGFloat, angle: Double) -> Path {
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let radial = CGPoint(x: cos(angle), y: sin(angle))
    let offsets: [(CGFloat, CGFloat)] = [
      (-0.055, 0), (-0.041, -0.014), (-0.021, -0.014), (-0.01, 0.01),
      (0.014, 0.01), (0.026, -0.012), (0.052, -0.012), (0.06, 0.004),
    ]
    return Path { path in
      for (index, offset) in offsets.enumerated() {
        let point = CGPoint(
          x: center.x + radial.x * unit * (0.4 + offset.1) + tangent.x * unit * offset.0,
          y: center.y + radial.y * unit * (0.4 + offset.1) + tangent.y * unit * offset.0
        )
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
    }
  }

  private func crystalPath(center: CGPoint, unit: CGFloat, angle: Double) -> Path {
    let radial = CGPoint(x: cos(angle), y: sin(angle))
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let node = polarPoint(center: center, radius: unit * 0.415, angle: angle)
    let points = [
      CGPoint(x: node.x + radial.x * unit * 0.05, y: node.y + radial.y * unit * 0.05),
      CGPoint(x: node.x + tangent.x * unit * 0.035, y: node.y + tangent.y * unit * 0.035),
      CGPoint(x: node.x - radial.x * unit * 0.04, y: node.y - radial.y * unit * 0.04),
      CGPoint(x: node.x - tangent.x * unit * 0.035, y: node.y - tangent.y * unit * 0.035),
    ]
    return Path { path in
      path.move(to: points[0])
      for point in points.dropFirst() { path.addLine(to: point) }
      path.closeSubpath()
      path.move(
        to: CGPoint(
          x: node.x + radial.x * unit * 0.038,
          y: node.y + radial.y * unit * 0.038
        )
      )
      path.addLine(
        to: CGPoint(
          x: node.x - radial.x * unit * 0.03,
          y: node.y - radial.y * unit * 0.03
        )
      )
    }
  }

  private func trigramPath(
    center: CGPoint,
    unit: CGFloat,
    angle: Double,
    sector: Int
  ) -> Path {
    let patterns = [
      [true, true, true], [false, true, true], [true, false, true], [false, false, true],
      [true, true, false], [false, true, false], [true, false, false], [false, false, false],
    ]
    let radial = CGPoint(x: cos(angle), y: sin(angle))
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let node = polarPoint(center: center, radius: unit * 0.325, angle: angle)
    return Path { path in
      for line in 0..<3 {
        let row = CGFloat(line - 1) * unit * 0.012
        let rowCenter = CGPoint(x: node.x + radial.x * row, y: node.y + radial.y * row)
        let half = unit * 0.027
        if patterns[sector][line] {
          path.move(
            to: CGPoint(x: rowCenter.x - tangent.x * half, y: rowCenter.y - tangent.y * half)
          )
          path.addLine(
            to: CGPoint(x: rowCenter.x + tangent.x * half, y: rowCenter.y + tangent.y * half)
          )
        } else {
          for side in [-1.0, 1.0] {
            let sideValue = CGFloat(side)
            path.move(
              to: CGPoint(
                x: rowCenter.x + tangent.x * half * sideValue,
                y: rowCenter.y + tangent.y * half * sideValue
              )
            )
            path.addLine(
              to: CGPoint(
                x: rowCenter.x + tangent.x * unit * 0.006 * sideValue,
                y: rowCenter.y + tangent.y * unit * 0.006 * sideValue
              )
            )
          }
        }
      }
    }
  }

  private func regularPolygon(
    center: CGPoint,
    radius: CGFloat,
    sides: Int,
    rotation: Double
  ) -> Path {
    Path { path in
      for index in 0..<sides {
        let angle = Double(index) * 2 * Double.pi / Double(sides) + rotation
        let point = polarPoint(center: center, radius: radius, angle: angle)
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func lensPath(center: CGPoint, unit: CGFloat) -> Path {
    Path { path in
      path.move(to: CGPoint(x: center.x - unit * 0.22, y: center.y))
      path.addQuadCurve(
        to: CGPoint(x: center.x + unit * 0.22, y: center.y),
        control: CGPoint(x: center.x, y: center.y - unit * 0.13)
      )
      path.addQuadCurve(
        to: CGPoint(x: center.x - unit * 0.22, y: center.y),
        control: CGPoint(x: center.x, y: center.y + unit * 0.13)
      )
    }
  }
}

private struct ThunderFormationCanvas: View {
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool
  let style: FormationVisualStyle

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let rotation = time * (isActivated ? 0.34 : 0.075)
      let rhythm = CGFloat(0.5 + 0.5 * sin(time * 2.4))
      let outwardBeat = 0.84 + rhythm * 0.32
      let inwardBeat = 1.16 - rhythm * 0.32
      let glyphWave = 0.5 + 0.5 * sin(time * 1.38 - 0.6)
      let glyphOpacity = 0.088 + pow(glyphWave, 2.2) * 0.132 + energy * 0.028
      let centerGlyph = context.resolve(
        Text("雷")
          .font(.system(size: unit * 0.58, weight: .black, design: .serif))
          .foregroundStyle(style.secondary.opacity(glyphOpacity))
      )
      var centerGlyphContext = context
      centerGlyphContext.addFilter(.blur(radius: 0.45 + CGFloat(glyphWave) * 0.9))
      centerGlyphContext.draw(centerGlyph, at: center, anchor: .center)

      for ring in 0..<4 {
        let ringFlash = 0.38 + 0.62 * (0.5 + 0.5 * sin(time * 3.1 - Double(ring) * 1.2))
        let radius = unit * (0.19 + CGFloat(ring) * 0.078)
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: center.x - radius,
              y: center.y - radius,
              width: radius * 2,
              height: radius * 2
            )
          ),
          with: .color(
            (ring.isMultiple(of: 2) ? style.primary : style.secondary)
              .opacity((0.14 + Double(3 - ring) * 0.05 + energy * 0.22) * ringFlash)
          ),
          style: StrokeStyle(
            lineWidth: (ring == 3 ? 2.4 : ring == 1 ? 1.65 : 0.72)
              * (ring.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * (0.78 + CGFloat(ringFlash) * 0.44),
            dash: ring == 2 ? [unit * 0.018, unit * 0.012] : []
          )
        )
      }

      // Broken thunder-script bands fill the quiet space between the main rings.
      // Their alternating motion keeps the detail legible instead of reading as
      // another solid circle.
      for band in 0..<2 {
        let radius = unit * (band == 0 ? 0.228 : 0.307)
        let segmentCount = band == 0 ? 14 : 20
        let bandDirection = band.isMultiple(of: 2) ? 1.0 : -1.0
        let bandRotation = rotation * (band == 0 ? -1.35 : 0.92)

        for segment in 0..<segmentCount {
          let segmentAngle =
            Double(segment) * 2 * Double.pi / Double(segmentCount)
            + bandRotation * bandDirection
          let segmentFlash =
            0.18
            + 0.82
            * pow(
              0.5
                + 0.5
                * sin(time * (4.15 + Double(band) * 0.86) - Double(segment) * 0.63),
              2.2
            )
          let halfSpan =
            Double.pi / Double(segmentCount)
            * (segment.isMultiple(of: 3) ? 0.66 : 0.42)
          let segmentColor: Color
          if segment.isMultiple(of: 4) {
            segmentColor = style.flare
          } else if band == 0 {
            segmentColor = style.secondary
          } else {
            segmentColor = style.primary
          }
          var scriptSegment = Path()
          scriptSegment.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(segmentAngle - halfSpan),
            endAngle: .radians(segmentAngle + halfSpan),
            clockwise: false
          )
          context.stroke(
            scriptSegment,
            with: .color(
              segmentColor.opacity((0.14 + energy * 0.22) * segmentFlash)
            ),
            style: StrokeStyle(
              lineWidth: (segment.isMultiple(of: 3) ? 1.55 : 0.72)
                * (0.68 + CGFloat(segmentFlash) * 0.64),
              lineCap: .square
            )
          )
        }
      }

      // Angular conductor paths create a radial seal between the rings. Each
      // path lights independently so the pulse appears to travel around it.
      for conduit in 0..<12 {
        let angle = Double(conduit) * Double.pi / 6 - rotation * 0.46
        let conduitWave =
          0.5
          + 0.5
          * sin(time * (4.7 + Double(conduit % 4) * 0.37) - Double(conduit) * 0.78)
        let conduitFlash = 0.16 + 0.84 * pow(conduitWave, 2.45)
        context.stroke(
          thunderConduitPath(center: center, unit: unit, angle: angle, index: conduit),
          with: .color(
            (conduit.isMultiple(of: 3) ? style.flare : style.secondary)
              .opacity((0.16 + energy * 0.25) * conduitFlash)
          ),
          style: StrokeStyle(
            lineWidth: (conduit.isMultiple(of: 3) ? 1.75 : 0.82)
              * (0.62 + CGFloat(conduitFlash) * 0.72),
            lineCap: .square,
            lineJoin: .miter
          )
        )

        let node = thunderConduitNode(center: center, unit: unit, angle: angle)
        context.fill(
          node,
          with: .color(style.primary.opacity((0.12 + energy * 0.24) * conduitFlash))
        )
        context.stroke(
          node,
          with: .color(Color.white.opacity((0.12 + energy * 0.18) * conduitFlash)),
          lineWidth: 0.45 + CGFloat(conduitFlash) * 0.7
        )
      }

      for sector in 0..<6 {
        let angle = Double(sector) * Double.pi / 3 + rotation
        let sectorFrequency = 5.4 + Double(sector % 4) * 0.62
        let sectorFlash =
          0.24 + 0.76 * (0.5 + 0.5 * sin(time * sectorFrequency - Double(sector) * 1.17))
        let eyeFrequency = 6.8 + Double(sector % 3) * 1.15
        let eyeWave = 0.5 + 0.5 * sin(time * eyeFrequency + Double(sector) * 0.83)
        let eyeFlash = 0.16 + 0.84 * pow(eyeWave, 2.8)
        let connectorFrequency = 5.9 + Double((sector + 2) % 5) * 0.74
        let connectorWave =
          0.5 + 0.5 * sin(time * connectorFrequency - Double(sector) * 1.31)
        let connectorFlash = 0.22 + 0.78 * pow(connectorWave, 2.15)
        var outerSegment = Path()
        outerSegment.addArc(
          center: center,
          radius: unit * 0.485,
          startAngle: .radians(angle - 0.39),
          endAngle: .radians(angle + 0.39),
          clockwise: false
        )
        context.stroke(
          outerSegment,
          with: .color(
            (sector.isMultiple(of: 2) ? style.primary : style.secondary)
              .opacity((0.38 + energy * 0.28) * sectorFlash)
          ),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 6.2 : 4)
              * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * (0.76 + CGFloat(sectorFlash) * 0.46),
            lineCap: .square
          )
        )

        let lightning = inwardLightningPath(
          center: center,
          unit: unit,
          angle: angle,
          seed: sector
        )
        var lightningGlow = context
        lightningGlow.addFilter(.blur(radius: 7 + energy * 7))
        lightningGlow.stroke(
          lightning,
          with: .color(style.primary.opacity((0.38 + energy * 0.3) * connectorFlash)),
          style: StrokeStyle(
            lineWidth: 10 * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * (0.64 + CGFloat(connectorFlash) * 0.58),
            lineCap: .round,
            lineJoin: .miter
          )
        )
        context.stroke(
          lightning,
          with: .linearGradient(
            Gradient(colors: [
              style.secondary.opacity(0.58 + connectorFlash * 0.42),
              style.primary.opacity(0.54 + connectorFlash * 0.46),
              style.flare.opacity(0.62 + connectorFlash * 0.38),
            ]),
            startPoint: polarPoint(center: center, radius: unit * 0.38, angle: angle),
            endPoint: polarPoint(center: center, radius: unit * 0.1, angle: angle)
          ),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 3.6 : 2.3)
              * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * (0.68 + CGFloat(connectorFlash) * 0.52),
            lineCap: .round,
            lineJoin: .miter
          )
        )
        context.stroke(
          lightning,
          with: .color(Color.white.opacity((0.42 + energy * 0.22) * connectorFlash)),
          style: StrokeStyle(
            lineWidth: 0.8 * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * (0.62 + CGFloat(connectorFlash) * 0.72),
            lineCap: .round,
            lineJoin: .miter
          )
        )

        for (branchIndex, branch) in inwardLightningBranchPaths(
          center: center,
          unit: unit,
          angle: angle,
          seed: sector
        ).enumerated() {
          let branchFrequency =
            6.25 + Double(sector) * 0.31 + Double(branchIndex) * 0.83
          let branchFlash =
            0.28
            + 0.72
            * pow(
              0.5
                + 0.5
                * sin(
                  time * branchFrequency
                    + Double(branchIndex + sector) * 0.91
                ),
              1.8
            )
          var branchGlow = context
          branchGlow.addFilter(.blur(radius: 4 + energy * 4))
          branchGlow.stroke(
            branch,
            with: .color(style.primary.opacity((0.34 + energy * 0.24) * branchFlash)),
            style: StrokeStyle(
              lineWidth: (6.2 - CGFloat(branchIndex) * 1.1) * (0.82 + rhythm * 0.34),
              lineCap: .round,
              lineJoin: .miter
            )
          )
          context.stroke(
            branch,
            with: .color(Color.white.opacity((0.62 + energy * 0.2) * branchFlash)),
            style: StrokeStyle(
              lineWidth: (1.9 - CGFloat(branchIndex) * 0.3) * (0.78 + rhythm * 0.38),
              lineCap: .round,
              lineJoin: .miter
            )
          )
        }

        let eye = thunderEyePath(center: center, unit: unit, angle: angle)
        context.fill(
          eye,
          with: .radialGradient(
            Gradient(colors: [
              style.flare.opacity(0.72 * eyeFlash),
              style.primary.opacity((0.2 + energy * 0.16) * eyeFlash),
              .clear,
            ]),
            center: polarPoint(center: center, radius: unit * 0.365, angle: angle),
            startRadius: 0,
            endRadius: unit * 0.055
          )
        )
        context.stroke(
          eye,
          with: .color(style.secondary.opacity((0.48 + energy * 0.28) * eyeFlash)),
          style: StrokeStyle(
            lineWidth: 1.8 * (sector.isMultiple(of: 2) ? inwardBeat : outwardBeat)
              * (0.58 + CGFloat(eyeFlash) * 0.84),
            lineJoin: .round
          )
        )

        let eyeCenter = polarPoint(center: center, radius: unit * 0.365, angle: angle)
        let pupilRadius = unit * (0.006 + CGFloat(eyeFlash) * 0.009)
        var pupilGlow = context
        pupilGlow.addFilter(.blur(radius: 4 + CGFloat(eyeFlash) * 7))
        pupilGlow.fill(
          Path(
            ellipseIn: CGRect(
              x: eyeCenter.x - pupilRadius,
              y: eyeCenter.y - pupilRadius,
              width: pupilRadius * 2,
              height: pupilRadius * 2
            )
          ),
          with: .color(style.flare.opacity((0.42 + energy * 0.26) * eyeFlash))
        )
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: eyeCenter.x - pupilRadius * 0.42,
              y: eyeCenter.y - pupilRadius * 0.42,
              width: pupilRadius * 0.84,
              height: pupilRadius * 0.84
            )
          ),
          with: .color(Color.white.opacity((0.5 + energy * 0.22) * eyeFlash))
        )

        context.stroke(
          outerFlamePath(center: center, unit: unit, angle: angle),
          with: .color(style.primary.opacity((0.34 + energy * 0.3) * connectorFlash)),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 3 : 1.7)
              * (sector.isMultiple(of: 2) ? inwardBeat : outwardBeat)
              * (0.68 + CGFloat(connectorFlash) * 0.62),
            lineCap: .round,
            lineJoin: .round
          )
        )
      }

      for rune in 0..<18 {
        let angle = Double(rune) * 2 * Double.pi / 18 - rotation * 0.75
        let runeFlash = 0.2 + 0.8 * (0.5 + 0.5 * sin(time * 4.8 - Double(rune) * 0.72))
        context.stroke(
          chevronPath(center: center, unit: unit, angle: angle),
          with: .color(
            (rune.isMultiple(of: 3) ? style.flare : style.primary)
              .opacity((0.28 + energy * 0.25) * runeFlash)
          ),
          style: StrokeStyle(
            lineWidth: (rune.isMultiple(of: 3) ? 1.8 : 0.8)
              * (rune.isMultiple(of: 2) ? outwardBeat : inwardBeat),
            lineCap: .round,
            lineJoin: .miter
          )
        )
      }

      for layer in 0..<3 {
        let sides = layer == 2 ? 6 : 3
        let layerFlash = 0.42 + 0.58 * (0.5 + 0.5 * sin(time * 3.7 + Double(layer) * 1.8))
        context.stroke(
          regularPolygon(
            center: center,
            radius: unit * (0.14 + CGFloat(layer) * 0.085),
            sides: sides,
            rotation: rotation * (layer.isMultiple(of: 2) ? 0.72 : -0.9)
              + Double(layer) * Double.pi / 3
          ),
          with: .color(
            (layer == 1 ? style.secondary : style.primary)
              .opacity((0.28 + energy * 0.3) * layerFlash)
          ),
          style: StrokeStyle(
            lineWidth: (layer == 1 ? 2.4 : 0.95)
              * (layer.isMultiple(of: 2) ? outwardBeat : inwardBeat),
            lineJoin: .miter,
            dash: layer == 2 ? [10, 5, 2, 5] : []
          )
        )
      }
    }
    .blendMode(.plusLighter)
  }

  private func polarPoint(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
    CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
  }

  private func inwardLightningPath(
    center: CGPoint,
    unit: CGFloat,
    angle: Double,
    seed: Int
  ) -> Path {
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let radii: [CGFloat] = [0.39, 0.335, 0.3, 0.245, 0.205, 0.145, 0.095]
    return Path { path in
      for (index, radius) in radii.enumerated() {
        let wobble =
          index == 0 || index == radii.count - 1
          ? 0
          : CGFloat((index + seed).isMultiple(of: 2) ? 1 : -1)
            * unit * (0.014 + CGFloat((index + seed) % 3) * 0.005)
        let point = polarPoint(center: center, radius: unit * radius, angle: angle)
        let displaced = CGPoint(
          x: point.x + tangent.x * wobble,
          y: point.y + tangent.y * wobble
        )
        index == 0 ? path.move(to: displaced) : path.addLine(to: displaced)
      }
    }
  }

  private func thunderConduitPath(
    center: CGPoint,
    unit: CGFloat,
    angle: Double,
    index: Int
  ) -> Path {
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
    let radii: [CGFloat] = [0.16, 0.214, 0.238, 0.286, 0.315]
    let offsets: [CGFloat] = [0, 0, 0.018 * direction, 0.018 * direction, 0]

    return Path { path in
      for (pointIndex, radius) in radii.enumerated() {
        let base = polarPoint(center: center, radius: unit * radius, angle: angle)
        let offset = unit * offsets[pointIndex]
        let point = CGPoint(
          x: base.x + tangent.x * offset,
          y: base.y + tangent.y * offset
        )
        pointIndex == 0 ? path.move(to: point) : path.addLine(to: point)
      }
    }
  }

  private func thunderConduitNode(
    center: CGPoint,
    unit: CGFloat,
    angle: Double
  ) -> Path {
    let radial = CGPoint(x: cos(angle), y: sin(angle))
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let node = polarPoint(center: center, radius: unit * 0.315, angle: angle)
    let radialSize = unit * 0.012
    let tangentSize = unit * 0.008

    return Path { path in
      path.move(
        to: CGPoint(x: node.x + radial.x * radialSize, y: node.y + radial.y * radialSize)
      )
      path.addLine(
        to: CGPoint(x: node.x + tangent.x * tangentSize, y: node.y + tangent.y * tangentSize)
      )
      path.addLine(
        to: CGPoint(x: node.x - radial.x * radialSize, y: node.y - radial.y * radialSize)
      )
      path.addLine(
        to: CGPoint(x: node.x - tangent.x * tangentSize, y: node.y - tangent.y * tangentSize)
      )
      path.closeSubpath()
    }
  }

  private func inwardLightningBranchPaths(
    center: CGPoint,
    unit: CGFloat,
    angle: Double,
    seed: Int
  ) -> [Path] {
    let radial = CGPoint(x: cos(angle), y: sin(angle))
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let startRadii: [CGFloat] = [0.315, 0.248, 0.19]

    return startRadii.enumerated().map { branchIndex, radius in
      let direction: CGFloat = (branchIndex + seed).isMultiple(of: 2) ? 1 : -1
      let start = polarPoint(center: center, radius: unit * radius, angle: angle)
      return Path { path in
        path.move(to: start)
        for step in 1...4 {
          let progress = CGFloat(step) / 4
          let sideReach = unit * (0.045 + CGFloat(branchIndex) * 0.012) * progress
          let inwardReach = unit * (0.026 + CGFloat(branchIndex) * 0.007) * progress
          let jitter =
            CGFloat((step + branchIndex + seed).isMultiple(of: 2) ? 1 : -1)
            * unit * 0.009
          path.addLine(
            to: CGPoint(
              x: start.x + tangent.x * (sideReach * direction + jitter)
                - radial.x * inwardReach,
              y: start.y + tangent.y * (sideReach * direction + jitter)
                - radial.y * inwardReach
            )
          )
        }
      }
    }
  }

  private func thunderEyePath(center: CGPoint, unit: CGFloat, angle: Double) -> Path {
    let radial = CGPoint(x: cos(angle), y: sin(angle))
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let node = polarPoint(center: center, radius: unit * 0.365, angle: angle)
    return Path { path in
      let left = CGPoint(x: node.x - tangent.x * unit * 0.055, y: node.y - tangent.y * unit * 0.055)
      let right = CGPoint(
        x: node.x + tangent.x * unit * 0.055, y: node.y + tangent.y * unit * 0.055)
      path.move(to: left)
      path.addQuadCurve(
        to: right,
        control: CGPoint(x: node.x + radial.x * unit * 0.037, y: node.y + radial.y * unit * 0.037)
      )
      path.addQuadCurve(
        to: left,
        control: CGPoint(x: node.x - radial.x * unit * 0.037, y: node.y - radial.y * unit * 0.037)
      )
      path.move(
        to: CGPoint(x: node.x - radial.x * unit * 0.02, y: node.y - radial.y * unit * 0.02)
      )
      path.addLine(
        to: CGPoint(x: node.x + radial.x * unit * 0.02, y: node.y + radial.y * unit * 0.02)
      )
    }
  }

  private func outerFlamePath(center: CGPoint, unit: CGFloat, angle: Double) -> Path {
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    return Path { path in
      for step in 0...6 {
        let fraction = CGFloat(step) / 6
        let point = polarPoint(
          center: center,
          radius: unit * (0.405 + fraction * 0.075),
          angle: angle
        )
        let wobble = sin(Double(step) * 2.1 + time * 1.4) * Double(unit) * 0.012
        let displaced = CGPoint(
          x: point.x + tangent.x * CGFloat(wobble),
          y: point.y + tangent.y * CGFloat(wobble)
        )
        step == 0 ? path.move(to: displaced) : path.addLine(to: displaced)
      }
    }
  }

  private func chevronPath(center: CGPoint, unit: CGFloat, angle: Double) -> Path {
    let radial = CGPoint(x: cos(angle), y: sin(angle))
    let tangent = CGPoint(x: -sin(angle), y: cos(angle))
    let node = polarPoint(center: center, radius: unit * 0.425, angle: angle)
    return Path { path in
      path.move(
        to: CGPoint(x: node.x - tangent.x * unit * 0.012, y: node.y - tangent.y * unit * 0.012)
      )
      path.addLine(
        to: CGPoint(x: node.x + radial.x * unit * 0.012, y: node.y + radial.y * unit * 0.012)
      )
      path.addLine(
        to: CGPoint(x: node.x + tangent.x * unit * 0.012, y: node.y + tangent.y * unit * 0.012)
      )
    }
  }

  private func regularPolygon(
    center: CGPoint,
    radius: CGFloat,
    sides: Int,
    rotation: Double
  ) -> Path {
    Path { path in
      for index in 0..<sides {
        let angle = Double(index) * 2 * Double.pi / Double(sides) + rotation
        let point = polarPoint(center: center, radius: radius, angle: angle)
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }
}
