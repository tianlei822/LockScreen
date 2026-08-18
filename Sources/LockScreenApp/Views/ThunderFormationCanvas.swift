import SwiftUI

struct ThunderFormationCanvas: View {
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
      centerGlyphContext.addFilter(.blur(radius: 4.5 + CGFloat(glyphWave) * 4.5))
      centerGlyphContext.draw(centerGlyph, at: center, anchor: .center)

      for ring in 0..<4 {
        let ringFlash = 0.38 + 0.62 * (0.5 + 0.5 * sin(time * 3.1 - Double(ring) * 1.2))
        let ringLineScale =
          ring.isMultiple(of: 2)
          ? breathingLineScale(
            frequency: 1.72 + Double(ring) * 0.08,
            phase: -Double(ring) * 1.15
          )
          : 1
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
            lineWidth: (ring == 3 ? 2.4 : ring == 1 ? 1.65 : 0.82)
              * (ring.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * (0.78 + CGFloat(ringFlash) * 0.44)
              * ringLineScale,
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
          let segmentLineScale = breathingLineScale(
            frequency: 1.86 + Double(band) * 0.16,
            phase: -Double(segment) * 0.51 - Double(band) * 0.8
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
              segmentColor.opacity(
                (0.16 + energy * 0.24) * (0.42 + segmentFlash * 0.58)
              )
            ),
            style: StrokeStyle(
              lineWidth: (segment.isMultiple(of: 3) ? 1.5 : 0.86)
                * (0.72 + CGFloat(segmentFlash) * 0.46)
                * segmentLineScale,
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
        let conduitLineScale = breathingLineScale(
          frequency: 1.64 + Double(conduit % 3) * 0.13,
          phase: -Double(conduit) * 0.72
        )
        context.stroke(
          thunderConduitPath(center: center, unit: unit, angle: angle, index: conduit),
          with: .color(
            (conduit.isMultiple(of: 3) ? style.flare : style.secondary)
              .opacity((0.17 + energy * 0.26) * (0.4 + conduitFlash * 0.6))
          ),
          style: StrokeStyle(
            lineWidth: (conduit.isMultiple(of: 3) ? 1.7 : 0.9)
              * (0.7 + CGFloat(conduitFlash) * 0.5)
              * conduitLineScale,
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
        let runeLineScale = breathingLineScale(
          frequency: 1.92 + Double(rune % 4) * 0.09,
          phase: -Double(rune) * 0.6
        )
        context.stroke(
          chevronPath(center: center, unit: unit, angle: angle),
          with: .color(
            (rune.isMultiple(of: 3) ? style.flare : style.primary)
              .opacity((0.29 + energy * 0.26) * (0.38 + runeFlash * 0.62))
          ),
          style: StrokeStyle(
            lineWidth: (rune.isMultiple(of: 3) ? 1.7 : 0.88)
              * (rune.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * runeLineScale,
            lineCap: .round,
            lineJoin: .miter
          )
        )
      }

      for layer in 0..<3 {
        let sides = layer == 2 ? 6 : 3
        let layerFlash = 0.42 + 0.58 * (0.5 + 0.5 * sin(time * 3.7 + Double(layer) * 1.8))
        let layerLineScale =
          layer == 1
          ? 1
          : breathingLineScale(
            frequency: 1.48 + Double(layer) * 0.16,
            phase: Double(layer) * 1.9
          )
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
              * (layer.isMultiple(of: 2) ? outwardBeat : inwardBeat)
              * layerLineScale,
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

  private func breathingLineScale(frequency: Double, phase: Double) -> CGFloat {
    let wave = 0.5 + 0.5 * sin(time * frequency + phase)
    return 0.82 + CGFloat(pow(wave, 2.3)) * 1.58
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
