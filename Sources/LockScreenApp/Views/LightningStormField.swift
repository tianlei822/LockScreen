import SwiftUI

enum LightningFieldPresentation {
  case backdrop
  case core
}

/// A seeded lightning weather field. Geometry stays stable during a flash,
/// then regenerates with new origins, landing points and branches next cycle.
struct LightningStormField: View {
  let style: FormationVisualStyle
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool
  let seedOffset: Int
  let presentation: LightningFieldPresentation

  private let cycleDuration = 2.1

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let strike = strikeState(at: time)
      let intensity = strike.intensity * (isActivated ? 1.22 : 0.72 + energy * 0.38)

      ZStack {
        if presentation == .backdrop {
          thunderGlyphField(size: size, intensity: intensity)
          cloudBank(size: size, strike: strike, intensity: intensity)
        }

        Canvas { context, canvasSize in
          guard intensity > 0.004 else { return }
          var random = SeededLightningRandom(seed: strike.seed)
          let boltCount = presentation == .backdrop ? 3 : 1

          for boltIndex in 0..<boltCount {
            let geometry = lightningGeometry(
              in: canvasSize,
              random: &random,
              isDistant: boltIndex > 0
            )
            let distanceFade = boltIndex == 0 ? 1.0 : 0.36
            draw(
              geometry,
              in: &context,
              intensity: intensity * distanceFade,
              isDistant: boltIndex > 0
            )
          }
        }

        if presentation == .backdrop {
          Color.white
            .opacity(intensity * 0.16)
            .blendMode(.screen)
        } else {
          RadialGradient(
            colors: [Color.white.opacity(intensity * 0.07), .clear],
            center: .center,
            startRadius: 0,
            endRadius: min(size.width, size.height) * 0.5
          )
          .blendMode(.screen)
        }
      }
      .frame(width: size.width, height: size.height)
      .clipped()
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
  }

  private func strikeState(at time: TimeInterval) -> LightningStrikeState {
    let epoch = Int(floor(time / cycleDuration))
    let localTime = time - Double(epoch) * cycleDuration
    let seed = UInt64(bitPattern: Int64(epoch &* 7_919 &+ seedOffset &* 104_729))
    var random = SeededLightningRandom(seed: seed)
    let strikeTime = 0.22 + random.next() * 0.82
    let age = localTime - strikeTime
    let first = gaussian(age, width: 0.13)
    let returnStroke = gaussian(age - 0.2, width: 0.095) * 0.88
    let afterFlash = gaussian(age - 0.43, width: 0.18) * 0.46
    let ionizedAfterglow = gaussian(age - 0.72, width: 0.3) * 0.14

    return LightningStrikeState(
      seed: seed,
      intensity: min(1, first + returnStroke + afterFlash + ionizedAfterglow),
      cloudCenter: UnitPoint(x: 0.14 + random.next() * 0.72, y: 0.08 + random.next() * 0.28)
    )
  }

  private func gaussian(_ value: Double, width: Double) -> Double {
    exp(-pow(value / width, 2))
  }

  private func cloudBank(
    size: CGSize,
    strike: LightningStrikeState,
    intensity: Double
  ) -> some View {
    ZStack {
      RadialGradient(
        colors: [
          Color.white.opacity(intensity * 0.18),
          style.primary.opacity(0.025 + intensity * 0.24),
          style.secondary.opacity(intensity * 0.08),
          .clear,
        ],
        center: strike.cloudCenter,
        startRadius: 0,
        endRadius: max(size.width, size.height) * 0.48
      )
      .blendMode(.plusLighter)

      Canvas { context, canvasSize in
        let cloudSeed = UInt64(bitPattern: Int64(seedOffset &* 104_729)) &+ 0x9E37_79B9
        var random = SeededLightningRandom(seed: cloudSeed)

        for index in 0..<8 {
          let baseAngle = Double(index) / 8 * 2 * Double.pi + random.next() * 0.32
          let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
          let angle = baseAngle + time * (0.018 + random.next() * 0.012) * direction
          let drift = sin(time * (0.18 + Double(index) * 0.015) + Double(index))
          let center = CGPoint(
            x: canvasSize.width * 0.5 + cos(angle) * canvasSize.width * 0.41,
            y: canvasSize.height * 0.5 + sin(angle) * canvasSize.height * 0.37
              + drift * canvasSize.height * 0.012
          )
          let width = canvasSize.width * (0.13 + random.next() * 0.1)
          let height = canvasSize.height * (0.05 + random.next() * 0.035)
          let flicker = pow(
            0.5 + 0.5 * sin(time * (2.25 + Double(index) * 0.31) + Double(index) * 1.7),
            6
          )
          let path = thunderCloudPath(center: center, width: width, height: height)
          let shadowPath = thunderCloudPath(
            center: CGPoint(x: center.x, y: center.y + height * 0.14),
            width: width * 0.94,
            height: height * 0.88
          )
          var haze = context
          haze.addFilter(.blur(radius: 12))
          haze.fill(
            path,
            with: .color(
              style.primary.opacity(0.065 + intensity * 0.1 + flicker * 0.14)
            )
          )
          context.fill(
            shadowPath,
            with: .color(
              Color(red: 0.025, green: 0.03, blue: 0.075).opacity(0.32 + flicker * 0.12)
            )
          )
          context.fill(
            path,
            with: .linearGradient(
              Gradient(colors: [
                style.secondary.opacity(0.055 + flicker * 0.12),
                Color(red: 0.07, green: 0.075, blue: 0.15)
                  .opacity(0.34 + flicker * 0.12),
                Color(red: 0.025, green: 0.03, blue: 0.08)
                  .opacity(0.46 + flicker * 0.08),
              ]),
              startPoint: CGPoint(x: center.x, y: center.y - height * 0.54),
              endPoint: CGPoint(x: center.x, y: center.y + height * 0.34)
            )
          )
          context.stroke(
            thunderCloudRimPath(center: center, width: width, height: height),
            with: .color(
              style.secondary.opacity(0.08 + intensity * 0.12 + flicker * 0.32)
            ),
            lineWidth: 0.7 + flicker * 1.4
          )
          context.stroke(
            thunderCloudUndersidePath(center: center, width: width, height: height),
            with: .color(
              style.primary.opacity(0.07 + intensity * 0.14 + flicker * 0.38)
            ),
            style: StrokeStyle(
              lineWidth: 0.75 + flicker * 1.65,
              lineCap: .round,
              lineJoin: .round
            )
          )

          if index.isMultiple(of: 3), flicker > 0.2 {
            let spark = thunderCloudSparkPath(
              center: center,
              width: width,
              height: height,
              direction: index.isMultiple(of: 2) ? 1 : -1
            )
            context.stroke(
              spark,
              with: .color(style.primary.opacity((0.16 + intensity * 0.24) * flicker)),
              style: StrokeStyle(lineWidth: 2.8 + flicker * 2.1, lineCap: .round)
            )
            context.stroke(
              spark,
              with: .color(Color.white.opacity((0.2 + intensity * 0.28) * flicker)),
              style: StrokeStyle(lineWidth: 0.55 + flicker * 0.52, lineCap: .round)
            )
          }
        }
      }
    }
  }

  private func thunderGlyphField(size: CGSize, intensity: Double) -> some View {
    Canvas { context, canvasSize in
      let unit = min(canvasSize.width, canvasSize.height)
      typealias GlyphPlacement = (
        x: CGFloat,
        y: CGFloat,
        scale: CGFloat,
        phase: Double,
        rotation: Double
      )
      let placements: [GlyphPlacement] = [
        (0.11, 0.2, 0.115, 0.2, -0.12),
        (0.5, 0.08, 0.085, 1.4, 0.08),
        (0.88, 0.18, 0.14, 2.5, 0.14),
        (0.06, 0.58, 0.095, 3.2, 0.1),
        (0.94, 0.56, 0.11, 4.1, -0.09),
        (0.2, 0.87, 0.145, 5.0, -0.15),
        (0.82, 0.86, 0.1, 5.8, 0.12),
      ]

      for (index, placement) in placements.enumerated() {
        let pulse =
          0.5
          + 0.5
          * sin(time * (0.72 + Double(index % 3) * 0.11) + placement.phase)
        let driftX = sin(time * 0.16 + placement.phase) * canvasSize.width * 0.012
        let driftY = cos(time * 0.13 + placement.phase) * canvasSize.height * 0.009
        let opacity = 0.055 + pulse * 0.082 + intensity * 0.06
        let glyph = context.resolve(
          Text("雷")
            .font(.system(size: unit * placement.scale, weight: .black, design: .serif))
            .foregroundStyle(
              (index.isMultiple(of: 2) ? style.primary : style.secondary).opacity(opacity)
            )
        )
        var glyphContext = context
        glyphContext.addFilter(.blur(radius: 1.8 + CGFloat(index % 3) * 1.05))
        glyphContext.translateBy(
          x: canvasSize.width * placement.x + driftX,
          y: canvasSize.height * placement.y + driftY
        )
        glyphContext.rotate(by: .radians(placement.rotation))
        glyphContext.draw(glyph, at: .zero, anchor: .center)
      }
    }
    .blendMode(.plusLighter)
  }

  private func thunderCloudPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
    var path = Path()
    path.addEllipse(
      in: CGRect(
        x: center.x - width * 0.5,
        y: center.y - height * 0.08,
        width: width,
        height: height * 0.62
      ))
    path.addEllipse(
      in: CGRect(
        x: center.x - width * 0.38,
        y: center.y - height * 0.42,
        width: width * 0.42,
        height: height * 0.78
      ))
    path.addEllipse(
      in: CGRect(
        x: center.x - width * 0.08,
        y: center.y - height * 0.55,
        width: width * 0.48,
        height: height * 0.95
      ))
    path.addEllipse(
      in: CGRect(
        x: center.x + width * 0.2,
        y: center.y - height * 0.3,
        width: width * 0.3,
        height: height * 0.68
      ))
    return path
  }

  private func thunderCloudRimPath(center: CGPoint, width: CGFloat, height: CGFloat) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: center.x - width * 0.46, y: center.y + height * 0.08))
    path.addCurve(
      to: CGPoint(x: center.x - width * 0.18, y: center.y - height * 0.18),
      control1: CGPoint(x: center.x - width * 0.42, y: center.y - height * 0.12),
      control2: CGPoint(x: center.x - width * 0.3, y: center.y - height * 0.28)
    )
    path.addCurve(
      to: CGPoint(x: center.x + width * 0.12, y: center.y - height * 0.3),
      control1: CGPoint(x: center.x - width * 0.08, y: center.y - height * 0.5),
      control2: CGPoint(x: center.x + width * 0.06, y: center.y - height * 0.52)
    )
    path.addCurve(
      to: CGPoint(x: center.x + width * 0.46, y: center.y + height * 0.08),
      control1: CGPoint(x: center.x + width * 0.25, y: center.y - height * 0.3),
      control2: CGPoint(x: center.x + width * 0.4, y: center.y - height * 0.12)
    )
    return path
  }

  private func thunderCloudUndersidePath(
    center: CGPoint,
    width: CGFloat,
    height: CGFloat
  ) -> Path {
    Path { path in
      path.move(to: CGPoint(x: center.x - width * 0.46, y: center.y + height * 0.16))
      path.addCurve(
        to: CGPoint(x: center.x - width * 0.15, y: center.y + height * 0.27),
        control1: CGPoint(x: center.x - width * 0.36, y: center.y + height * 0.24),
        control2: CGPoint(x: center.x - width * 0.26, y: center.y + height * 0.29)
      )
      path.addCurve(
        to: CGPoint(x: center.x + width * 0.16, y: center.y + height * 0.24),
        control1: CGPoint(x: center.x - width * 0.04, y: center.y + height * 0.18),
        control2: CGPoint(x: center.x + width * 0.05, y: center.y + height * 0.32)
      )
      path.addCurve(
        to: CGPoint(x: center.x + width * 0.46, y: center.y + height * 0.13),
        control1: CGPoint(x: center.x + width * 0.28, y: center.y + height * 0.28),
        control2: CGPoint(x: center.x + width * 0.38, y: center.y + height * 0.22)
      )
    }
  }

  private func thunderCloudSparkPath(
    center: CGPoint,
    width: CGFloat,
    height: CGFloat,
    direction: CGFloat
  ) -> Path {
    Path { path in
      let start = CGPoint(
        x: center.x + width * 0.08 * direction,
        y: center.y + height * 0.2
      )
      path.move(to: start)
      path.addLine(
        to: CGPoint(x: start.x - width * 0.035 * direction, y: start.y + height * 0.18)
      )
      path.addLine(
        to: CGPoint(x: start.x + width * 0.02 * direction, y: start.y + height * 0.27)
      )
      path.addLine(
        to: CGPoint(x: start.x - width * 0.07 * direction, y: start.y + height * 0.46)
      )
      path.addLine(
        to: CGPoint(x: start.x - width * 0.015 * direction, y: start.y + height * 0.58)
      )
    }
  }

  private func lightningGeometry(
    in size: CGSize,
    random: inout SeededLightningRandom,
    isDistant: Bool
  ) -> LightningGeometry {
    let usesSideCloud = isDistant && random.next() > 0.38
    let origin: CGPoint
    let target: CGPoint

    if usesSideCloud {
      let entersFromLeft = random.next() > 0.5
      origin = CGPoint(
        x: size.width * (entersFromLeft ? -0.025 : 1.025),
        y: size.height * (0.14 + random.next() * 0.48)
      )
      target = CGPoint(
        x: size.width * (0.2 + random.next() * 0.6),
        y: origin.y + size.height * (0.04 + random.next() * 0.2)
      )
    } else {
      origin = CGPoint(
        x: size.width * (0.08 + random.next() * 0.84),
        y: -size.height * (0.02 + random.next() * 0.08)
      )
      target = CGPoint(
        x: size.width * (0.12 + random.next() * 0.76),
        y: size.height * (isDistant ? 0.34 + random.next() * 0.38 : 0.78 + random.next() * 0.25)
      )
    }
    let stepCount = (isDistant ? 9 : 14) + Int(random.next() * (isDistant ? 5 : 7))
    var points = [origin]
    let deltaX = target.x - origin.x
    let deltaY = target.y - origin.y
    let distance = max(1, hypot(deltaX, deltaY))
    let normal = CGPoint(x: -deltaY / distance, y: deltaX / distance)

    for step in 1..<stepCount {
      let fraction = CGFloat(step) / CGFloat(stepCount)
      let envelope = 0.35 + sin(Double(fraction) * .pi) * 0.65
      let baseX = origin.x + (target.x - origin.x) * fraction
      let baseY = origin.y + (target.y - origin.y) * fraction
      let jitter =
        (random.next() - 0.5) * Double(min(size.width, size.height)) * 0.12 * envelope
      points.append(
        CGPoint(
          x: baseX + normal.x * jitter,
          y: baseY + normal.y * jitter
        ))
    }
    points.append(target)

    let trunk = lightningStroke(connecting: points, endScale: isDistant ? 0.34 : 0.48)
    let branchCount = (isDistant ? 2 : 6) + Int(random.next() * (isDistant ? 3 : 6))
    var branches: [LightningStroke] = []

    for _ in 0..<branchCount {
      let startIndex = 2 + Int(random.next() * Double(max(1, points.count - 5)))
      let start = points[min(startIndex, points.count - 3)]
      let direction = random.next() > 0.5 ? 1.0 : -1.0
      let branchSteps = 3 + Int(random.next() * 5)
      let horizontalReach = size.width * (0.055 + random.next() * 0.17) * direction
      let verticalReach = size.height * (0.05 + random.next() * 0.2)
      var branchPoints = [start]

      for step in 1...branchSteps {
        let fraction = CGFloat(step) / CGFloat(branchSteps)
        branchPoints.append(
          CGPoint(
            x: start.x + horizontalReach * fraction
              + (random.next() - 0.5) * Double(size.width) * 0.025,
            y: start.y + verticalReach * fraction
          ))
      }
      branches.append(lightningStroke(connecting: branchPoints, endScale: 0.2))
    }

    return LightningGeometry(trunk: trunk, branches: branches)
  }

  private func lightningStroke(
    connecting points: [CGPoint],
    endScale: CGFloat
  ) -> LightningStroke {
    var path = Path()
    guard let first = points.first else {
      return LightningStroke(path: path, segments: [])
    }
    path.move(to: first)
    for point in points.dropFirst() {
      path.addLine(to: point)
    }

    let segmentCount = max(1, points.count - 1)
    let segments = zip(points, points.dropFirst()).enumerated().map {
      index, pair -> LightningSegment in
      let (start, end) = pair
      let progress = CGFloat(index) / CGFloat(segmentCount)
      let taper = 1 - progress * (1 - endScale)
      let geometryPhase = Double(start.x * 0.071 + start.y * 0.043 + CGFloat(index) * 1.93)
      let irregularity = CGFloat(0.62 + abs(sin(geometryPhase)) * 0.82)
      var segmentPath = Path()
      segmentPath.move(to: start)
      segmentPath.addLine(to: end)
      return LightningSegment(
        path: segmentPath,
        widthScale: max(0.22, taper * irregularity)
      )
    }

    return LightningStroke(path: path, segments: segments)
  }

  private func draw(
    _ geometry: LightningGeometry,
    in context: inout GraphicsContext,
    intensity: Double,
    isDistant: Bool
  ) {
    var aura = context
    aura.addFilter(.blur(radius: isDistant ? 9 : 14 + energy * 8))
    aura.stroke(
      geometry.trunk.path,
      with: .color(style.primary.opacity(intensity * (isDistant ? 0.42 : 0.78))),
      style: StrokeStyle(
        lineWidth: isDistant ? 5 : 13 + energy * 8,
        lineCap: .round,
        lineJoin: .round
      )
    )

    let trunkBaseWidth = isDistant ? 0.8 : 1.8 + energy * 2.2
    for segment in geometry.trunk.segments {
      context.stroke(
        segment.path,
        with: .color(style.primary.opacity(intensity * (isDistant ? 0.38 : 0.68))),
        style: StrokeStyle(
          lineWidth: trunkBaseWidth * segment.widthScale * 2.2,
          lineCap: .round,
          lineJoin: .round
        )
      )
      context.stroke(
        segment.path,
        with: .color(Color.white.opacity(intensity * (isDistant ? 0.58 : 0.98))),
        style: StrokeStyle(
          lineWidth: trunkBaseWidth * segment.widthScale,
          lineCap: .round,
          lineJoin: .round
        )
      )
    }

    for branch in geometry.branches {
      var branchGlow = context
      branchGlow.addFilter(.blur(radius: isDistant ? 4 : 7))
      branchGlow.stroke(
        branch.path,
        with: .color(style.secondary.opacity(intensity * 0.58)),
        style: StrokeStyle(lineWidth: isDistant ? 2.8 : 6 + energy * 4, lineCap: .round)
      )

      let branchBaseWidth = isDistant ? 0.62 : 1.2 + energy * 1.15
      for segment in branch.segments {
        context.stroke(
          segment.path,
          with: .color(style.primary.opacity(intensity * (isDistant ? 0.48 : 0.86))),
          style: StrokeStyle(
            lineWidth: branchBaseWidth * segment.widthScale * 1.8,
            lineCap: .round
          )
        )
        context.stroke(
          segment.path,
          with: .color(Color.white.opacity(intensity * (isDistant ? 0.52 : 0.94))),
          style: StrokeStyle(
            lineWidth: branchBaseWidth * segment.widthScale * 0.68,
            lineCap: .round
          )
        )
      }
    }
  }
}

private struct LightningStrikeState {
  let seed: UInt64
  let intensity: Double
  let cloudCenter: UnitPoint
}

private struct LightningGeometry {
  let trunk: LightningStroke
  let branches: [LightningStroke]
}

private struct LightningStroke {
  let path: Path
  let segments: [LightningSegment]
}

private struct LightningSegment {
  let path: Path
  let widthScale: CGFloat
}

private struct SeededLightningRandom {
  private var state: UInt64

  init(seed: UInt64) {
    state = seed == 0 ? 0xA076_1D64_78BD_642F : seed
  }

  mutating func next() -> Double {
    state ^= state >> 12
    state ^= state << 25
    state ^= state >> 27
    let value = state &* 2_685_821_657_736_338_717
    return Double(value >> 11) / Double(1 << 53)
  }
}
