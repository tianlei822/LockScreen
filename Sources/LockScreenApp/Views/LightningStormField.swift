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

        Canvas(rendersAsynchronously: true) { context, canvasSize in
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

      Canvas(rendersAsynchronously: true) { context, canvasSize in
        let cloudSeed = UInt64(bitPattern: Int64(seedOffset &* 104_729)) &+ 0x9E37_79B9
        var random = SeededLightningRandom(seed: cloudSeed)
        typealias CloudProfile = (
          orbitX: CGFloat,
          orbitY: CGFloat,
          width: CGFloat,
          height: CGFloat,
          variant: Int
        )
        let profiles: [CloudProfile] = [
          (0.4, 0.34, 0.28, 0.105, 0),
          (0.43, 0.39, 0.12, 0.052, 1),
          (0.38, 0.36, 0.21, 0.072, 2),
          (0.44, 0.32, 0.15, 0.086, 1),
          (0.39, 0.4, 0.245, 0.082, 2),
          (0.45, 0.35, 0.105, 0.045, 0),
          (0.37, 0.38, 0.225, 0.098, 1),
          (0.42, 0.33, 0.14, 0.058, 2),
        ]
        for (index, profile) in profiles.enumerated() {
          let baseAngle =
            Double(index) / Double(profiles.count) * 2 * Double.pi + random.next() * 0.32
          let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
          let angle = baseAngle + time * (0.018 + random.next() * 0.012) * direction
          let drift = sin(time * (0.18 + Double(index) * 0.015) + Double(index))
          let center = CGPoint(
            x: canvasSize.width * 0.5 + cos(angle) * canvasSize.width * profile.orbitX,
            y: canvasSize.height * 0.5 + sin(angle) * canvasSize.height * profile.orbitY
              + drift * canvasSize.height * 0.012
          )
          let width = canvasSize.width * profile.width
          let height = canvasSize.height * profile.height
          let flicker = pow(
            0.5 + 0.5 * sin(time * (2.25 + Double(index) * 0.31) + Double(index) * 1.7),
            6
          )
          let dischargeWave =
            index.isMultiple(of: 3)
            ? pow(
              0.5
                + 0.5
                * sin(time * (3.15 + Double(index) * 0.18) - Double(index) * 1.23),
              7
            )
            : 0
          let dischargeIntensity = min(1, intensity * 0.92 + dischargeWave * 0.68)
          let cloudCharge = min(1, flicker + dischargeIntensity * 0.82)
          let path = thunderCloudPath(
            center: center,
            width: width,
            height: height,
            variant: profile.variant
          )
          let shadowPath = thunderCloudPath(
            center: CGPoint(x: center.x, y: center.y + height * 0.14),
            width: width * 0.94,
            height: height * 0.88,
            variant: profile.variant
          )
          var haze = context
          haze.addFilter(.blur(radius: 12))
          haze.fill(
            path,
            with: .color(
              style.primary.opacity(0.085 + intensity * 0.12 + cloudCharge * 0.18)
            )
          )
          context.fill(
            shadowPath,
            with: .color(
              Color(red: 0.025, green: 0.03, blue: 0.075).opacity(
                0.38 + cloudCharge * 0.14
              )
            )
          )
          context.fill(
            path,
            with: .linearGradient(
              Gradient(colors: [
                style.secondary.opacity(0.09 + cloudCharge * 0.16),
                Color(red: 0.07, green: 0.075, blue: 0.15)
                  .opacity(0.38 + cloudCharge * 0.16),
                Color(red: 0.025, green: 0.03, blue: 0.08)
                  .opacity(0.5 + cloudCharge * 0.1),
              ]),
              startPoint: CGPoint(x: center.x, y: center.y - height * 0.54),
              endPoint: CGPoint(x: center.x, y: center.y + height * 0.34)
            )
          )
          context.stroke(
            thunderCloudRimPath(
              center: center,
              width: width,
              height: height,
              variant: profile.variant
            ),
            with: .color(
              style.secondary.opacity(0.13 + intensity * 0.16 + cloudCharge * 0.44)
            ),
            lineWidth: 0.85 + cloudCharge * 1.65
          )
          context.stroke(
            thunderCloudUndersidePath(
              center: center,
              width: width,
              height: height,
              variant: profile.variant
            ),
            with: .color(
              style.primary.opacity(0.11 + intensity * 0.18 + cloudCharge * 0.48)
            ),
            style: StrokeStyle(
              lineWidth: 0.9 + cloudCharge * 1.85,
              lineCap: .round,
              lineJoin: .round
            )
          )

          if index.isMultiple(of: 3) {
            if dischargeIntensity > 0.12 {
              let start = CGPoint(
                x: center.x + width * (index.isMultiple(of: 2) ? 0.08 : -0.1),
                y: center.y + height * 0.24
              )
              let dischargeSeed =
                strike.seed
                &+ UInt64(index + 1) &* 0x9E37_79B9_7F4A_7C15
              var dischargeRandom = SeededLightningRandom(seed: dischargeSeed)
              let horizontalShift =
                CGFloat(dischargeRandom.next() - 0.5) * canvasSize.width * 0.66
              let landingX = min(
                max(start.x + horizontalShift, canvasSize.width * 0.045),
                canvasSize.width * 0.955
              )
              let target = CGPoint(
                x: landingX,
                y: canvasSize.height * CGFloat(0.94 + dischargeRandom.next() * 0.14)
              )
              let discharge = cloudDischargeGeometry(
                from: start,
                to: target,
                seed: dischargeSeed ^ 0xD1B5_4A32_D192_ED03
              )
              draw(
                discharge,
                in: &context,
                intensity: dischargeIntensity,
                isDistant: false
              )
            }
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

  private func thunderCloudPath(
    center: CGPoint,
    width: CGFloat,
    height: CGFloat,
    variant: Int
  ) -> Path {
    var path = Path()

    switch variant % 3 {
    case 1:
      path.addEllipse(
        in: CGRect(
          x: center.x - width * 0.48,
          y: center.y - height * 0.02,
          width: width * 0.96,
          height: height * 0.52
        ))
      path.addEllipse(
        in: CGRect(
          x: center.x - width * 0.34,
          y: center.y - height * 0.5,
          width: width * 0.38,
          height: height * 0.92
        ))
      path.addEllipse(
        in: CGRect(
          x: center.x - width * 0.08,
          y: center.y - height * 0.7,
          width: width * 0.36,
          height: height * 1.15
        ))
      path.addEllipse(
        in: CGRect(
          x: center.x + width * 0.2,
          y: center.y - height * 0.28,
          width: width * 0.28,
          height: height * 0.68
        ))
    case 2:
      path.addEllipse(
        in: CGRect(
          x: center.x - width * 0.54,
          y: center.y,
          width: width * 1.08,
          height: height * 0.48
        ))
      path.addEllipse(
        in: CGRect(
          x: center.x - width * 0.46,
          y: center.y - height * 0.34,
          width: width * 0.36,
          height: height * 0.72
        ))
      path.addEllipse(
        in: CGRect(
          x: center.x - width * 0.16,
          y: center.y - height * 0.48,
          width: width * 0.5,
          height: height * 0.86
        ))
      path.addEllipse(
        in: CGRect(
          x: center.x + width * 0.2,
          y: center.y - height * 0.2,
          width: width * 0.34,
          height: height * 0.56
        ))
    default:
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
    }
    return path
  }

  private func thunderCloudRimPath(
    center: CGPoint,
    width: CGFloat,
    height: CGFloat,
    variant: Int
  ) -> Path {
    let crownLift: CGFloat = variant % 3 == 1 ? 0.46 : variant % 3 == 2 ? 0.24 : 0.3
    let skew: CGFloat = variant % 3 == 2 ? 0.07 : variant % 3 == 1 ? -0.035 : 0
    var path = Path()
    path.move(to: CGPoint(x: center.x - width * 0.46, y: center.y + height * 0.08))
    path.addCurve(
      to: CGPoint(x: center.x - width * 0.18, y: center.y - height * 0.18),
      control1: CGPoint(x: center.x - width * 0.42, y: center.y - height * 0.12),
      control2: CGPoint(x: center.x - width * 0.3, y: center.y - height * 0.28)
    )
    path.addCurve(
      to: CGPoint(
        x: center.x + width * (0.12 + skew),
        y: center.y - height * crownLift
      ),
      control1: CGPoint(
        x: center.x - width * (0.08 - skew),
        y: center.y - height * (crownLift + 0.2)
      ),
      control2: CGPoint(
        x: center.x + width * (0.06 + skew),
        y: center.y - height * (crownLift + 0.22)
      )
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
    height: CGFloat,
    variant: Int
  ) -> Path {
    let slant: CGFloat = variant % 3 == 2 ? 0.05 : variant % 3 == 1 ? -0.035 : 0
    return Path { path in
      path.move(
        to: CGPoint(
          x: center.x - width * (0.46 - slant),
          y: center.y + height * 0.16
        ))
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
        to: CGPoint(
          x: center.x + width * (0.46 + slant),
          y: center.y + height * 0.13
        ),
        control1: CGPoint(x: center.x + width * 0.28, y: center.y + height * 0.28),
        control2: CGPoint(x: center.x + width * 0.38, y: center.y + height * 0.22)
      )
    }
  }

  private func cloudDischargeGeometry(
    from start: CGPoint,
    to target: CGPoint,
    seed: UInt64
  ) -> LightningGeometry {
    var random = SeededLightningRandom(seed: seed)
    let deltaX = target.x - start.x
    let deltaY = target.y - start.y
    let distance = max(1, hypot(deltaX, deltaY))
    let tangent = CGPoint(x: deltaX / distance, y: deltaY / distance)
    let normal = CGPoint(x: -deltaY / distance, y: deltaX / distance)
    let stepCount = 11 + Int(random.next() * 6)
    var points = [start]

    for step in 1..<stepCount {
      let progress = CGFloat(step) / CGFloat(stepCount)
      let envelope = 0.42 + sin(progress * .pi) * 0.58
      let jitter = CGFloat(random.next() - 0.5) * min(distance * 0.13, 54) * envelope
      points.append(
        CGPoint(
          x: start.x + deltaX * progress + normal.x * jitter,
          y: start.y + deltaY * progress + normal.y * jitter
        )
      )
    }
    points.append(target)

    let trunk = lightningStroke(connecting: points, endScale: 0.38)
    let branchCount = 1 + Int(random.next() * 3)
    var branches: [LightningStroke] = []

    for branchIndex in 0..<branchCount {
      let availableStartCount = max(1, points.count - 6)
      let startIndex = 3 + Int(random.next() * Double(availableStartCount))
      let branchStart = points[min(startIndex, points.count - 3)]
      let side: CGFloat =
        (branchIndex.isMultiple(of: 2) ? 1 : -1)
        * (random.next() > 0.5 ? 1 : -1)
      let branchSteps = 3 + Int(random.next() * 4)
      let lateralReach = distance * CGFloat(0.08 + random.next() * 0.13) * side
      let downwardReach = distance * CGFloat(0.05 + random.next() * 0.12)
      var branchPoints = [branchStart]

      for step in 1...branchSteps {
        let progress = CGFloat(step) / CGFloat(branchSteps)
        let jitter = CGFloat(random.next() - 0.5) * distance * 0.025
        branchPoints.append(
          CGPoint(
            x: branchStart.x + normal.x * lateralReach * progress
              + tangent.x * downwardReach * progress + normal.x * jitter,
            y: branchStart.y + normal.y * lateralReach * progress
              + tangent.y * downwardReach * progress + normal.y * jitter
          )
        )
      }
      branches.append(lightningStroke(connecting: branchPoints, endScale: 0.16))
    }

    return LightningGeometry(trunk: trunk, branches: branches)
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
