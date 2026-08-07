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

  private let cycleDuration = 2.65

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let strike = strikeState(at: time)
      let intensity = strike.intensity * (isActivated ? 1.22 : 0.72 + energy * 0.38)

      ZStack {
        if presentation == .backdrop {
          cloudBank(size: size, strike: strike, intensity: intensity)
        }

        Canvas { context, canvasSize in
          guard intensity > 0.004 else { return }
          var random = SeededLightningRandom(seed: strike.seed)
          let boltCount = presentation == .backdrop ? 2 : 1

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
    let strikeTime = 0.3 + random.next() * 1.25
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

      Canvas { context, canvasSize in
        var random = SeededLightningRandom(seed: strike.seed &+ 0x9E37_79B9)
        var clouds = context
        clouds.addFilter(.blur(radius: 28))

        for _ in 0..<9 {
          let width = canvasSize.width * (0.12 + random.next() * 0.2)
          let height = canvasSize.height * (0.06 + random.next() * 0.12)
          let x = canvasSize.width * (-0.04 + random.next() * 1.08)
          let y = canvasSize.height * (-0.04 + random.next() * 0.44)
          let rect = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
          clouds.fill(
            Path(ellipseIn: rect),
            with: .color(style.primary.opacity(0.018 + intensity * 0.065))
          )
        }
      }
    }
    .blendMode(.plusLighter)
  }

  private func lightningGeometry(
    in size: CGSize,
    random: inout SeededLightningRandom,
    isDistant: Bool
  ) -> LightningGeometry {
    let origin = CGPoint(
      x: size.width * (0.08 + random.next() * 0.84),
      y: -size.height * (0.02 + random.next() * 0.08)
    )
    let target = CGPoint(
      x: size.width * (0.12 + random.next() * 0.76),
      y: size.height * (isDistant ? 0.34 + random.next() * 0.38 : 0.78 + random.next() * 0.25)
    )
    let stepCount = (isDistant ? 9 : 14) + Int(random.next() * (isDistant ? 5 : 7))
    var points = [origin]

    for step in 1..<stepCount {
      let fraction = CGFloat(step) / CGFloat(stepCount)
      let envelope = 0.35 + sin(Double(fraction) * .pi) * 0.65
      let baseX = origin.x + (target.x - origin.x) * fraction
      let jitter = (random.next() - 0.5) * Double(size.width) * 0.12 * envelope
      points.append(
        CGPoint(
          x: baseX + jitter,
          y: origin.y + (target.y - origin.y) * fraction
        ))
    }
    points.append(target)

    let trunk = lightningStroke(connecting: points, endScale: isDistant ? 0.34 : 0.48)
    let branchCount = (isDistant ? 1 : 4) + Int(random.next() * (isDistant ? 3 : 5))
    var branches: [LightningStroke] = []

    for _ in 0..<branchCount {
      let startIndex = 2 + Int(random.next() * Double(max(1, points.count - 5)))
      let start = points[min(startIndex, points.count - 3)]
      let direction = random.next() > 0.5 ? 1.0 : -1.0
      let branchSteps = 3 + Int(random.next() * 5)
      let horizontalReach = size.width * (0.04 + random.next() * 0.14) * direction
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
        with: .color(style.secondary.opacity(intensity * 0.46)),
        style: StrokeStyle(lineWidth: isDistant ? 2 : 5 + energy * 3, lineCap: .round)
      )

      let branchBaseWidth = isDistant ? 0.5 : 0.9 + energy * 0.8
      for segment in branch.segments {
        context.stroke(
          segment.path,
          with: .color(style.flare.opacity(intensity * (isDistant ? 0.42 : 0.82))),
          style: StrokeStyle(
            lineWidth: branchBaseWidth * segment.widthScale,
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
