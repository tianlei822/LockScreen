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

private struct BaguaFormationCanvas: View {
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool
  let style: FormationVisualStyle

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let rotation = time * (isActivated ? 0.22 : 0.055)

      for ring in 0..<5 {
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
              .opacity(0.2 + Double(4 - ring) * 0.045 + energy * 0.18)
          ),
          style: StrokeStyle(
            lineWidth: ring == 4 ? 2.8 : ring == 2 ? 1.8 : 0.75,
            dash: ring == 3 ? [unit * 0.014, unit * 0.01] : []
          )
        )
      }

      for sector in 0..<8 {
        let angle = Double(sector) * Double.pi / 4 + rotation
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
          with: .color(style.primary.opacity(0.46 + energy * 0.28)),
          style: StrokeStyle(
            lineWidth: sector.isMultiple(of: 2) ? 5.2 : 3.2,
            lineCap: .square
          )
        )

        context.stroke(
          circuitRunePath(center: center, unit: unit, angle: angle),
          with: .color(style.secondary.opacity(0.58 + energy * 0.22)),
          style: StrokeStyle(lineWidth: sector.isMultiple(of: 2) ? 1.9 : 1.25, lineJoin: .miter)
        )

        let crystal = crystalPath(center: center, unit: unit, angle: angle)
        var crystalGlow = context
        crystalGlow.addFilter(.blur(radius: 6 + energy * 6))
        crystalGlow.stroke(
          crystal,
          with: .color(style.primary.opacity(0.4 + energy * 0.25)),
          lineWidth: 6
        )
        context.stroke(
          crystal,
          with: .color(Color.white.opacity(0.48 + energy * 0.22)),
          style: StrokeStyle(lineWidth: 1.45, lineJoin: .miter)
        )

        context.stroke(
          trigramPath(center: center, unit: unit, angle: angle, sector: sector),
          with: .color(style.primary.opacity(0.62 + energy * 0.24)),
          style: StrokeStyle(lineWidth: 2.1, lineCap: .square)
        )
      }

      for layer in 0..<3 {
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
              .opacity(0.25 + energy * 0.22)
          ),
          style: StrokeStyle(lineWidth: layer == 1 ? 1.8 : 0.85, lineJoin: .miter)
        )
      }

      context.stroke(
        lensPath(center: center, unit: unit),
        with: .color(style.secondary.opacity(0.44 + energy * 0.26)),
        style: StrokeStyle(lineWidth: 2.2, lineJoin: .round)
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
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let rotation = time * (isActivated ? 0.34 : 0.075)
      let rhythm = CGFloat(0.5 + 0.5 * sin(time * 2.4))
      let outwardBeat = 0.84 + rhythm * 0.32
      let inwardBeat = 1.16 - rhythm * 0.32

      for ring in 0..<4 {
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
              .opacity(0.18 + Double(3 - ring) * 0.055 + energy * 0.22)
          ),
          style: StrokeStyle(
            lineWidth: (ring == 3 ? 2.4 : ring == 1 ? 1.65 : 0.72)
              * (ring.isMultiple(of: 2) ? outwardBeat : inwardBeat),
            dash: ring == 2 ? [unit * 0.018, unit * 0.012] : []
          )
        )
      }

      for sector in 0..<6 {
        let angle = Double(sector) * Double.pi / 3 + rotation
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
              .opacity(0.52 + energy * 0.28)
          ),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 6.2 : 4)
              * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat),
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
          with: .color(style.primary.opacity(0.48 + energy * 0.3)),
          style: StrokeStyle(
            lineWidth: 10 * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat),
            lineCap: .round,
            lineJoin: .miter
          )
        )
        context.stroke(
          lightning,
          with: .linearGradient(
            Gradient(colors: [style.secondary, style.primary, style.flare]),
            startPoint: polarPoint(center: center, radius: unit * 0.38, angle: angle),
            endPoint: polarPoint(center: center, radius: unit * 0.1, angle: angle)
          ),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 3.6 : 2.3)
              * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat),
            lineCap: .round,
            lineJoin: .miter
          )
        )
        context.stroke(
          lightning,
          with: .color(Color.white.opacity(0.62 + energy * 0.18)),
          style: StrokeStyle(
            lineWidth: 0.8 * (sector.isMultiple(of: 2) ? outwardBeat : inwardBeat),
            lineCap: .round,
            lineJoin: .miter
          )
        )

        let eye = thunderEyePath(center: center, unit: unit, angle: angle)
        context.fill(
          eye,
          with: .radialGradient(
            Gradient(colors: [
              style.flare.opacity(0.7),
              style.primary.opacity(0.28),
              .clear,
            ]),
            center: polarPoint(center: center, radius: unit * 0.365, angle: angle),
            startRadius: 0,
            endRadius: unit * 0.055
          )
        )
        context.stroke(
          eye,
          with: .color(style.secondary.opacity(0.72 + energy * 0.2)),
          style: StrokeStyle(
            lineWidth: 1.8 * (sector.isMultiple(of: 2) ? inwardBeat : outwardBeat),
            lineJoin: .round
          )
        )

        context.stroke(
          outerFlamePath(center: center, unit: unit, angle: angle),
          with: .color(style.primary.opacity(0.44 + energy * 0.3)),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 3 : 1.7)
              * (sector.isMultiple(of: 2) ? inwardBeat : outwardBeat),
            lineCap: .round,
            lineJoin: .round
          )
        )
      }

      for rune in 0..<18 {
        let angle = Double(rune) * 2 * Double.pi / 18 - rotation * 0.75
        context.stroke(
          chevronPath(center: center, unit: unit, angle: angle),
          with: .color(
            (rune.isMultiple(of: 3) ? style.flare : style.primary)
              .opacity(0.38 + energy * 0.25)
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
              .opacity(0.34 + energy * 0.3)
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
