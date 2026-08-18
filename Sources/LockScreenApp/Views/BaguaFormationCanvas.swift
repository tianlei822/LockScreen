import SwiftUI

struct BaguaFormationCanvas: View {
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
