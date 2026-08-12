import SwiftUI

struct SolarSystemArtwork: View {
  let isActivated: Bool
  let onActivate: () -> Void
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  @State private var exitStartedAt: Date?

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let unit = min(size.width, size.height)
      let center = CGPoint(x: size.width * 0.5, y: size.height * 0.56)

      ZStack {
        TimelineView(
          .animation(minimumInterval: 1 / 30, paused: ritualAnimationsPaused)
        ) { timeline in
          let time = timeline.date.timeIntervalSinceReferenceDate
          let exitProgress = min(
            1,
            max(0, exitStartedAt.map { timeline.date.timeIntervalSince($0) / 1.35 } ?? 0)
          )

          ZStack {
            SolarOrbitCanvas(time: time, center: center)
              .opacity(max(0, 1 - exitProgress * 1.08))
              .scaleEffect(1 + exitProgress * 0.16, anchor: .center)
              .blur(radius: exitProgress * 13)

            SolarWarpExitCanvas(
              center: center,
              progress: exitProgress
            )

            SolarUnlockSun(
              diameter: unit * 0.14,
              time: time,
              exitProgress: exitProgress,
              onActivate: onActivate
            )
            .position(center)
          }
        }

        VStack {
          Spacer()
          HStack(spacing: 14) {
            Rectangle()
              .fill(Color.white.opacity(0.24))
              .frame(width: 44, height: 1)
            Text("DOUBLE-CLICK THE SUN TO UNLOCK")
              .font(.system(size: 10, weight: .medium, design: .monospaced))
              .tracking(2.8)
            Rectangle()
              .fill(Color.white.opacity(0.24))
              .frame(width: 44, height: 1)
          }
          .foregroundStyle(Color.white.opacity(0.68))
          .padding(.bottom, max(48, size.height * 0.07))
          .opacity(isActivated ? 0 : 1)
          .accessibilityHidden(true)
        }
      }
      .background(
        RadialGradient(
          colors: [
            Color(red: 0.055, green: 0.075, blue: 0.14),
            Color(red: 0.008, green: 0.014, blue: 0.038),
            .black,
          ],
          center: UnitPoint(x: 0.5, y: 0.56),
          startRadius: 0,
          endRadius: max(size.width, size.height) * 0.74
        )
      )
    }
    .onChange(of: isActivated) { _, activated in
      exitStartedAt = activated ? Date() : nil
    }
    .animation(.easeOut(duration: 0.28), value: isActivated)
  }
}

private struct SolarUnlockSun: View {
  let diameter: CGFloat
  let time: TimeInterval
  let exitProgress: Double
  let onActivate: () -> Void
  @State private var isHovering = false

  var body: some View {
    let pulse = 1 + sin(time * 1.7) * 0.025
    let contraction = min(1, exitProgress / 0.16) * 0.16
    let expansion = max(0, (exitProgress - 0.16) / 0.84)
    let exitScale = 1 - contraction + expansion * 2.35
    let exitOpacity = 1 - max(0, (exitProgress - 0.6) / 0.4)

    ZStack {
      Circle()
        .fill(Color.orange.opacity(0.22))
        .frame(width: diameter * 2.35, height: diameter * 2.35)
        .blur(radius: diameter * 0.34)

      Circle()
        .trim(from: 0.04, to: 0.82)
        .stroke(
          AngularGradient(
            colors: [.clear, Color.orange.opacity(0.58), .clear, Color.yellow.opacity(0.42)],
            center: .center
          ),
          style: StrokeStyle(lineWidth: max(1.2, diameter * 0.018), lineCap: .round)
        )
        .frame(width: diameter * 1.28, height: diameter * 1.28)
        .rotationEffect(.degrees(time * 4.2))
        .blur(radius: 1.2)

      Circle()
        .fill(
          RadialGradient(
            colors: [
              .white,
              Color(red: 1, green: 0.9, blue: 0.32),
              Color(red: 1, green: 0.47, blue: 0.07),
              Color(red: 0.72, green: 0.12, blue: 0.02),
            ],
            center: UnitPoint(x: 0.36, y: 0.32),
            startRadius: 0,
            endRadius: diameter * 0.62
          )
        )
        .overlay {
          SolarGranulationCanvas(time: time)
            .clipShape(Circle())
        }
        .overlay {
          Circle()
            .stroke(Color.white.opacity(isHovering ? 0.82 : 0.3), lineWidth: 1)
            .padding(-8)
        }
        .shadow(color: Color.orange.opacity(0.9), radius: isHovering ? 34 : 22)
        .frame(width: diameter, height: diameter)
    }
    .frame(width: diameter * 2, height: diameter * 2)
    .contentShape(Circle())
    .scaleEffect(exitProgress > 0 ? exitScale : pulse * (isHovering ? 1.06 : 1))
    .opacity(exitOpacity)
    .allowsHitTesting(exitProgress == 0)
    .onHover { isHovering = $0 }
    .onTapGesture(count: 2) {
      onActivate()
    }
    .accessibilityRepresentation {
      Button("Sun — double-click to unlock", action: onActivate)
    }
    .help("Double-click the sun to unlock")
  }
}

private struct SolarWarpExitCanvas: View {
  let center: CGPoint
  let progress: Double

  var body: some View {
    Canvas(opaque: false, rendersAsynchronously: true) { context, size in
      guard progress > 0 else { return }

      let unit = min(size.width, size.height)
      let visibility = sin(progress * .pi)
      let acceleration = pow(progress, 1.7)

      for index in 0..<72 {
        let seed = Double(index + 1_307)
        let angle = Double(detailHash(seed * 2.71)) * 2 * Double.pi
        let direction = CGVector(dx: cos(angle), dy: sin(angle))
        let baseDistance = unit * (0.06 + detailHash(seed * 4.9) * 0.38)
        let startDistance = baseDistance * (0.82 + progress * 0.32)
        let length =
          unit
          * (0.008 + acceleration * (0.045 + detailHash(seed * 7.3) * 0.12))
        let start = CGPoint(
          x: center.x + direction.dx * startDistance,
          y: center.y + direction.dy * startDistance
        )
        let end = CGPoint(
          x: start.x + direction.dx * length,
          y: start.y + direction.dy * length
        )

        var streak = Path()
        streak.move(to: start)
        streak.addLine(to: end)
        let warmth = index.isMultiple(of: 7)
        context.stroke(
          streak,
          with: .linearGradient(
            Gradient(colors: [
              Color.white.opacity(0.04),
              (warmth ? Color.orange : Color.cyan).opacity(visibility * 0.72),
              Color.white.opacity(visibility * 0.9),
            ]),
            startPoint: start,
            endPoint: end
          ),
          style: StrokeStyle(
            lineWidth: 0.35 + detailHash(seed * 11.2) * 1.15 + acceleration * 0.6,
            lineCap: .round
          )
        )
      }

      for ring in 0..<3 {
        let delayed = max(0, min(1, progress * 1.35 - Double(ring) * 0.16))
        let radius = unit * (0.04 + delayed * (0.34 + Double(ring) * 0.08))
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
            Color(red: 0.58, green: 0.82, blue: 1)
              .opacity((1 - delayed) * (0.42 - Double(ring) * 0.08))
          ),
          lineWidth: 0.7 + CGFloat(ring) * 0.35
        )
      }

      let flash = max(0, 1 - abs(progress - 0.38) / 0.28)
      var bloom = context
      bloom.addFilter(.blur(radius: unit * 0.025))
      let bloomRadius = unit * (0.06 + progress * 0.18)
      bloom.fill(
        Path(
          ellipseIn: CGRect(
            x: center.x - bloomRadius,
            y: center.y - bloomRadius,
            width: bloomRadius * 2,
            height: bloomRadius * 2
          )
        ),
        with: .radialGradient(
          Gradient(colors: [
            Color.white.opacity(flash * 0.8),
            Color.orange.opacity(flash * 0.28),
            .clear,
          ]),
          center: center,
          startRadius: 0,
          endRadius: bloomRadius
        )
      )
    }
    .accessibilityHidden(true)
  }
}

private struct SolarGranulationCanvas: View {
  let time: TimeInterval

  var body: some View {
    Canvas(opaque: false, rendersAsynchronously: true) { context, size in
      let radius = min(size.width, size.height) * 0.5
      let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)

      for index in 0..<58 {
        let seed = Double(index + 1)
        let angle = detailHash(seed * 4.13) * 2 * Double.pi + time * 0.018
        let distance = sqrt(detailHash(seed * 7.71)) * radius * 0.86
        let point = CGPoint(
          x: center.x + cos(angle) * distance,
          y: center.y + sin(angle) * distance
        )
        let width = radius * (0.045 + detailHash(seed * 11.9) * 0.1)
        let height = width * (0.4 + detailHash(seed * 2.3) * 0.45)
        let shimmer = 0.5 + 0.5 * sin(time * 0.8 + seed * 1.7)
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: point.x - width * 0.5,
              y: point.y - height * 0.5,
              width: width,
              height: height
            )
          ),
          with: .color(Color.yellow.opacity(0.08 + shimmer * 0.12))
        )
      }

      for index in 0..<3 {
        let drift = sin(time * 0.12 + Double(index) * 2.1) * radius * 0.08
        let spotRadius = radius * (0.05 + CGFloat(index) * 0.012)
        let point = CGPoint(
          x: center.x + radius * (-0.28 + CGFloat(index) * 0.29) + drift,
          y: center.y + radius * (index.isMultiple(of: 2) ? 0.18 : -0.23)
        )
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: point.x - spotRadius,
              y: point.y - spotRadius * 0.52,
              width: spotRadius * 2,
              height: spotRadius * 1.04
            )
          ),
          with: .color(Color(red: 0.35, green: 0.06, blue: 0.015).opacity(0.42))
        )
      }
    }
  }
}

private struct SolarOrbitCanvas: View {
  let time: TimeInterval
  let center: CGPoint

  var body: some View {
    Canvas(opaque: false, rendersAsynchronously: true) { context, size in
      drawNebula(context: context, size: size)
      drawStars(context: context, size: size)
      drawMeteors(context: context, size: size)
      drawOrbits(context: context, size: size)
      drawBelts(context: context, size: size)
      drawPlanets(context: context, size: size)
    }
  }

  private func drawNebula(context: GraphicsContext, size: CGSize) {
    var glow = context
    glow.addFilter(.blur(radius: 46))

    let unit = min(size.width, size.height)
    var galacticBand = Path()
    galacticBand.move(to: CGPoint(x: -unit * 0.14, y: size.height * 0.82))
    galacticBand.addCurve(
      to: CGPoint(x: size.width + unit * 0.16, y: size.height * 0.18),
      control1: CGPoint(x: size.width * 0.22, y: size.height * 0.56),
      control2: CGPoint(x: size.width * 0.72, y: size.height * 0.42)
    )
    glow.stroke(
      galacticBand,
      with: .linearGradient(
        Gradient(colors: [
          Color.blue.opacity(0),
          Color(red: 0.24, green: 0.34, blue: 0.68).opacity(0.08),
          Color.indigo.opacity(0.055),
          Color.blue.opacity(0),
        ]),
        startPoint: CGPoint(x: 0, y: size.height),
        endPoint: CGPoint(x: size.width, y: 0)
      ),
      style: StrokeStyle(lineWidth: unit * 0.16, lineCap: .round)
    )

    for index in 0..<3 {
      let seed = Double(index + 1)
      let drift = CGPoint(
        x: sin(time * 0.025 + seed) * size.width * 0.04,
        y: cos(time * 0.02 + seed * 2) * size.height * 0.035
      )
      let cloudCenter = CGPoint(
        x: size.width * (0.22 + CGFloat(index) * 0.29) + drift.x,
        y: size.height * (index.isMultiple(of: 2) ? 0.68 : 0.3) + drift.y
      )
      let radius = min(size.width, size.height) * (0.18 + CGFloat(index) * 0.025)
      glow.fill(
        Path(
          ellipseIn: CGRect(
            x: cloudCenter.x - radius,
            y: cloudCenter.y - radius * 0.48,
            width: radius * 2,
            height: radius * 0.96
          )
        ),
        with: .color(
          (index == 1 ? Color.indigo : Color.blue).opacity(index == 1 ? 0.08 : 0.055)
        )
      )
    }
  }

  private func drawStars(context: GraphicsContext, size: CGSize) {
    for index in 0..<260 {
      let seed = Double(index + 11)
      let x = hash(seed * 1.37) * size.width
      let y = hash(seed * 2.41) * size.height
      let twinkle =
        0.5
        + 0.5 * sin(time * (0.22 + Double(hash(seed)) * 0.42) + seed * 1.7)
      let radius = 0.24 + hash(seed * 4.7) * 0.56
      let alpha = 0.09 + twinkle * (0.08 + Double(hash(seed * 8.2)) * 0.18)
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: x - radius,
            y: y - radius,
            width: radius * 2,
            height: radius * 2
          )
        ),
        with: .color(Color.white.opacity(alpha))
      )
    }

    for index in 0..<72 {
      let seed = Double(index + 607)
      let drift = CGPoint(
        x: sin(time * 0.014 + seed) * 1.8,
        y: cos(time * 0.011 + seed * 0.7) * 1.2
      )
      let point = CGPoint(
        x: hash(seed * 1.83) * size.width + drift.x,
        y: hash(seed * 3.29) * size.height + drift.y
      )
      let wave =
        0.5
        + 0.5 * sin(time * (0.48 + Double(hash(seed * 5.3)) * 1.1) + seed * 2.1)
      let flare = pow(max(0, sin(time * 0.91 + seed * 4.37)), 8)
      let radius = 0.7 + hash(seed * 7.9) * 0.8
      let alpha = 0.2 + wave * 0.38 + flare * 0.3
      let color = starColor(index: index)

      var halo = context
      halo.addFilter(.blur(radius: 2.2 + radius))
      halo.fill(
        Path(
          ellipseIn: CGRect(
            x: point.x - radius * 2.2,
            y: point.y - radius * 2.2,
            width: radius * 4.4,
            height: radius * 4.4
          )
        ),
        with: .color(color.opacity(alpha * 0.2))
      )
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
          )
        ),
        with: .color(color.opacity(alpha))
      )
    }

    for index in 0..<18 {
      let seed = Double(index + 997)
      let point = CGPoint(
        x: hash(seed * 2.17) * size.width,
        y: hash(seed * 5.71) * size.height
      )
      let pulse = pow(
        0.5 + 0.5 * sin(time * (0.7 + Double(index % 4) * 0.16) + seed),
        2.4
      )
      let coreRadius = 0.85 + hash(seed * 3.8) * 0.65
      let ray = 2.8 + coreRadius * 2.6 + pulse * 4.5
      let color = starColor(index: index + 3)

      var bloom = context
      bloom.addFilter(.blur(radius: 4 + pulse * 3))
      bloom.fill(
        Path(
          ellipseIn: CGRect(
            x: point.x - ray * 0.7,
            y: point.y - ray * 0.7,
            width: ray * 1.4,
            height: ray * 1.4
          )
        ),
        with: .color(color.opacity(0.1 + pulse * 0.18))
      )

      var rays = Path()
      rays.move(to: CGPoint(x: point.x - ray, y: point.y))
      rays.addLine(to: CGPoint(x: point.x + ray, y: point.y))
      rays.move(to: CGPoint(x: point.x, y: point.y - ray * 0.72))
      rays.addLine(to: CGPoint(x: point.x, y: point.y + ray * 0.72))
      context.stroke(
        rays,
        with: .color(color.opacity(0.16 + pulse * 0.42)),
        style: StrokeStyle(lineWidth: 0.42, lineCap: .round)
      )
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: point.x - coreRadius,
            y: point.y - coreRadius,
            width: coreRadius * 2,
            height: coreRadius * 2
          )
        ),
        with: .color(Color.white.opacity(0.72 + pulse * 0.28))
      )
    }
  }

  private func starColor(index: Int) -> Color {
    switch index % 9 {
    case 0, 1:
      Color(red: 0.67, green: 0.8, blue: 1)
    case 2:
      Color(red: 1, green: 0.78, blue: 0.55)
    default:
      Color(red: 0.9, green: 0.94, blue: 1)
    }
  }

  private func drawMeteors(context: GraphicsContext, size: CGSize) {
    let unit = min(size.width, size.height)
    let channels: [(period: Double, duration: Double, offset: Double)] = [
      (9.8, 0.96, 2.1)
    ]

    for (channel, timing) in channels.enumerated() {
      let channelTime = time + timing.offset
      let elapsed = channelTime.truncatingRemainder(dividingBy: timing.period)
      guard elapsed < timing.duration else { continue }

      let progress = elapsed / timing.duration
      let easedProgress = 1 - pow(1 - progress, 2)
      let visibility = pow(sin(progress * .pi), 0.72)
      let cycle = floor(channelTime / timing.period)
      let seed = cycle * 97.3 + Double(channel) * 419.7 + 31
      let movesRight = detailHash(seed * 2.31) > 0.5
      let downwardAngle = Double.pi * (0.21 + detailHash(seed * 3.74) * 0.12)
      let angle = movesRight ? downwardAngle : Double.pi - downwardAngle
      let direction = CGVector(dx: cos(angle), dy: sin(angle))
      let start = CGPoint(
        x: size.width
          * ((movesRight ? 0.06 : 0.54) + detailHash(seed * 5.17) * 0.4),
        y: size.height * (0.03 + detailHash(seed * 8.43) * 0.2)
      )
      let travel = unit * (0.42 + detailHash(seed * 11.8) * 0.18)
      let head = CGPoint(
        x: start.x + direction.dx * travel * easedProgress,
        y: start.y + direction.dy * travel * easedProgress
      )
      let trailLength =
        unit * (0.12 + detailHash(seed * 14.2) * 0.08)
        * (0.64 + progress * 0.36)
      let tail = CGPoint(
        x: head.x - direction.dx * trailLength,
        y: head.y - direction.dy * trailLength
      )
      let tint =
        detailHash(seed * 19.4) > 0.72
        ? Color(red: 1, green: 0.78, blue: 0.52)
        : Color(red: 0.68, green: 0.86, blue: 1)

      var trail = Path()
      trail.move(to: tail)
      trail.addLine(to: head)

      var glow = context
      glow.addFilter(.blur(radius: 3.5))
      glow.stroke(
        trail,
        with: .linearGradient(
          Gradient(colors: [.clear, tint.opacity(visibility * 0.42)]),
          startPoint: tail,
          endPoint: head
        ),
        style: StrokeStyle(lineWidth: 3.4, lineCap: .round)
      )
      context.stroke(
        trail,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            tint.opacity(visibility * 0.54),
            Color.white.opacity(visibility * 0.96),
          ]),
          startPoint: tail,
          endPoint: head
        ),
        style: StrokeStyle(lineWidth: 1.05, lineCap: .round)
      )

      let headRadius = 1.1 + detailHash(seed * 17.6) * 0.75
      glow.fill(
        Path(
          ellipseIn: CGRect(
            x: head.x - headRadius * 2.2,
            y: head.y - headRadius * 2.2,
            width: headRadius * 4.4,
            height: headRadius * 4.4
          )
        ),
        with: .color(tint.opacity(visibility * 0.46))
      )
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: head.x - headRadius,
            y: head.y - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
          )
        ),
        with: .color(Color.white.opacity(visibility))
      )
    }
  }

  private func drawOrbits(context: GraphicsContext, size: CGSize) {
    let unit = min(size.width, size.height)

    for planet in SolarPlanet.all {
      var orbit = Path()
      for step in 0...120 {
        let point = orbitPoint(
          radius: unit * planet.orbit,
          angle: Double(step) / 120 * 2 * .pi
        )
        if step == 0 { orbit.move(to: point) } else { orbit.addLine(to: point) }
      }
      context.stroke(
        orbit,
        with: .color(Color(red: 0.55, green: 0.7, blue: 0.95).opacity(0.13)),
        style: StrokeStyle(lineWidth: 0.7, dash: [1.5, 5])
      )
    }
  }

  private func drawBelts(context: GraphicsContext, size: CGSize) {
    let unit = min(size.width, size.height)

    for index in 0..<170 {
      let seed = Double(index + 41)
      let angle = detailHash(seed * 1.91) * 2 * Double.pi + time * 0.008
      let radius = unit * (0.338 + detailHash(seed * 7.13) * 0.025)
      var point = orbitPoint(radius: radius, angle: angle)
      point.y += (detailHash(seed * 4.2) - 0.5) * unit * 0.012
      let diameter = 0.45 + detailHash(seed * 3.7) * 1.15
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: point.x - diameter * 0.5,
            y: point.y - diameter * 0.5,
            width: diameter,
            height: diameter
          )
        ),
        with: .color(
          Color(red: 0.68, green: 0.57, blue: 0.47)
            .opacity(0.18 + detailHash(seed * 5.8) * 0.34)
        )
      )
    }

    for index in 0..<110 {
      let seed = Double(index + 307)
      let angle = detailHash(seed * 1.37) * 2 * Double.pi - time * 0.003
      let radius = unit * (0.625 + detailHash(seed * 8.4) * 0.055)
      var point = orbitPoint(radius: radius, angle: angle)
      point.y += (detailHash(seed * 3.1) - 0.5) * unit * 0.018
      let diameter = 0.35 + detailHash(seed * 6.7) * 0.8
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: point.x - diameter * 0.5,
            y: point.y - diameter * 0.5,
            width: diameter,
            height: diameter
          )
        ),
        with: .color(Color(red: 0.58, green: 0.68, blue: 0.82).opacity(0.2))
      )
    }
  }

  private func drawPlanets(context: GraphicsContext, size: CGSize) {
    let unit = min(size.width, size.height)
    let placements = SolarPlanet.all.map { planet in
      let angle = time * planet.speed + planet.phase
      return (planet, orbitPoint(radius: unit * planet.orbit, angle: angle))
    }
    .sorted { $0.1.y < $1.1.y }

    for (planet, point) in placements {
      let radius = max(4, unit * planet.radius)
      let planetRect = CGRect(
        x: point.x - radius,
        y: point.y - radius,
        width: radius * 2,
        height: radius * 2
      )

      drawAtmosphere(context: context, planet: planet, rect: planetRect)
      drawRings(context: context, planet: planet, point: point, radius: radius, front: false)

      context.fill(
        Path(ellipseIn: planetRect),
        with: .radialGradient(
          Gradient(colors: [planet.highlight, planet.color, planet.shadow]),
          center: CGPoint(x: point.x - radius * 0.35, y: point.y - radius * 0.35),
          startRadius: 0,
          endRadius: radius * 1.6
        )
      )

      var surface = context
      surface.clip(to: Path(ellipseIn: planetRect))
      drawSurfaceDetails(
        context: &surface,
        planet: planet,
        rect: planetRect,
        spin: time * planet.spinSpeed + planet.phase
      )

      context.fill(
        Path(ellipseIn: planetRect),
        with: .linearGradient(
          Gradient(colors: [.white.opacity(0.22), .clear, .black.opacity(0.67)]),
          startPoint: CGPoint(x: planetRect.minX, y: planetRect.minY),
          endPoint: CGPoint(x: planetRect.maxX, y: planetRect.maxY)
        )
      )
      context.stroke(
        Path(ellipseIn: planetRect.insetBy(dx: 0.4, dy: 0.4)),
        with: .color(Color.white.opacity(0.22)),
        lineWidth: max(0.45, radius * 0.035)
      )
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: point.x - radius * 0.48,
            y: point.y - radius * 0.5,
            width: radius * 0.35,
            height: radius * 0.2
          )
        ),
        with: .color(Color.white.opacity(0.18))
      )

      drawRings(context: context, planet: planet, point: point, radius: radius, front: true)
      drawSatellites(context: context, planet: planet, point: point, radius: radius)

      let label = context.resolve(
        Text(planet.name.uppercased())
          .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
          .foregroundStyle(Color.white.opacity(0.56))
      )
      context.draw(label, at: CGPoint(x: point.x, y: point.y + radius + 11))
    }
  }

  private func drawAtmosphere(
    context: GraphicsContext,
    planet: SolarPlanet,
    rect: CGRect
  ) {
    guard let atmosphere = planet.atmosphere else { return }

    let radius = rect.width * 0.5
    var halo = context
    halo.addFilter(.blur(radius: max(1.5, radius * 0.42)))
    halo.stroke(
      Path(ellipseIn: rect.insetBy(dx: -radius * 0.13, dy: -radius * 0.13)),
      with: .color(atmosphere.opacity(0.48)),
      lineWidth: max(1, radius * 0.18)
    )
    context.stroke(
      Path(ellipseIn: rect.insetBy(dx: -0.7, dy: -0.7)),
      with: .color(atmosphere.opacity(0.52)),
      lineWidth: max(0.55, radius * 0.055)
    )
  }

  private func drawSurfaceDetails(
    context: inout GraphicsContext,
    planet: SolarPlanet,
    rect: CGRect,
    spin: Double
  ) {
    switch planet.surface {
    case .rocky:
      drawCraters(context: &context, rect: rect, tint: planet.shadow, count: 8, seed: 19)
    case .cloudy:
      drawBands(
        context: &context,
        rect: rect,
        colors: [planet.highlight.opacity(0.74), .white.opacity(0.32), planet.accent],
        count: 8,
        spin: spin,
        widthScale: 0.07
      )
    case .earth:
      drawEarth(context: &context, rect: rect, spin: spin)
    case .mars:
      drawMars(context: &context, rect: rect, spin: spin, planet: planet)
    case .gas:
      drawGasGiant(context: &context, rect: rect, spin: spin, planet: planet)
    case .ice:
      drawIceGiant(context: &context, rect: rect, spin: spin, planet: planet)
    }
  }

  private func drawBands(
    context: inout GraphicsContext,
    rect: CGRect,
    colors: [Color],
    count: Int,
    spin: Double,
    widthScale: CGFloat
  ) {
    for index in 0..<count {
      let progress = CGFloat(index + 1) / CGFloat(count + 1)
      let y = rect.minY + rect.height * progress
      let wave = sin(spin * 0.7 + Double(index) * 1.33) * Double(rect.height * 0.035)
      var band = Path()
      band.move(to: CGPoint(x: rect.minX - rect.width * 0.1, y: y + wave))
      band.addCurve(
        to: CGPoint(x: rect.midX, y: y - wave * 0.7),
        control1: CGPoint(x: rect.minX + rect.width * 0.18, y: y - wave),
        control2: CGPoint(x: rect.minX + rect.width * 0.36, y: y + wave * 0.65)
      )
      band.addCurve(
        to: CGPoint(x: rect.maxX + rect.width * 0.1, y: y + wave * 0.4),
        control1: CGPoint(x: rect.minX + rect.width * 0.68, y: y - wave * 0.9),
        control2: CGPoint(x: rect.minX + rect.width * 0.86, y: y + wave)
      )
      context.stroke(
        band,
        with: .color(colors[index % colors.count].opacity(index.isMultiple(of: 2) ? 0.7 : 0.46)),
        lineWidth: max(0.55, rect.height * widthScale * (index.isMultiple(of: 3) ? 1.35 : 0.78))
      )
    }
  }

  private func drawCraters(
    context: inout GraphicsContext,
    rect: CGRect,
    tint: Color,
    count: Int,
    seed: Double
  ) {
    for index in 0..<count {
      let value = Double(index) + seed
      let x = rect.minX + rect.width * (0.14 + detailHash(value * 3.17) * 0.72)
      let y = rect.minY + rect.height * (0.14 + detailHash(value * 6.73) * 0.72)
      let diameter = rect.width * (0.08 + detailHash(value * 9.41) * 0.16)
      let craterRect = CGRect(
        x: x - diameter * 0.5,
        y: y - diameter * 0.36,
        width: diameter,
        height: diameter * 0.72
      )
      context.fill(Path(ellipseIn: craterRect), with: .color(tint.opacity(0.36)))
      context.stroke(
        Path(ellipseIn: craterRect.offsetBy(dx: -diameter * 0.06, dy: -diameter * 0.05)),
        with: .color(Color.white.opacity(0.18)),
        lineWidth: max(0.35, rect.width * 0.018)
      )
    }
  }

  private func drawEarth(context: inout GraphicsContext, rect: CGRect, spin: Double) {
    let drift = CGFloat(sin(spin)) * rect.width * 0.09
    var americas = Path()
    americas.move(to: point(in: rect, x: 0.17, y: 0.2, dx: drift))
    americas.addCurve(
      to: point(in: rect, x: 0.34, y: 0.48, dx: drift),
      control1: point(in: rect, x: 0.36, y: 0.16, dx: drift),
      control2: point(in: rect, x: 0.4, y: 0.34, dx: drift)
    )
    americas.addCurve(
      to: point(in: rect, x: 0.28, y: 0.82, dx: drift),
      control1: point(in: rect, x: 0.24, y: 0.58, dx: drift),
      control2: point(in: rect, x: 0.4, y: 0.69, dx: drift)
    )
    americas.addCurve(
      to: point(in: rect, x: 0.17, y: 0.2, dx: drift),
      control1: point(in: rect, x: 0.13, y: 0.66, dx: drift),
      control2: point(in: rect, x: 0.08, y: 0.34, dx: drift)
    )
    context.fill(americas, with: .color(Color(red: 0.25, green: 0.5, blue: 0.22)))

    var oldWorld = Path()
    oldWorld.move(to: point(in: rect, x: 0.53, y: 0.23, dx: drift))
    oldWorld.addCurve(
      to: point(in: rect, x: 0.86, y: 0.4, dx: drift),
      control1: point(in: rect, x: 0.66, y: 0.1, dx: drift),
      control2: point(in: rect, x: 0.82, y: 0.22, dx: drift)
    )
    oldWorld.addCurve(
      to: point(in: rect, x: 0.62, y: 0.78, dx: drift),
      control1: point(in: rect, x: 0.74, y: 0.47, dx: drift),
      control2: point(in: rect, x: 0.76, y: 0.72, dx: drift)
    )
    oldWorld.addCurve(
      to: point(in: rect, x: 0.53, y: 0.23, dx: drift),
      control1: point(in: rect, x: 0.48, y: 0.68, dx: drift),
      control2: point(in: rect, x: 0.42, y: 0.36, dx: drift)
    )
    context.fill(oldWorld, with: .color(Color(red: 0.36, green: 0.57, blue: 0.24)))

    drawBands(
      context: &context,
      rect: rect,
      colors: [.white.opacity(0.48), Color.cyan.opacity(0.26)],
      count: 5,
      spin: spin * 1.3,
      widthScale: 0.025
    )
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: rect.minX + rect.width * 0.14,
          y: rect.minY - rect.height * 0.01,
          width: rect.width * 0.72,
          height: rect.height * 0.12
        )
      ),
      with: .color(Color.white.opacity(0.78))
    )
  }

  private func drawMars(
    context: inout GraphicsContext,
    rect: CGRect,
    spin: Double,
    planet: SolarPlanet
  ) {
    let drift = CGFloat(sin(spin)) * rect.width * 0.12
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: rect.minX + rect.width * 0.04 + drift,
          y: rect.minY + rect.height * 0.34,
          width: rect.width * 0.74,
          height: rect.height * 0.25
        )
      ),
      with: .color(planet.accent.opacity(0.62))
    )
    drawCraters(context: &context, rect: rect, tint: planet.shadow, count: 5, seed: 83)
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: rect.minX + rect.width * 0.2,
          y: rect.minY,
          width: rect.width * 0.6,
          height: rect.height * 0.13
        )
      ),
      with: .color(Color(red: 0.95, green: 0.84, blue: 0.72).opacity(0.82))
    )
  }

  private func drawGasGiant(
    context: inout GraphicsContext,
    rect: CGRect,
    spin: Double,
    planet: SolarPlanet
  ) {
    drawBands(
      context: &context,
      rect: rect,
      colors: [planet.accent, planet.highlight, .white.opacity(0.34), planet.shadow],
      count: planet.name == "Jupiter" ? 11 : 9,
      spin: spin,
      widthScale: planet.name == "Jupiter" ? 0.05 : 0.042
    )

    guard planet.name == "Jupiter" else { return }
    let spotX = rect.midX + CGFloat(sin(spin * 0.55)) * rect.width * 0.18
    let spotRect = CGRect(
      x: spotX - rect.width * 0.14,
      y: rect.minY + rect.height * 0.59,
      width: rect.width * 0.28,
      height: rect.height * 0.13
    )
    context.fill(
      Path(ellipseIn: spotRect),
      with: .radialGradient(
        Gradient(colors: [
          Color(red: 0.92, green: 0.47, blue: 0.33), Color(red: 0.46, green: 0.16, blue: 0.11),
        ]),
        center: CGPoint(x: spotRect.midX - spotRect.width * 0.18, y: spotRect.midY),
        startRadius: 0,
        endRadius: spotRect.width * 0.58
      )
    )
    context.stroke(
      Path(ellipseIn: spotRect.insetBy(dx: -0.5, dy: -0.35)),
      with: .color(Color.orange.opacity(0.44)),
      lineWidth: max(0.4, rect.width * 0.018)
    )
  }

  private func drawIceGiant(
    context: inout GraphicsContext,
    rect: CGRect,
    spin: Double,
    planet: SolarPlanet
  ) {
    drawBands(
      context: &context,
      rect: rect,
      colors: [planet.highlight.opacity(0.42), planet.accent.opacity(0.52)],
      count: 7,
      spin: spin,
      widthScale: 0.025
    )

    guard planet.name == "Neptune" else { return }
    let spotX = rect.midX + CGFloat(sin(spin * 0.7)) * rect.width * 0.18
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: spotX - rect.width * 0.13,
          y: rect.minY + rect.height * 0.47,
          width: rect.width * 0.26,
          height: rect.height * 0.13
        )
      ),
      with: .color(Color(red: 0.04, green: 0.08, blue: 0.29).opacity(0.72))
    )
    var cloud = Path()
    cloud.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.3))
    cloud.addCurve(
      to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY + rect.height * 0.24),
      control1: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.38),
      control2: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.16)
    )
    context.stroke(
      cloud,
      with: .color(Color.white.opacity(0.48)),
      style: StrokeStyle(lineWidth: max(0.55, rect.width * 0.045), lineCap: .round)
    )
  }

  private func drawRings(
    context: GraphicsContext,
    planet: SolarPlanet,
    point: CGPoint,
    radius: CGFloat,
    front: Bool
  ) {
    guard let ring = planet.ring else { return }

    let layerCount = ring == .saturn ? 4 : 2
    let rotation = ring == .saturn ? -0.25 : 1.12
    let baseOpacity = ring == .saturn ? 0.66 : 0.28
    for index in 0..<layerCount {
      let fraction = CGFloat(index) / CGFloat(max(1, layerCount - 1))
      let horizontalRadius = radius * (1.42 + fraction * (ring == .saturn ? 0.72 : 0.48))
      let verticalRadius = radius * (0.34 + fraction * 0.12)
      let path = ellipseArcPath(
        center: point,
        horizontalRadius: horizontalRadius,
        verticalRadius: verticalRadius,
        rotation: rotation,
        startAngle: front ? 0 : 0,
        endAngle: front ? .pi : 2 * .pi
      )
      let color =
        ring == .saturn
        ? Color(red: 0.92 - Double(fraction) * 0.14, green: 0.81, blue: 0.58)
        : Color(red: 0.62, green: 0.91, blue: 0.94)
      context.stroke(
        path,
        with: .color(color.opacity(baseOpacity - Double(fraction) * 0.08)),
        lineWidth: max(0.45, radius * (ring == .saturn ? 0.075 : 0.045))
      )
    }
  }

  private func drawSatellites(
    context: GraphicsContext,
    planet: SolarPlanet,
    point: CGPoint,
    radius: CGFloat
  ) {
    if planet.name == "Earth" {
      let orbitRadius = radius * 1.75
      context.stroke(
        Path(
          ellipseIn: CGRect(
            x: point.x - orbitRadius,
            y: point.y - orbitRadius * 0.28,
            width: orbitRadius * 2,
            height: orbitRadius * 0.56
          )
        ),
        with: .color(Color.white.opacity(0.13)),
        lineWidth: 0.45
      )
      let angle = time * 0.72
      let moon = CGPoint(
        x: point.x + cos(angle) * orbitRadius,
        y: point.y + sin(angle) * orbitRadius * 0.28
      )
      let moonRadius = max(1, radius * 0.12)
      context.fill(
        Path(
          ellipseIn: CGRect(
            x: moon.x - moonRadius,
            y: moon.y - moonRadius,
            width: moonRadius * 2,
            height: moonRadius * 2
          )
        ),
        with: .radialGradient(
          Gradient(colors: [.white, Color.gray]),
          center: CGPoint(x: moon.x - moonRadius * 0.3, y: moon.y - moonRadius * 0.3),
          startRadius: 0,
          endRadius: moonRadius * 1.5
        )
      )
    } else if planet.name == "Jupiter" {
      let orbitalRadii: [CGFloat] = [1.45, 1.76, 2.08, 2.42]
      for (index, orbitScale) in orbitalRadii.enumerated() {
        let angle = time * (0.42 + Double(index) * 0.09) + Double(index) * 1.7
        let moon = CGPoint(
          x: point.x + cos(angle) * radius * orbitScale,
          y: point.y + sin(angle) * radius * orbitScale * 0.22
        )
        let moonRadius = max(0.7, radius * (0.055 + CGFloat(index) * 0.008))
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: moon.x - moonRadius,
              y: moon.y - moonRadius,
              width: moonRadius * 2,
              height: moonRadius * 2
            )
          ),
          with: .color(
            (index.isMultiple(of: 2) ? Color.white : Color.orange).opacity(0.78)
          )
        )
      }
    }
  }

  private func ellipseArcPath(
    center: CGPoint,
    horizontalRadius: CGFloat,
    verticalRadius: CGFloat,
    rotation: Double,
    startAngle: Double,
    endAngle: Double
  ) -> Path {
    var path = Path()
    let steps = 80
    for step in 0...steps {
      let progress = Double(step) / Double(steps)
      let angle = startAngle + (endAngle - startAngle) * progress
      let flatX = cos(angle) * horizontalRadius
      let flatY = sin(angle) * verticalRadius
      let point = CGPoint(
        x: center.x + flatX * cos(rotation) - flatY * sin(rotation),
        y: center.y + flatX * sin(rotation) + flatY * cos(rotation)
      )
      if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    return path
  }

  private func point(in rect: CGRect, x: CGFloat, y: CGFloat, dx: CGFloat = 0) -> CGPoint {
    CGPoint(x: rect.minX + rect.width * x + dx, y: rect.minY + rect.height * y)
  }

  private func orbitPoint(radius: CGFloat, angle: Double) -> CGPoint {
    let x = cos(angle) * radius
    let y = sin(angle) * radius * 0.36
    let tilt = -0.11
    return CGPoint(
      x: center.x + x * cos(tilt) - y * sin(tilt),
      y: center.y + x * sin(tilt) + y * cos(tilt)
    )
  }

  private func hash(_ value: Double) -> CGFloat {
    CGFloat(abs(sin(value * 12.9898) * 43_758.5453).truncatingRemainder(dividingBy: 1))
  }
}

private struct SolarPlanet {
  let name: String
  let orbit: CGFloat
  let speed: Double
  let phase: Double
  let radius: CGFloat
  let color: Color
  let accent: Color
  let highlight: Color
  let shadow: Color
  let surface: SolarPlanetSurface
  let spinSpeed: Double
  let atmosphere: Color?
  let ring: SolarRingStyle?

  static let all = [
    SolarPlanet(
      name: "Mercury", orbit: 0.13, speed: 0.18, phase: 0.2, radius: 0.008,
      color: Color(red: 0.57, green: 0.54, blue: 0.51),
      accent: Color(red: 0.35, green: 0.32, blue: 0.3),
      highlight: Color(red: 0.77, green: 0.73, blue: 0.69),
      shadow: Color(red: 0.15, green: 0.13, blue: 0.12),
      surface: .rocky, spinSpeed: 0.24, atmosphere: nil, ring: nil),
    SolarPlanet(
      name: "Venus", orbit: 0.19, speed: 0.13, phase: 1.4, radius: 0.012,
      color: Color(red: 0.84, green: 0.64, blue: 0.36),
      accent: Color(red: 0.61, green: 0.4, blue: 0.24),
      highlight: Color(red: 0.96, green: 0.84, blue: 0.61),
      shadow: Color(red: 0.29, green: 0.14, blue: 0.06),
      surface: .cloudy, spinSpeed: -0.12,
      atmosphere: Color(red: 0.93, green: 0.64, blue: 0.31), ring: nil),
    SolarPlanet(
      name: "Earth", orbit: 0.25, speed: 0.1, phase: 2.7, radius: 0.013,
      color: Color(red: 0.08, green: 0.35, blue: 0.67),
      accent: Color(red: 0.3, green: 0.5, blue: 0.25),
      highlight: Color(red: 0.32, green: 0.67, blue: 0.96),
      shadow: Color(red: 0.018, green: 0.08, blue: 0.22),
      surface: .earth, spinSpeed: 1.35,
      atmosphere: Color(red: 0.2, green: 0.68, blue: 1), ring: nil),
    SolarPlanet(
      name: "Mars", orbit: 0.31, speed: 0.08, phase: 4.2, radius: 0.011,
      color: Color(red: 0.72, green: 0.29, blue: 0.16),
      accent: Color(red: 0.39, green: 0.12, blue: 0.08),
      highlight: Color(red: 0.92, green: 0.57, blue: 0.36),
      shadow: Color(red: 0.24, green: 0.045, blue: 0.022),
      surface: .mars, spinSpeed: 1.28,
      atmosphere: Color(red: 0.81, green: 0.36, blue: 0.2), ring: nil),
    SolarPlanet(
      name: "Jupiter", orbit: 0.38, speed: 0.052, phase: 5.3, radius: 0.025,
      color: Color(red: 0.72, green: 0.55, blue: 0.42),
      accent: Color(red: 0.46, green: 0.28, blue: 0.22),
      highlight: Color(red: 0.91, green: 0.78, blue: 0.61),
      shadow: Color(red: 0.21, green: 0.09, blue: 0.055),
      surface: .gas, spinSpeed: 2.1, atmosphere: nil, ring: nil),
    SolarPlanet(
      name: "Saturn", orbit: 0.45, speed: 0.041, phase: 0.9, radius: 0.021,
      color: Color(red: 0.82, green: 0.7, blue: 0.46),
      accent: Color(red: 0.57, green: 0.45, blue: 0.28),
      highlight: Color(red: 0.95, green: 0.86, blue: 0.67),
      shadow: Color(red: 0.22, green: 0.14, blue: 0.055),
      surface: .gas, spinSpeed: 1.86, atmosphere: nil, ring: .saturn),
    SolarPlanet(
      name: "Uranus", orbit: 0.52, speed: 0.03, phase: 2.1, radius: 0.016,
      color: Color(red: 0.44, green: 0.76, blue: 0.8),
      accent: Color(red: 0.2, green: 0.49, blue: 0.56),
      highlight: Color(red: 0.73, green: 0.93, blue: 0.94),
      shadow: Color(red: 0.045, green: 0.17, blue: 0.21),
      surface: .ice, spinSpeed: -0.82,
      atmosphere: Color(red: 0.39, green: 0.84, blue: 0.89), ring: .uranus),
    SolarPlanet(
      name: "Neptune", orbit: 0.59, speed: 0.024, phase: 3.5, radius: 0.016,
      color: Color(red: 0.13, green: 0.33, blue: 0.74),
      accent: Color(red: 0.08, green: 0.16, blue: 0.45),
      highlight: Color(red: 0.42, green: 0.65, blue: 0.94),
      shadow: Color(red: 0.018, green: 0.045, blue: 0.22),
      surface: .ice, spinSpeed: 0.72,
      atmosphere: Color(red: 0.18, green: 0.43, blue: 0.88), ring: nil),
  ]
}

private enum SolarPlanetSurface {
  case rocky
  case cloudy
  case earth
  case mars
  case gas
  case ice
}

private enum SolarRingStyle {
  case saturn
  case uranus
}

private func detailHash(_ value: Double) -> CGFloat {
  CGFloat(abs(sin(value * 12.9898) * 43_758.5453).truncatingRemainder(dividingBy: 1))
}
