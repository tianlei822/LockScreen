import LockScreenCore
import SwiftUI

struct FivePhaseOuterOrbitField: View {
  let element: FivePhaseElement
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)

      for ring in 0..<4 {
        let radius = unit * (0.365 + CGFloat(ring) * 0.043)
        let segmentCount = 8 + ring * 3
        for segment in 0..<segmentCount {
          let phase = time * (ring.isMultiple(of: 2) ? 0.18 : -0.14)
          let start = Double(segment) * 2 * .pi / Double(segmentCount) + phase
          let span = 2 * .pi / Double(segmentCount) * (0.48 + Double((segment + ring) % 3) * 0.12)
          let wave = 0.5 + 0.5 * sin(time * 2.05 - Double(segment) * 0.63 + Double(ring))
          var arc = Path()
          arc.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(start),
            endAngle: .radians(start + span),
            clockwise: false
          )
          context.stroke(
            arc,
            with: .color(
              (ring.isMultiple(of: 2) ? element.color : Color.white)
                .opacity(0.08 + wave * 0.13 + energy * 0.09)
            ),
            style: StrokeStyle(
              lineWidth: 0.45 + CGFloat(ring) * 0.22 + wave * 0.9,
              lineCap: .round
            )
          )
        }
      }

      for node in 0..<24 {
        let angle = Double(node) * 2 * .pi / 24 - time * 0.11
        let radius = unit * (node.isMultiple(of: 3) ? 0.49 : 0.462)
        let pulse = 0.5 + 0.5 * sin(time * 2.8 + Double(node) * 1.13)
        let point = CGPoint(
          x: center.x + cos(angle) * radius,
          y: center.y + sin(angle) * radius
        )
        let nodeRadius = CGFloat(0.9 + pulse * (node.isMultiple(of: 3) ? 2.4 : 1.1))
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: point.x - nodeRadius,
              y: point.y - nodeRadius,
              width: nodeRadius * 2,
              height: nodeRadius * 2
            )
          ),
          with: .color(
            (node.isMultiple(of: 4) ? Color.white : element.color)
              .opacity(0.2 + pulse * 0.46 + energy * 0.12)
          )
        )
      }
    }
    .frame(width: diameter, height: diameter)
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }
}

struct FivePhaseElementCore: View {
  let element: FivePhaseElement
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double

  var body: some View {
    let beat = 0.5 + 0.5 * sin(time * 2.6 + Double(element.rawValue))
    let coreSize = diameter * 0.118

    ZStack {
      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color.white.opacity(0.18 + beat * 0.12),
              element.color.opacity(0.46 + energy * 0.2),
              Color.black.opacity(0.76),
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: coreSize * 0.62
          )
        )

      Circle()
        .stroke(
          AngularGradient(
            colors: [element.color, .white, element.color.opacity(0.32), element.color],
            center: .center
          ),
          style: StrokeStyle(lineWidth: 1.3 + beat * 1.2 + energy)
        )
        .rotationEffect(.degrees(time * 24))

      FivePhaseCoreTexture(
        element: element,
        time: time,
        energy: energy
      )
      .frame(width: coreSize * 0.82, height: coreSize * 0.82)

      coreMotif(size: coreSize)
        .foregroundStyle(
          LinearGradient(
            colors: [.white, element.color, element.color.opacity(0.72)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .shadow(color: element.color.opacity(0.9), radius: 5 + energy * 7)
    }
    .frame(width: coreSize, height: coreSize)
    .scaleEffect(0.96 + beat * 0.08 + energy * 0.035)
    .shadow(color: element.color.opacity(0.62), radius: 12 + beat * 7 + energy * 10)
    .allowsHitTesting(false)
  }

  @ViewBuilder
  private func coreMotif(size: CGFloat) -> some View {
    switch element {
    case .wood:
      Image(systemName: "leaf.fill")
        .font(.system(size: size * 0.48, weight: .bold))
        .rotationEffect(.degrees(-18 + sin(time * 1.4) * 5))
    case .fire:
      Image(systemName: "flame.fill")
        .font(.system(size: size * 0.54, weight: .black))
        .scaleEffect(x: 0.94 + sin(time * 3.1) * 0.06, y: 1.04 + sin(time * 3.8) * 0.08)
    case .earth:
      Image(systemName: "mountain.2.fill")
        .font(.system(size: size * 0.48, weight: .bold))
    case .metal:
      SpiritSwordGlyph(color: element.color, energy: energy)
        .frame(width: size * 0.28, height: size * 0.64)
        .rotationEffect(.degrees(sin(time * 1.7) * 3))
    case .water:
      Image(systemName: "drop.fill")
        .font(.system(size: size * 0.52, weight: .bold))
        .offset(y: sin(time * 1.8) * size * 0.035)
    }
  }
}

/// Fine material engraving inside the elemental core. Keeping the five
/// variants in one small Canvas adds depth without expanding the SwiftUI view
/// hierarchy that must be rebuilt when the active phase changes.
struct FivePhaseCoreTexture: View {
  let element: FivePhaseElement
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let pale = Color.white.opacity(0.16 + energy * 0.12)
      let tint = element.color.opacity(0.24 + energy * 0.12)

      switch element {
      case .wood:
        var veins = Path()
        veins.move(to: CGPoint(x: center.x, y: size.height * 0.16))
        veins.addCurve(
          to: CGPoint(x: center.x, y: size.height * 0.84),
          control1: CGPoint(x: size.width * 0.4, y: size.height * 0.38),
          control2: CGPoint(x: size.width * 0.6, y: size.height * 0.62)
        )
        for index in 0..<4 {
          let y = size.height * (0.32 + CGFloat(index) * 0.11)
          let direction: CGFloat = index.isMultiple(of: 2) ? -1 : 1
          veins.move(to: CGPoint(x: center.x, y: y))
          veins.addLine(
            to: CGPoint(
              x: center.x + direction * unit * (0.16 + CGFloat(index % 2) * 0.04),
              y: y - unit * 0.11
            )
          )
        }
        context.stroke(
          veins, with: .color(tint),
          style: StrokeStyle(lineWidth: 0.7, lineCap: .round, lineJoin: .round)
        )

      case .fire:
        for index in 0..<3 {
          let phase = time * (0.34 + Double(index) * 0.05) + Double(index) * 1.8
          var emberArc = Path()
          emberArc.addArc(
            center: center,
            radius: unit * (0.18 + CGFloat(index) * 0.09),
            startAngle: .radians(phase),
            endAngle: .radians(phase + 1.1 + Double(index) * 0.18),
            clockwise: false
          )
          context.stroke(
            emberArc,
            with: .color(index == 0 ? pale : tint),
            style: StrokeStyle(
              lineWidth: 0.65 + CGFloat(2 - index) * 0.28,
              lineCap: .round
            )
          )
        }

      case .earth:
        for ridge in 0..<4 {
          let y = size.height * (0.3 + CGFloat(ridge) * 0.12)
          var stratum = Path()
          stratum.move(to: CGPoint(x: size.width * 0.18, y: y))
          stratum.addCurve(
            to: CGPoint(x: size.width * 0.82, y: y + unit * 0.015),
            control1: CGPoint(x: size.width * 0.36, y: y - unit * 0.065),
            control2: CGPoint(x: size.width * 0.63, y: y + unit * 0.06)
          )
          context.stroke(
            stratum,
            with: .color(ridge.isMultiple(of: 2) ? pale : tint),
            lineWidth: ridge.isMultiple(of: 2) ? 0.8 : 0.5
          )
        }

      case .metal:
        var facets = Path()
        for index in 0..<8 {
          let angle = Double(index) * 2 * .pi / 8 + time * 0.045
          facets.move(
            to: CGPoint(
              x: center.x + cos(angle) * unit * 0.1,
              y: center.y + sin(angle) * unit * 0.1
            ))
          facets.addLine(
            to: CGPoint(
              x: center.x + cos(angle) * unit * 0.41,
              y: center.y + sin(angle) * unit * 0.41
            ))
        }
        context.stroke(
          facets,
          with: .color(pale),
          style: StrokeStyle(lineWidth: 0.6, lineCap: .round)
        )

      case .water:
        for ripple in 0..<3 {
          let width = unit * (0.28 + CGFloat(ripple) * 0.18)
          let height = width * (0.22 + CGFloat(ripple) * 0.035)
          let drift = sin(time * 0.7 + Double(ripple)) * unit * 0.025
          context.stroke(
            Path(
              ellipseIn: CGRect(
                x: center.x - width / 2,
                y: center.y + unit * (0.05 + CGFloat(ripple) * 0.09) + drift,
                width: width,
                height: height
              )
            ),
            with: .color(ripple == 0 ? pale : tint),
            lineWidth: 0.55 + CGFloat(2 - ripple) * 0.16
          )
        }
      }
    }
    .allowsHitTesting(false)
  }
}

struct EarthPlanetNode: View {
  let size: CGFloat
  let time: TimeInterval
  let index: Int
  let energy: Double
  let color: Color

  var body: some View {
    ZStack {
      if index.isMultiple(of: 2) {
        Ellipse()
          .stroke(color.opacity(0.46 + energy * 0.16), lineWidth: 0.7 + energy * 0.4)
          .frame(width: size * 1.65, height: size * 0.48)
          .rotationEffect(.degrees(-18 + sin(time * 0.8 + Double(index)) * 5))
      }

      Circle()
        .fill(
          RadialGradient(
            colors: [
              Color(red: 0.96, green: 0.7, blue: 0.38).opacity(0.9),
              color.opacity(0.88),
              Color(red: 0.16, green: 0.06, blue: 0.018),
            ],
            center: .topLeading,
            startRadius: 0,
            endRadius: size * 0.7
          )
        )
        .overlay {
          Circle()
            .trim(from: 0.08, to: 0.42)
            .stroke(Color.white.opacity(0.34), lineWidth: 0.7)
            .rotationEffect(.degrees(time * 18 + Double(index) * 41))
        }
        .frame(width: size, height: size)
        .shadow(color: color.opacity(0.62), radius: 5 + energy * 5)
    }
    .frame(width: size * 1.7, height: size * 1.2)
  }
}

struct FivePhaseMaterialDetailLayer: View {
  let element: FivePhaseElement
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)

      switch element {
      case .wood:
        for index in 0..<18 {
          let seed = Double(index + 1)
          let angle = seed * 2.31 + time * (index.isMultiple(of: 2) ? 0.08 : -0.055)
          let radius = unit * CGFloat(0.2 + seed.truncatingRemainder(dividingBy: 5) * 0.042)
          let leafCenter = polarPoint(center: center, radius: radius, angle: angle)
          let leaf = leafPath(
            center: leafCenter,
            length: unit * CGFloat(0.014 + seed.truncatingRemainder(dividingBy: 3) * 0.004),
            angle: angle + sin(time + seed) * 0.22
          )
          context.fill(
            leaf,
            with: .linearGradient(
              Gradient(colors: [Color.white.opacity(0.5), element.color.opacity(0.58)]),
              startPoint: CGPoint(x: leafCenter.x, y: leafCenter.y - unit * 0.012),
              endPoint: CGPoint(x: leafCenter.x, y: leafCenter.y + unit * 0.012)
            )
          )
          context.stroke(
            leaf,
            with: .color(Color(red: 0.025, green: 0.22, blue: 0.08).opacity(0.7)),
            lineWidth: 0.45
          )
        }

      case .fire:
        for index in 0..<24 {
          let seed = Double(index + 1)
          let x = center.x + sin(seed * 8.17) * unit * 0.34
          let travel = (time * (28 + seed.truncatingRemainder(dividingBy: 18)) + seed * 11)
            .truncatingRemainder(dividingBy: Double(unit * 0.72))
          let y = center.y + unit * 0.35 - CGFloat(travel)
          let length = unit * CGFloat(0.008 + seed.truncatingRemainder(dividingBy: 4) * 0.004)
          var ember = Path()
          ember.move(to: CGPoint(x: x, y: y))
          ember.addLine(to: CGPoint(x: x + sin(seed) * length * 0.35, y: y - length))
          var glow = context
          glow.addFilter(.blur(radius: 3))
          glow.stroke(
            ember,
            with: .color(Color.orange.opacity(0.4 + energy * 0.16)),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
          )
          context.stroke(
            ember,
            with: .color(
              (index.isMultiple(of: 5) ? Color.white : Color.yellow)
                .opacity(0.5 + energy * 0.18)
            ),
            style: StrokeStyle(lineWidth: 0.75, lineCap: .round)
          )
        }

      case .earth:
        for index in 0..<38 {
          let seed = Double(index + 1)
          let isPebble = index >= 20
          let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
          let orbitSpeed =
            (isPebble ? 0.12 : 0.075) + seed.truncatingRemainder(dividingBy: 5) * 0.014
          let angle = seed * 2.07 + time * orbitSpeed * direction
          let radiusPulse = sin(time * (0.48 + seed * 0.013) + seed) * (isPebble ? 0.018 : 0.011)
          let radius =
            unit
            * CGFloat(
              (isPebble ? 0.12 : 0.16)
                + seed.truncatingRemainder(dividingBy: 6) * (isPebble ? 0.052 : 0.043)
                + radiusPulse)
          let orbitCenter = polarPoint(center: center, radius: radius, angle: angle)
          let floatOffset =
            sin(time * (0.82 + seed * 0.018) + seed * 0.7)
            * unit * (isPebble ? 0.022 : 0.034)
          let rockCenter = CGPoint(x: orbitCenter.x, y: orbitCenter.y + floatOffset)
          let rockSize =
            unit
            * CGFloat(
              (isPebble ? 0.0055 : 0.012)
                + seed.truncatingRemainder(dividingBy: 4) * (isPebble ? 0.0018 : 0.004))
          let rock = rockPath(
            center: rockCenter,
            size: rockSize,
            seed: seed,
            rotation: time * (0.22 + seed * 0.012) * direction
          )
          if !isPebble || index.isMultiple(of: 3) {
            var rockShadow = context
            rockShadow.addFilter(.blur(radius: isPebble ? 2 : 4))
            rockShadow.fill(
              rock,
              with: .color(Color(red: 0.92, green: 0.55, blue: 0.24).opacity(0.16))
            )
          }
          context.fill(
            rock,
            with: .linearGradient(
              Gradient(colors: [
                Color(red: 0.76, green: 0.5, blue: 0.28).opacity(0.42),
                Color(red: 0.16, green: 0.07, blue: 0.025).opacity(0.78),
              ]),
              startPoint: CGPoint(x: rockCenter.x - rockSize, y: rockCenter.y - rockSize),
              endPoint: CGPoint(x: rockCenter.x + rockSize, y: rockCenter.y + rockSize)
            )
          )
          context.stroke(
            rock,
            with: .color(element.color.opacity(0.28 + energy * 0.12)),
            lineWidth: 0.55
          )
        }

      case .metal:
        for index in 0..<12 {
          let angle = Double(index) * 2 * Double.pi / 12 - time * 0.19
          let glintCenter = polarPoint(center: center, radius: unit * 0.27, angle: angle)
          let pulse = max(0, sin(time * 2.8 + Double(index) * 1.47))
          let length = unit * CGFloat(0.012 + pulse * 0.018)
          let glint = glintPath(center: glintCenter, length: length, angle: angle)
          var glow = context
          glow.addFilter(.blur(radius: 4 + pulse * 5))
          glow.stroke(
            glint,
            with: .color(element.color.opacity(0.34 + pulse * 0.34)),
            style: StrokeStyle(lineWidth: 4, lineCap: .round)
          )
          context.stroke(
            glint,
            with: .color(Color.white.opacity(0.42 + pulse * 0.5)),
            style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
          )
        }

      case .water:
        for index in 0..<36 {
          let seed = Double(index + 1)
          let xHash = abs(sin(seed * 13.71) * 9_371).truncatingRemainder(dividingBy: 1)
          let x = center.x - unit * 0.4 + unit * 0.8 * CGFloat(xHash)
          let travel = (time * (48 + seed.truncatingRemainder(dividingBy: 24)) + seed * 17)
            .truncatingRemainder(dividingBy: Double(unit * 0.82))
          let y = center.y - unit * 0.41 + CGFloat(travel)
          let length = unit * CGFloat(0.018 + seed.truncatingRemainder(dividingBy: 4) * 0.006)
          var rain = Path()
          rain.move(to: CGPoint(x: x, y: y))
          rain.addLine(to: CGPoint(x: x - length * 0.16, y: y + length))
          context.stroke(
            rain,
            with: .linearGradient(
              Gradient(colors: [.clear, Color.white.opacity(0.68), element.color.opacity(0.34)]),
              startPoint: CGPoint(x: x, y: y),
              endPoint: CGPoint(x: x - length * 0.16, y: y + length)
            ),
            style: StrokeStyle(
              lineWidth: index.isMultiple(of: 7) ? 1.15 : 0.55,
              lineCap: .round
            )
          )
        }

        for index in 0..<18 {
          let seed = Double(index + 1)
          let x = center.x + sin(seed * 5.31 + time * 0.24) * unit * 0.38
          let travel = (time * (10 + seed.truncatingRemainder(dividingBy: 7)) + seed * 23)
            .truncatingRemainder(dividingBy: Double(unit * 0.76))
          let flakeCenter = CGPoint(x: x, y: center.y - unit * 0.38 + CGFloat(travel))
          let flake = snowCrystalPath(
            center: flakeCenter,
            radius: unit * CGFloat(0.006 + seed.truncatingRemainder(dividingBy: 3) * 0.0026),
            rotation: time * 0.42 + seed
          )
          context.stroke(
            flake,
            with: .color(Color.white.opacity(0.46 + energy * 0.18)),
            style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
          )
        }

        for index in 0..<22 {
          let seed = Double(index + 1)
          let angle = seed * 2.23 + time * 0.06
          let radius = unit * CGFloat(0.15 + seed.truncatingRemainder(dividingBy: 7) * 0.037)
          let bubbleCenter = polarPoint(center: center, radius: radius, angle: angle)
          let bubbleRadius =
            unit * CGFloat(0.004 + seed.truncatingRemainder(dividingBy: 4) * 0.0025)
          let bubbleRect = CGRect(
            x: bubbleCenter.x - bubbleRadius,
            y: bubbleCenter.y - bubbleRadius,
            width: bubbleRadius * 2,
            height: bubbleRadius * 2
          )
          context.fill(
            Path(ellipseIn: bubbleRect),
            with: .radialGradient(
              Gradient(colors: [Color.white.opacity(0.62), element.color.opacity(0.16), .clear]),
              center: CGPoint(
                x: bubbleCenter.x - bubbleRadius * 0.3,
                y: bubbleCenter.y - bubbleRadius * 0.3
              ),
              startRadius: 0,
              endRadius: bubbleRadius
            )
          )
          context.stroke(
            Path(ellipseIn: bubbleRect),
            with: .color(element.color.opacity(0.3 + energy * 0.15)),
            lineWidth: 0.5
          )
        }
      }
    }
    .blendMode(element == .earth ? .normal : .plusLighter)
    .allowsHitTesting(false)
  }

  private func polarPoint(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
    CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
  }

  private func leafPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
    let tangent = CGPoint(x: cos(angle), y: sin(angle))
    let normal = CGPoint(x: -sin(angle), y: cos(angle))
    return Path { path in
      let start = CGPoint(x: center.x - tangent.x * length, y: center.y - tangent.y * length)
      let end = CGPoint(x: center.x + tangent.x * length, y: center.y + tangent.y * length)
      path.move(to: start)
      path.addQuadCurve(
        to: end,
        control: CGPoint(
          x: center.x + normal.x * length * 0.55, y: center.y + normal.y * length * 0.55)
      )
      path.addQuadCurve(
        to: start,
        control: CGPoint(
          x: center.x - normal.x * length * 0.55, y: center.y - normal.y * length * 0.55)
      )
    }
  }

  private func rockPath(
    center: CGPoint,
    size: CGFloat,
    seed: Double,
    rotation: Double
  ) -> Path {
    Path { path in
      for index in 0..<5 {
        let angle = Double(index) * 2 * Double.pi / 5 + seed + rotation
        let radius = size * CGFloat(0.72 + abs(sin(seed * Double(index + 1))) * 0.32)
        let point = CGPoint(
          x: center.x + cos(angle) * radius,
          y: center.y + sin(angle) * radius
        )
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func glintPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
    let primary = CGPoint(x: cos(angle), y: sin(angle))
    let cross = CGPoint(x: -primary.y, y: primary.x)
    return Path { path in
      path.move(
        to: CGPoint(x: center.x - primary.x * length, y: center.y - primary.y * length)
      )
      path.addLine(
        to: CGPoint(x: center.x + primary.x * length, y: center.y + primary.y * length)
      )
      path.move(
        to: CGPoint(x: center.x - cross.x * length * 0.45, y: center.y - cross.y * length * 0.45)
      )
      path.addLine(
        to: CGPoint(x: center.x + cross.x * length * 0.45, y: center.y + cross.y * length * 0.45)
      )
    }
  }

  private func snowCrystalPath(
    center: CGPoint,
    radius: CGFloat,
    rotation: Double
  ) -> Path {
    Path { path in
      for arm in 0..<3 {
        let angle = rotation + Double(arm) * Double.pi / 3
        path.move(
          to: CGPoint(x: center.x - cos(angle) * radius, y: center.y - sin(angle) * radius)
        )
        path.addLine(
          to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        )
      }
    }
  }
}

struct FormationConstellation: View {
  let element: FivePhaseElement
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let centralRadius = unit * 0.17
      let satelliteOrbit = unit * 0.34
      let latticeColor = element == .fire ? Color.orange : element.color
      let breath = CGFloat(0.5 + 0.5 * sin(time * 1.28 + Double(element.rawValue) * 0.73))
      let outwardBreath = 0.76 + breath * 0.58
      let inwardBreath = 1.22 - breath * 0.34

      for ring in 0..<4 {
        let radius = unit * (0.225 + CGFloat(ring) * 0.074)
        let rect = CGRect(
          x: center.x - radius,
          y: center.y - radius,
          width: radius * 2,
          height: radius * 2
        )
        context.stroke(
          Path(ellipseIn: rect),
          with: .color(
            latticeColor.opacity(0.1 + Double(3 - ring) * 0.035 + energy * 0.08)
          ),
          style: StrokeStyle(
            lineWidth: (0.55 + CGFloat(ring.isMultiple(of: 2) ? 0.8 : 0.25))
              * (ring.isMultiple(of: 2) ? outwardBreath : inwardBreath),
            dash: ring == 2 ? [unit * 0.018, unit * 0.012] : []
          )
        )
      }

      for sector in 0..<6 {
        let startAngle = Double(sector) * 2 * .pi / 6 - .pi / 2
        let endAngle = startAngle + 2 * .pi / 6
        let boundaryStart = CGPoint(
          x: center.x + cos(startAngle) * centralRadius * 1.08,
          y: center.y + sin(startAngle) * centralRadius * 1.08
        )
        let boundaryEnd = CGPoint(
          x: center.x + cos(startAngle) * unit * 0.385,
          y: center.y + sin(startAngle) * unit * 0.385
        )
        var boundary = Path()
        boundary.move(to: boundaryStart)
        boundary.addLine(to: boundaryEnd)
        context.stroke(
          boundary,
          with: .color(latticeColor.opacity(0.12 + energy * 0.11)),
          style: StrokeStyle(
            lineWidth: (sector.isMultiple(of: 2) ? 1.05 : 0.5)
              * (sector.isMultiple(of: 2) ? outwardBreath : inwardBreath),
            dash: sector.isMultiple(of: 2) ? [] : [unit * 0.014, unit * 0.009]
          )
        )

        var segment = Path()
        segment.addArc(
          center: center,
          radius: unit * 0.425,
          startAngle: .radians(startAngle + 0.11),
          endAngle: .radians(endAngle - 0.11),
          clockwise: false
        )
        context.stroke(
          segment,
          with: .color(
            latticeColor.opacity(0.24 + Double(sector % 3) * 0.045 + energy * 0.12)
          ),
          style: StrokeStyle(
            lineWidth: (2.4 + CGFloat(sector.isMultiple(of: 2) ? 0.9 : 0))
              * outwardBreath,
            lineCap: .butt
          )
        )
      }

      for layer in 0..<2 {
        let count = layer == 0 ? 6 : 8
        let radius = unit * (layer == 0 ? 0.285 : 0.325)
        let phase = time * (layer == 0 ? 0.026 : -0.019) + Double(layer) * .pi / 8
        var polygon = Path()
        for point in 0..<count {
          let angle = Double(point) * 2 * .pi / Double(count) - .pi / 2 + phase
          let vertex = CGPoint(
            x: center.x + cos(angle) * radius,
            y: center.y + sin(angle) * radius
          )
          point == 0 ? polygon.move(to: vertex) : polygon.addLine(to: vertex)
        }
        polygon.closeSubpath()
        context.stroke(
          polygon,
          with: .color(latticeColor.opacity(0.13 + Double(layer) * 0.05 + energy * 0.1)),
          style: StrokeStyle(
            lineWidth: (layer == 0 ? 1.05 : 0.62)
              * (layer == 0 ? inwardBreath : outwardBreath),
            lineJoin: .round
          )
        )
      }

      for triangle in 0..<2 {
        var hexagram = Path()
        for point in 0..<3 {
          let angle =
            Double(point) * 2 * .pi / 3 - .pi / 2 + Double(triangle) * .pi
            - time * (triangle == 0 ? 0.022 : -0.018)
          let vertex = CGPoint(
            x: center.x + cos(angle) * unit * 0.225,
            y: center.y + sin(angle) * unit * 0.225
          )
          point == 0 ? hexagram.move(to: vertex) : hexagram.addLine(to: vertex)
        }
        hexagram.closeSubpath()
        context.stroke(
          hexagram,
          with: .color(
            (triangle == 0 ? Color.white : latticeColor)
              .opacity(0.12 + energy * 0.13)
          ),
          style: StrokeStyle(
            lineWidth: (triangle == 0 ? 0.65 : 1.05)
              * (triangle == 0 ? inwardBreath : outwardBreath),
            lineJoin: .round
          )
        )
      }

      for index in 0..<30 {
        let angle = Double(index) * 2 * .pi / 30 - time * 0.018
        let innerRadius = unit * (index.isMultiple(of: 3) ? 0.372 : 0.386)
        let outerRadius = unit * (index.isMultiple(of: 5) ? 0.414 : 0.402)
        let tangent = angle + .pi / 2
        let runeWidth = unit * (index.isMultiple(of: 4) ? 0.012 : 0.007)
        let inner = CGPoint(
          x: center.x + cos(angle) * innerRadius,
          y: center.y + sin(angle) * innerRadius
        )
        let outer = CGPoint(
          x: center.x + cos(angle) * outerRadius,
          y: center.y + sin(angle) * outerRadius
        )
        var rune = Path()
        rune.move(
          to: CGPoint(
            x: inner.x - cos(tangent) * runeWidth,
            y: inner.y - sin(tangent) * runeWidth
          )
        )
        rune.addLine(to: outer)
        rune.addLine(
          to: CGPoint(
            x: inner.x + cos(tangent) * runeWidth,
            y: inner.y + sin(tangent) * runeWidth
          )
        )
        context.stroke(
          rune,
          with: .color(
            (index.isMultiple(of: 5) ? Color.white : latticeColor)
              .opacity(0.16 + energy * 0.12)
          ),
          style: StrokeStyle(
            lineWidth: (index.isMultiple(of: 5) ? 1.35 : 0.65)
              * (index.isMultiple(of: 5) ? outwardBreath : inwardBreath),
            lineCap: .round,
            lineJoin: .round
          )
        )
      }

      for index in 0..<6 {
        let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
        let angle = Double(index) * 2 * .pi / 6 - .pi / 2 + time * 0.018 * direction
        let node = CGPoint(
          x: center.x + cos(angle) * satelliteOrbit,
          y: center.y + sin(angle) * satelliteOrbit
        )
        let nodeRadius = unit * (index.isMultiple(of: 3) ? 0.054 : 0.044)
        let connectorStart = CGPoint(
          x: center.x + cos(angle) * centralRadius,
          y: center.y + sin(angle) * centralRadius
        )
        let connectorEnd = CGPoint(
          x: node.x - cos(angle) * nodeRadius,
          y: node.y - sin(angle) * nodeRadius
        )
        var connector = Path()
        connector.move(to: connectorStart)
        connector.addLine(to: connectorEnd)
        context.stroke(
          connector,
          with: .color(latticeColor.opacity(0.16 + energy * 0.14)),
          style: StrokeStyle(
            lineWidth: (index.isMultiple(of: 2) ? 1.15 : 0.55)
              * (index.isMultiple(of: 2) ? outwardBreath : inwardBreath),
            dash: index.isMultiple(of: 2) ? [] : [unit * 0.012, unit * 0.008]
          )
        )

        for inset in 0..<2 {
          let radius = nodeRadius * (1 - CGFloat(inset) * 0.34)
          let nodeRect = CGRect(
            x: node.x - radius,
            y: node.y - radius,
            width: radius * 2,
            height: radius * 2
          )
          context.stroke(
            Path(ellipseIn: nodeRect),
            with: .color(
              latticeColor.opacity(0.22 + Double(1 - inset) * 0.14 + energy * 0.14)
            ),
            lineWidth: (inset == 0 ? 1.15 : 0.55)
              * (inset == 0 ? outwardBreath : inwardBreath)
          )
        }

        func nodePoint(radial: CGFloat, tangent: CGFloat) -> CGPoint {
          CGPoint(
            x: node.x + cos(angle) * radial + cos(angle + .pi / 2) * tangent,
            y: node.y + sin(angle) * radial + sin(angle + .pi / 2) * tangent
          )
        }

        var nodeGlyph = Path()
        if index.isMultiple(of: 2) {
          let inner = nodePoint(radial: -nodeRadius * 0.64, tangent: 0)
          let outer = nodePoint(radial: nodeRadius * 0.64, tangent: 0)
          nodeGlyph.move(to: inner)
          nodeGlyph.addQuadCurve(
            to: outer,
            control: nodePoint(radial: 0, tangent: -nodeRadius * 0.52)
          )
          nodeGlyph.addQuadCurve(
            to: inner,
            control: nodePoint(radial: 0, tangent: nodeRadius * 0.52)
          )
          nodeGlyph.move(to: nodePoint(radial: -nodeRadius * 0.2, tangent: 0))
          nodeGlyph.addLine(to: nodePoint(radial: nodeRadius * 0.2, tangent: 0))
        } else {
          nodeGlyph.move(to: nodePoint(radial: -nodeRadius * 0.78, tangent: 0))
          nodeGlyph.addLine(to: nodePoint(radial: 0, tangent: -nodeRadius * 0.58))
          nodeGlyph.addLine(to: nodePoint(radial: nodeRadius * 0.78, tangent: 0))
          nodeGlyph.addLine(to: nodePoint(radial: 0, tangent: nodeRadius * 0.58))
          nodeGlyph.closeSubpath()
        }
        context.stroke(
          nodeGlyph,
          with: .color(Color.white.opacity(0.24 + energy * 0.18)),
          style: StrokeStyle(lineWidth: 0.65 * inwardBreath, lineJoin: .round)
        )

        if index.isMultiple(of: 2) {
          var crystalFrame = Path()
          crystalFrame.move(to: nodePoint(radial: -nodeRadius * 1.55, tangent: 0))
          crystalFrame.addLine(to: nodePoint(radial: 0, tangent: -nodeRadius * 0.72))
          crystalFrame.addLine(to: nodePoint(radial: nodeRadius * 1.55, tangent: 0))
          crystalFrame.addLine(to: nodePoint(radial: 0, tangent: nodeRadius * 0.72))
          crystalFrame.closeSubpath()
          context.stroke(
            crystalFrame,
            with: .color(latticeColor.opacity(0.2 + energy * 0.14)),
            style: StrokeStyle(lineWidth: 0.8 * outwardBreath, lineJoin: .miter)
          )
        }
      }

      for ring in 0..<2 {
        let radius = unit * (0.105 + CGFloat(ring) * 0.062)
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: center.x - radius,
              y: center.y - radius,
              width: radius * 2,
              height: radius * 2
            )
          ),
          with: .color(latticeColor.opacity(0.28 - Double(ring) * 0.08 + energy * 0.14)),
          lineWidth: (ring == 0 ? 1.2 : 0.7)
            * (ring == 0 ? outwardBreath : inwardBreath)
        )
      }
    }
    .frame(width: diameter, height: diameter)
    .blendMode(element == .earth ? .normal : .plusLighter)
  }
}
