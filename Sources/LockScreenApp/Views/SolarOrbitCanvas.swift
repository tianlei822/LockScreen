import SwiftUI

enum SolarOrbitRenderPolicy {
  /// The two depth layers bracket the sun and must commit the same timeline frame together.
  static let rendersAsynchronously = false
}

enum SolarSatelliteDepth: Equatable {
  case behindPlanet
  case inFrontOfPlanet

  init(angle: Double) {
    self = sin(angle) > 0 ? .inFrontOfPlanet : .behindPlanet
  }
}

enum SolarEarthRotation {
  static func horizontalOffset(spin: Double, width: CGFloat) -> CGFloat {
    let fullTurn = 2 * Double.pi
    var wrappedSpin = spin.truncatingRemainder(dividingBy: fullTurn)
    if wrappedSpin < 0 { wrappedSpin += fullTurn }
    return -CGFloat(wrappedSpin / fullTurn) * width
  }
}

struct SolarOrbitCanvas: View {
  let time: TimeInterval
  let center: CGPoint
  let planetDepth: SolarOrbitDepth

  var body: some View {
    Canvas(
      opaque: false,
      rendersAsynchronously: SolarOrbitRenderPolicy.rendersAsynchronously
    ) { context, size in
      if planetDepth == .behindSun {
        drawNebula(context: context, size: size)
        drawStars(context: context, size: size)
        drawMeteors(context: context, size: size)
        drawOrbits(context: context, size: size)
        drawBelts(context: context, size: size)
      }
      drawPlanets(context: context, size: size, depth: planetDepth)
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

  private func drawPlanets(
    context: GraphicsContext,
    size: CGSize,
    depth: SolarOrbitDepth
  ) {
    let unit = min(size.width, size.height)
    let placements: [(planet: SolarPlanet, point: CGPoint)] = SolarPlanet.all.compactMap {
      planet in
      let angle = time * planet.speed + planet.phase
      guard SolarOrbitDepth(angle: angle) == depth else { return nil }
      return (planet, orbitPoint(radius: unit * planet.orbit, angle: angle))
    }
    .sorted { $0.point.y < $1.point.y }

    for (planet, point) in placements {
      let radius = max(4, unit * planet.radius * 1.35)
      let planetRect = CGRect(
        x: point.x - radius,
        y: point.y - radius,
        width: radius * 2,
        height: radius * 2
      )

      drawSatelliteOrbits(context: context, planet: planet, point: point, radius: radius)
      drawSatellites(
        context: context,
        planet: planet,
        point: point,
        radius: radius,
        depth: .behindPlanet
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
      let sunDistance = max(1, hypot(center.x - point.x, center.y - point.y))
      let towardSun = CGPoint(
        x: (center.x - point.x) / sunDistance, y: (center.y - point.y) / sunDistance
      )
      let orbitAngle = time * planet.speed + planet.phase
      if let image = SolarPlanetTextureRenderer.image(
        name: planet.name,
        spin: time * planet.spinSpeed * 0.18 + planet.phase,
        light: SIMD3(Double(towardSun.x), Double(towardSun.y), -sin(orbitAngle) * 0.7)
      ) {
        surface.draw(Image(decorative: image, scale: 1), in: planetRect)
      } else {
        drawSurfaceDetails(
          context: &surface, planet: planet, rect: planetRect,
          spin: time * planet.spinSpeed + planet.phase
        )
      }
      context.stroke(
        Path(ellipseIn: planetRect.insetBy(dx: 0.4, dy: 0.4)),
        with: .linearGradient(
          Gradient(colors: [.white.opacity(0.18), .clear, .clear]),
          startPoint: CGPoint(x: point.x + towardSun.x * radius, y: point.y + towardSun.y * radius),
          endPoint: CGPoint(x: point.x - towardSun.x * radius, y: point.y - towardSun.y * radius)
        ),
        lineWidth: max(0.35, radius * 0.02)
      )

      drawRings(context: context, planet: planet, point: point, radius: radius, front: true)
      drawSatellites(
        context: context,
        planet: planet,
        point: point,
        radius: radius,
        depth: .inFrontOfPlanet
      )

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
    halo.addFilter(.blur(radius: max(0.8, radius * 0.13)))
    halo.stroke(
      Path(ellipseIn: rect.insetBy(dx: -radius * 0.13, dy: -radius * 0.13)),
      with: .color(atmosphere.opacity(0.22)),
      lineWidth: max(0.6, radius * 0.07)
    )
    context.stroke(
      Path(ellipseIn: rect.insetBy(dx: -0.7, dy: -0.7)),
      with: .color(atmosphere.opacity(0.28)),
      lineWidth: max(0.4, radius * 0.025)
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
    let land = Color(red: 0.26, green: 0.53, blue: 0.22)
    let highland = Color(red: 0.55, green: 0.61, blue: 0.28)
    let coastline = Color(red: 0.66, green: 0.78, blue: 0.39)
    let rotationOffset = SolarEarthRotation.horizontalOffset(spin: spin, width: rect.width)

    func drawLand(_ path: Path, color: Color = land) {
      context.fill(path, with: .color(color))
      context.stroke(
        path,
        with: .color(coastline.opacity(0.62)),
        lineWidth: max(0.28, rect.width * 0.012)
      )
    }

    for wrap in -1...2 {
      let offset = rotationOffset + CGFloat(wrap) * rect.width

      var northAmerica = Path()
      northAmerica.move(to: point(in: rect, x: 0.08, y: 0.24, dx: offset))
      northAmerica.addCurve(
        to: point(in: rect, x: 0.39, y: 0.3, dx: offset),
        control1: point(in: rect, x: 0.16, y: 0.13, dx: offset),
        control2: point(in: rect, x: 0.34, y: 0.16, dx: offset)
      )
      northAmerica.addCurve(
        to: point(in: rect, x: 0.29, y: 0.5, dx: offset),
        control1: point(in: rect, x: 0.42, y: 0.36, dx: offset),
        control2: point(in: rect, x: 0.32, y: 0.42, dx: offset)
      )
      northAmerica.addCurve(
        to: point(in: rect, x: 0.08, y: 0.24, dx: offset),
        control1: point(in: rect, x: 0.18, y: 0.51, dx: offset),
        control2: point(in: rect, x: 0.09, y: 0.39, dx: offset)
      )
      drawLand(northAmerica)

      var southAmerica = Path()
      southAmerica.move(to: point(in: rect, x: 0.29, y: 0.46, dx: offset))
      southAmerica.addCurve(
        to: point(in: rect, x: 0.37, y: 0.69, dx: offset),
        control1: point(in: rect, x: 0.42, y: 0.5, dx: offset),
        control2: point(in: rect, x: 0.42, y: 0.58, dx: offset)
      )
      southAmerica.addCurve(
        to: point(in: rect, x: 0.28, y: 0.9, dx: offset),
        control1: point(in: rect, x: 0.34, y: 0.78, dx: offset),
        control2: point(in: rect, x: 0.3, y: 0.86, dx: offset)
      )
      southAmerica.addCurve(
        to: point(in: rect, x: 0.29, y: 0.46, dx: offset),
        control1: point(in: rect, x: 0.19, y: 0.73, dx: offset),
        control2: point(in: rect, x: 0.2, y: 0.55, dx: offset)
      )
      drawLand(southAmerica, color: Color(red: 0.22, green: 0.49, blue: 0.2))

      var eurasia = Path()
      eurasia.move(to: point(in: rect, x: 0.47, y: 0.27, dx: offset))
      eurasia.addCurve(
        to: point(in: rect, x: 0.94, y: 0.34, dx: offset),
        control1: point(in: rect, x: 0.63, y: 0.12, dx: offset),
        control2: point(in: rect, x: 0.88, y: 0.18, dx: offset)
      )
      eurasia.addCurve(
        to: point(in: rect, x: 0.67, y: 0.49, dx: offset),
        control1: point(in: rect, x: 0.88, y: 0.47, dx: offset),
        control2: point(in: rect, x: 0.76, y: 0.4, dx: offset)
      )
      eurasia.addCurve(
        to: point(in: rect, x: 0.47, y: 0.27, dx: offset),
        control1: point(in: rect, x: 0.58, y: 0.54, dx: offset),
        control2: point(in: rect, x: 0.43, y: 0.4, dx: offset)
      )
      drawLand(eurasia, color: highland)

      var africa = Path()
      africa.move(to: point(in: rect, x: 0.56, y: 0.43, dx: offset))
      africa.addCurve(
        to: point(in: rect, x: 0.75, y: 0.5, dx: offset),
        control1: point(in: rect, x: 0.66, y: 0.4, dx: offset),
        control2: point(in: rect, x: 0.74, y: 0.44, dx: offset)
      )
      africa.addCurve(
        to: point(in: rect, x: 0.62, y: 0.79, dx: offset),
        control1: point(in: rect, x: 0.74, y: 0.64, dx: offset),
        control2: point(in: rect, x: 0.68, y: 0.74, dx: offset)
      )
      africa.addCurve(
        to: point(in: rect, x: 0.56, y: 0.43, dx: offset),
        control1: point(in: rect, x: 0.52, y: 0.67, dx: offset),
        control2: point(in: rect, x: 0.48, y: 0.51, dx: offset)
      )
      drawLand(africa, color: Color(red: 0.61, green: 0.55, blue: 0.26))

      var australia = Path()
      australia.addRoundedRect(
        in: CGRect(
          x: rect.minX + rect.width * 0.78 + offset,
          y: rect.minY + rect.height * 0.66,
          width: rect.width * 0.17,
          height: rect.height * 0.12
        ),
        cornerSize: CGSize(width: rect.width * 0.05, height: rect.height * 0.04)
      )
      drawLand(australia, color: Color(red: 0.55, green: 0.49, blue: 0.23))

      context.fill(
        Path(
          ellipseIn: CGRect(
            x: rect.minX + rect.width * 0.43 + offset,
            y: rect.minY + rect.height * 0.11,
            width: rect.width * 0.12,
            height: rect.height * 0.13
          )
        ),
        with: .color(Color(red: 0.72, green: 0.82, blue: 0.7).opacity(0.92))
      )
    }

    let cloudOffset = SolarEarthRotation.horizontalOffset(spin: spin * 1.08, width: rect.width)
    for wrap in -1...2 {
      let offset = cloudOffset + CGFloat(wrap) * rect.width
      for (index, latitude) in [0.3, 0.53, 0.7].enumerated() {
        var cloud = Path()
        cloud.move(
          to: point(
            in: rect,
            x: 0.02 + CGFloat(index) * 0.13,
            y: CGFloat(latitude),
            dx: offset
          )
        )
        cloud.addCurve(
          to: point(
            in: rect,
            x: 0.56 + CGFloat(index) * 0.11,
            y: CGFloat(latitude) - 0.025,
            dx: offset
          ),
          control1: point(
            in: rect,
            x: 0.19 + CGFloat(index) * 0.12,
            y: CGFloat(latitude) - 0.07,
            dx: offset
          ),
          control2: point(
            in: rect,
            x: 0.4 + CGFloat(index) * 0.1,
            y: CGFloat(latitude) + 0.06,
            dx: offset
          )
        )
        context.stroke(
          cloud,
          with: .color(Color.white.opacity(index == 1 ? 0.5 : 0.38)),
          style: StrokeStyle(
            lineWidth: max(0.42, rect.width * (index == 1 ? 0.035 : 0.025)),
            lineCap: .round
          )
        )
      }
    }

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
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: rect.minX + rect.width * 0.17,
          y: rect.maxY - rect.height * 0.09,
          width: rect.width * 0.66,
          height: rect.height * 0.09
        )
      ),
      with: .color(Color.white.opacity(0.52))
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

    let layerCount = ring == .saturn ? 48 : 7
    let rotation = ring == .saturn ? -0.25 : 1.12
    let baseOpacity = ring == .saturn ? 0.66 : 0.28
    for index in 0..<layerCount {
      let fraction = CGFloat(index) / CGFloat(max(1, layerCount - 1))
      // Leave a dark division between Saturn's dense inner and outer ring bands.
      if ring == .saturn && fraction > 0.59 && fraction < 0.66 { continue }
      let horizontalRadius = radius * (1.24 + fraction * (ring == .saturn ? 1.02 : 0.66))
      let verticalRadius = horizontalRadius * 0.27
      let path = ellipseArcPath(
        center: point,
        horizontalRadius: horizontalRadius,
        verticalRadius: verticalRadius,
        rotation: rotation,
        startAngle: front ? 0 : .pi,
        endAngle: front ? .pi : 2 * .pi
      )
      let color =
        ring == .saturn
        ? Color(red: 0.92 - Double(fraction) * 0.14, green: 0.81, blue: 0.58)
        : Color(red: 0.62, green: 0.91, blue: 0.94)
      context.stroke(
        path,
        with: .color(
          color.opacity(
            (baseOpacity - Double(fraction) * 0.08)
              * (fraction < 0.2 ? 0.38 : 0.7 + 0.3 * abs(sin(Double(index) * 2.17)))
          )
        ),
        lineWidth: max(0.22, radius * (ring == .saturn ? 0.02 : 0.012))
      )
    }
  }

  private func drawSatelliteOrbits(
    context: GraphicsContext,
    planet: SolarPlanet,
    point: CGPoint,
    radius: CGFloat
  ) {
    for satellite in satellites(for: planet) {
      let orbitRadius = radius * satellite.orbitScale
      context.stroke(
        Path(
          ellipseIn: CGRect(
            x: point.x - orbitRadius,
            y: point.y - orbitRadius * satellite.verticalScale,
            width: orbitRadius * 2,
            height: orbitRadius * satellite.verticalScale * 2
          )
        ),
        with: .color(Color.white.opacity(0.075)),
        lineWidth: 0.38
      )
    }
  }

  private func drawSatellites(
    context: GraphicsContext,
    planet: SolarPlanet,
    point: CGPoint,
    radius: CGFloat,
    depth: SolarSatelliteDepth
  ) {
    for satellite in satellites(for: planet) {
      let angle = time * satellite.speed + satellite.phase
      guard SolarSatelliteDepth(angle: angle) == depth else { continue }

      let orbitRadius = radius * satellite.orbitScale
      let moon = CGPoint(
        x: point.x + cos(angle) * orbitRadius,
        y: point.y + sin(angle) * orbitRadius * satellite.verticalScale
      )
      let moonRadius = max(satellite.minimumRadius, radius * satellite.radiusScale)
      let moonRect = CGRect(
        x: moon.x - moonRadius,
        y: moon.y - moonRadius,
        width: moonRadius * 2,
        height: moonRadius * 2
      )
      let sunDistance = max(1, hypot(center.x - moon.x, center.y - moon.y))
      context.fill(
        Path(ellipseIn: moonRect),
        with: .radialGradient(
          Gradient(colors: [satellite.highlight, satellite.color, satellite.shadow]),
          center: CGPoint(
            x: moon.x + (center.x - moon.x) / sunDistance * moonRadius * 0.34,
            y: moon.y + (center.y - moon.y) / sunDistance * moonRadius * 0.34
          ),
          startRadius: 0,
          endRadius: moonRadius * 1.5
        )
      )
      context.stroke(
        Path(ellipseIn: moonRect.insetBy(dx: 0.15, dy: 0.15)),
        with: .color(Color.white.opacity(0.22)),
        lineWidth: 0.3
      )
    }
  }

  private func satellites(for planet: SolarPlanet) -> [SolarSatellite] {
    switch planet.name {
    case "Earth":
      return [
        SolarSatellite(
          orbitScale: 1.8,
          verticalScale: 0.3,
          speed: 0.34,
          phase: 0,
          radiusScale: 0.16,
          minimumRadius: 1.15,
          color: Color(red: 0.68, green: 0.69, blue: 0.68),
          highlight: Color(red: 0.95, green: 0.96, blue: 0.94),
          shadow: Color(red: 0.18, green: 0.19, blue: 0.2)
        )
      ]
    case "Mars":
      return [
        SolarSatellite(
          orbitScale: 1.5,
          verticalScale: 0.26,
          speed: 0.82,
          phase: 0.6,
          radiusScale: 0.07,
          minimumRadius: 0.62,
          color: Color(red: 0.55, green: 0.44, blue: 0.36),
          highlight: Color(red: 0.8, green: 0.7, blue: 0.59),
          shadow: Color(red: 0.2, green: 0.13, blue: 0.1)
        ),
        SolarSatellite(
          orbitScale: 1.95,
          verticalScale: 0.24,
          speed: 0.51,
          phase: 2.4,
          radiusScale: 0.06,
          minimumRadius: 0.55,
          color: Color(red: 0.49, green: 0.41, blue: 0.36),
          highlight: Color(red: 0.75, green: 0.67, blue: 0.59),
          shadow: Color(red: 0.17, green: 0.12, blue: 0.1)
        ),
      ]
    case "Jupiter":
      let colors = [
        Color(red: 0.86, green: 0.75, blue: 0.55),
        Color(red: 0.86, green: 0.7, blue: 0.42),
        Color(red: 0.66, green: 0.7, blue: 0.67),
        Color(red: 0.56, green: 0.48, blue: 0.39),
      ]
      return [1.45, 1.76, 2.08, 2.42].enumerated().map { index, orbitScale in
        SolarSatellite(
          orbitScale: CGFloat(orbitScale),
          verticalScale: 0.22,
          speed: 0.28 + Double(index) * 0.055,
          phase: Double(index) * 1.7,
          radiusScale: 0.062 + CGFloat(index) * 0.008,
          minimumRadius: 0.72,
          color: colors[index],
          highlight: colors[index].opacity(0.95),
          shadow: Color.black.opacity(0.82)
        )
      }
    case "Saturn":
      return [
        SolarSatellite(
          orbitScale: 2.5,
          verticalScale: 0.25,
          speed: 0.2,
          phase: 1.1,
          radiusScale: 0.1,
          minimumRadius: 0.82,
          color: Color(red: 0.72, green: 0.52, blue: 0.3),
          highlight: Color(red: 0.91, green: 0.72, blue: 0.48),
          shadow: Color(red: 0.25, green: 0.14, blue: 0.08)
        ),
        SolarSatellite(
          orbitScale: 2.05,
          verticalScale: 0.25,
          speed: 0.27,
          phase: 3.2,
          radiusScale: 0.062,
          minimumRadius: 0.58,
          color: Color(red: 0.72, green: 0.69, blue: 0.61),
          highlight: Color(red: 0.91, green: 0.88, blue: 0.79),
          shadow: Color(red: 0.25, green: 0.23, blue: 0.2)
        ),
      ]
    case "Uranus":
      return [
        SolarSatellite(
          orbitScale: 1.85,
          verticalScale: 0.34,
          speed: 0.24,
          phase: 2.1,
          radiusScale: 0.07,
          minimumRadius: 0.62,
          color: Color(red: 0.68, green: 0.72, blue: 0.72),
          highlight: Color(red: 0.9, green: 0.94, blue: 0.93),
          shadow: Color(red: 0.2, green: 0.24, blue: 0.25)
        )
      ]
    case "Neptune":
      return [
        SolarSatellite(
          orbitScale: 1.9,
          verticalScale: 0.29,
          speed: -0.22,
          phase: 0.8,
          radiusScale: 0.075,
          minimumRadius: 0.64,
          color: Color(red: 0.64, green: 0.67, blue: 0.65),
          highlight: Color(red: 0.9, green: 0.92, blue: 0.89),
          shadow: Color(red: 0.17, green: 0.2, blue: 0.2)
        )
      ]
    default:
      return []
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

enum SolarOrbitDepth: Equatable {
  case behindSun
  case inFrontOfSun

  init(angle: Double) {
    self = sin(angle) > 0 ? .inFrontOfSun : .behindSun
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
      name: "Earth", orbit: 0.25, speed: 0.1, phase: 2.7, radius: 0.015,
      color: Color(red: 0.08, green: 0.35, blue: 0.67),
      accent: Color(red: 0.3, green: 0.5, blue: 0.25),
      highlight: Color(red: 0.32, green: 0.67, blue: 0.96),
      shadow: Color(red: 0.018, green: 0.08, blue: 0.22),
      surface: .earth, spinSpeed: 0.32,
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

private struct SolarSatellite {
  let orbitScale: CGFloat
  let verticalScale: CGFloat
  let speed: Double
  let phase: Double
  let radiusScale: CGFloat
  let minimumRadius: CGFloat
  let color: Color
  let highlight: Color
  let shadow: Color
}

func detailHash(_ value: Double) -> CGFloat {
  CGFloat(abs(sin(value * 12.9898) * 43_758.5453).truncatingRemainder(dividingBy: 1))
}
