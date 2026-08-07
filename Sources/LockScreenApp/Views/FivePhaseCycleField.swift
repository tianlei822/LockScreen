import SwiftUI

struct FivePhaseCycleState {
  static let stageDuration = 3.4

  let current: FivePhaseElement
  let next: FivePhaseElement
  let progress: Double

  init(time: TimeInterval) {
    let stage = Int(floor(time / Self.stageDuration))
    let elements = FivePhaseElement.allCases
    current = elements[Self.positiveModulo(stage, elements.count)]
    next = elements[Self.positiveModulo(stage + 1, elements.count)]
    progress = (time - floor(time / Self.stageDuration) * Self.stageDuration) / Self.stageDuration
  }

  func opacity(for element: FivePhaseElement) -> Double {
    let transition = smoothstep((progress - 0.76) / 0.24)
    if element == current { return 1 - transition }
    if element == next { return transition }
    return 0
  }

  private func smoothstep(_ value: Double) -> Double {
    let clamped = max(0, min(1, value))
    return clamped * clamped * (3 - 2 * clamped)
  }

  private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
    let result = value % divisor
    return result >= 0 ? result : result + divisor
  }
}

/// Plays one elemental discipline at a time, cross-fading into the next phase.
struct FivePhaseCycleField: View {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    let cycle = FivePhaseCycleState(time: time)

    ZStack {
      ForEach(FivePhaseElement.allCases) { element in
        FivePhaseAttributeStage(
          element: element,
          diameter: diameter,
          time: time,
          energy: energy,
          isActivated: isActivated
        )
        .opacity(cycle.opacity(for: element))
        .scaleEffect(0.86 + cycle.opacity(for: element) * 0.14)
        .zIndex(element == cycle.current ? 1 : 0)
      }
    }
    .frame(width: diameter, height: diameter)
    .animation(.linear(duration: 0.08), value: cycle.current)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Five Phases cycle, \(cycle.current.accessibilityName) active")
  }
}

private struct FivePhaseAttributeStage: View {
  let element: FivePhaseElement
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    let pulse =
      1 + sin(time * (isActivated ? 4.2 : 1.65) + Double(element.rawValue))
      * (0.018 + energy * 0.022)
    let strokeBreath = CGFloat(
      0.84 + (0.5 + 0.5 * sin(time * 1.35 + Double(element.rawValue) * 0.8)) * 0.3
    )

    ZStack {
      RadialGradient(
        colors: [element.color.opacity(0.2 + energy * 0.2), .clear],
        center: .center,
        startRadius: 0,
        endRadius: diameter * 0.38
      )
      .frame(width: diameter * 0.78, height: diameter * 0.78)
      .blendMode(.plusLighter)

      FormationConstellation(
        element: element,
        diameter: diameter,
        time: time,
        energy: energy
      )

      pattern

      FivePhaseMaterialDetailLayer(
        element: element,
        time: time,
        energy: energy
      )

      ForEach(0..<3, id: \.self) { index in
        ResonantRing(
          phase: time * (1.1 + Double(index) * 0.28),
          lobes: 4 + element.rawValue + index * 2,
          amplitude: 0.012 + CGFloat(index) * 0.008 + energy * 0.006
        )
        .stroke(
          element.color.opacity(0.12 + Double(index) * 0.08 + energy * 0.18),
          lineWidth: (0.55 + CGFloat(index) * 0.45 + energy * 0.7) * strokeBreath
        )
        .frame(
          width: diameter * (0.46 + CGFloat(index) * 0.115),
          height: diameter * (0.46 + CGFloat(index) * 0.115)
        )
        .rotationEffect(
          .degrees(time * Double(index.isMultiple(of: 2) ? 12 : -10))
        )
      }

      FivePhaseSigil(
        element: element,
        size: diameter * (element == .fire ? 0.17 : 0.24),
        energy: energy,
        time: time
      )
      .opacity(element == .fire ? 0.68 : 1)
      .shadow(color: element.color, radius: 12 + energy * 16)

      ForEach(0..<6, id: \.self) { index in
        Circle()
          .fill(index.isMultiple(of: 2) ? Color.white : element.color)
          .frame(width: 3 + energy * 3, height: 3 + energy * 3)
          .shadow(color: element.color, radius: 5 + energy * 6)
          .offset(y: -diameter * (0.16 + CGFloat(index.isMultiple(of: 2) ? 0.05 : 0.09)))
          .rotationEffect(.degrees(Double(index) * 60 + time * 18))
      }
    }
    .frame(width: diameter, height: diameter)
    .scaleEffect(pulse)
    .blendMode(element == .earth ? .normal : .plusLighter)
  }

  @ViewBuilder
  private var pattern: some View {
    switch element {
    case .wood:
      woodPattern
    case .fire:
      firePattern
    case .earth:
      earthPattern
    case .metal:
      metalPattern
    case .water:
      waterPattern
    }
  }

  private var woodPattern: some View {
    ZStack {
      ForEach(0..<6, id: \.self) { index in
        BranchFormationShape(phase: time * 0.9 + Double(index))
          .stroke(
            element.color.opacity(0.32 + energy * 0.3),
            style: StrokeStyle(
              lineWidth: 0.8 + CGFloat(index.isMultiple(of: 2) ? 1.2 : 0.4) + energy,
              lineCap: .round,
              lineJoin: .round
            )
          )
          .frame(width: diameter * 0.23, height: diameter * 0.42)
          .offset(y: -diameter * 0.18)
          .rotationEffect(.degrees(Double(index) * 60 + time * 4))
      }

      ForEach(0..<12, id: \.self) { index in
        LeafFormationShape()
          .fill(
            LinearGradient(
              colors: [Color.white.opacity(0.76), element.color, Color.green.opacity(0.34)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(
            width: diameter * (index.isMultiple(of: 3) ? 0.034 : 0.026),
            height: diameter * (index.isMultiple(of: 3) ? 0.072 : 0.056)
          )
          .overlay {
            LeafVeinFormationShape()
              .stroke(
                Color(red: 0.08, green: 0.34, blue: 0.16).opacity(0.76),
                style: StrokeStyle(lineWidth: 0.65, lineCap: .round)
              )
          }
          .offset(
            x: sin(Double(index) * 2.4 + time * 0.35) * diameter * 0.17,
            y: -diameter * (0.1 + CGFloat(index % 4) * 0.07)
          )
          .rotationEffect(.degrees(Double(index) * 47 + sin(time + Double(index)) * 12))
          .shadow(color: element.color.opacity(0.72), radius: 4 + energy * 4)
      }
    }
  }

  private var firePattern: some View {
    ZStack {
      SolarFireDragonFormation(diameter: diameter * 0.72, time: time, energy: energy)

      ForEach(0..<3, id: \.self) { index in
        Circle()
          .trim(
            from: 0.06 + Double(index) * 0.085,
            to: 0.71 + Double(index) * 0.065
          )
          .stroke(
            index == 1 ? Color.orange : element.color,
            style: StrokeStyle(
              lineWidth: 0.75 + CGFloat(2 - index) * 0.45 + energy,
              lineCap: .round,
              dash: [diameter * 0.018, diameter * 0.012]
            )
          )
          .frame(width: diameter * (0.36 + CGFloat(index) * 0.1))
          .opacity(0.52 - Double(index) * 0.08 + energy * 0.18)
          .rotationEffect(
            .degrees(time * Double(index.isMultiple(of: 2) ? 13 : -9) + Double(index) * 47)
          )
      }
    }
  }

  private var earthPattern: some View {
    ZStack {
      EarthSealFormation(
        diameter: diameter * 0.68,
        time: time,
        energy: energy,
        color: element.color
      )
      .offset(y: diameter * 0.035)

      ForEach(0..<2, id: \.self) { index in
        Rectangle()
          .stroke(
            element.color.opacity(0.17 + Double(1 - index) * 0.12 + energy * 0.16),
            lineWidth: 0.7 + CGFloat(index) * 0.5 + energy * 0.6
          )
          .frame(
            width: diameter * (0.32 + CGFloat(index) * 0.17),
            height: diameter * (0.32 + CGFloat(index) * 0.17)
          )
          .rotationEffect(
            .degrees(45 + Double(index) * 18 + time * Double(index == 0 ? -2.5 : 1.8))
          )
          .scaleEffect(1 + sin(time * 1.1 - Double(index) * 0.7) * 0.022)
      }
    }
  }

  private var metalPattern: some View {
    ZStack {
      swordRing(count: 10, orbit: 0.23, speed: -11, scale: 1, phase: 0)
      swordRing(count: 6, orbit: 0.135, speed: 17, scale: 0.72, phase: 1.7)
      swordRing(count: 18, orbit: 0.335, speed: -23, scale: 0.38, phase: 3.4)
    }
  }

  private func swordRing(
    count: Int,
    orbit: CGFloat,
    speed: Double,
    scale: CGFloat,
    phase: Double
  ) -> some View {
    ForEach(0..<count, id: \.self) { index in
      let bob = sin(time * 1.55 + Double(index) * 1.37 + phase)
      let bank = sin(time * 1.1 + Double(index) * 0.83 + phase) * 7

      ZStack {
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                .clear,
                element.color.opacity(0.08),
                element.color.opacity(0.5 + energy * 0.18),
                Color.white.opacity(0.72),
                .clear,
              ],
              startPoint: .bottom,
              endPoint: .top
            )
          )
          .frame(width: diameter * 0.014 * scale, height: diameter * 0.42 * scale)
          .blur(radius: 2.5 + energy * 2)
          .scaleEffect(y: 0.84 + abs(bob) * 0.28)

        SpiritSwordGlyph(color: element.color, energy: energy)
          .frame(width: diameter * 0.044 * scale, height: diameter * 0.3 * scale)
      }
      .scaleEffect(1 + bob * 0.045)
      .offset(y: -diameter * orbit + bob * diameter * 0.014)
      .rotationEffect(
        .degrees(Double(index) * 360 / Double(count) + time * speed + bank)
      )
      .shadow(color: element.color.opacity(0.82), radius: 5 + energy * 8)
    }
  }

  private var waterPattern: some View {
    ZStack {
      WaterTideFormation(
        diameter: diameter * 0.72,
        time: time,
        energy: energy,
        color: element.color
      )

      ForEach(0..<2, id: \.self) { index in
        ResonantRing(
          phase: -time * (1.5 + Double(index) * 0.18),
          lobes: 5 + index * 2,
          amplitude: 0.018 + CGFloat(index) * 0.006
        )
        .trim(from: 0.08 + Double(index) * 0.04, to: 0.9 - Double(index) * 0.025)
        .stroke(
          element.color.opacity(0.2 + Double(1 - index) * 0.1 + energy * 0.14),
          style: StrokeStyle(
            lineWidth: 0.7 + CGFloat(index) * 0.5 + energy * 0.7,
            lineCap: .round
          )
        )
        .frame(
          width: diameter * (0.46 + CGFloat(index) * 0.16),
          height: diameter * (0.46 + CGFloat(index) * 0.16)
        )
        .rotationEffect(.degrees(time * Double(index.isMultiple(of: 2) ? 6 : -5)))
      }
    }
  }
}

private struct FivePhaseMaterialDetailLayer: View {
  let element: FivePhaseElement
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas { context, size in
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

private struct FormationConstellation: View {
  let element: FivePhaseElement
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas { context, size in
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

private struct BranchFormationShape: Shape {
  let phase: Double

  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addCurve(
        to: CGPoint(x: rect.midX + sin(phase) * rect.width * 0.12, y: rect.minY),
        control1: CGPoint(x: rect.width * 0.35, y: rect.height * 0.7),
        control2: CGPoint(x: rect.width * 0.68, y: rect.height * 0.32)
      )
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.58))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.35))
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.42))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.2))
    }
  }
}

private struct SpiritSwordFormationShape: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.58))
      path.addLine(to: CGPoint(x: rect.width * 0.57, y: rect.height * 0.72))
      path.addLine(to: CGPoint(x: rect.width * 0.57, y: rect.height * 0.89))
      path.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.95))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.95))
      path.addLine(to: CGPoint(x: rect.width * 0.43, y: rect.height * 0.89))
      path.addLine(to: CGPoint(x: rect.width * 0.43, y: rect.height * 0.72))
      path.addLine(to: CGPoint(x: rect.width * 0.34, y: rect.height * 0.58))
      path.closeSubpath()

      path.move(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.71))
      path.addLine(to: CGPoint(x: rect.width * 0.88, y: rect.height * 0.71))
      path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.77))
      path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.77))
      path.closeSubpath()
    }
  }
}

private struct SpiritSwordDetailShape: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.04))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.69))

      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.12))
      path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.58))
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.12))
      path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.58))

      path.move(to: CGPoint(x: rect.width * 0.24, y: rect.height * 0.735))
      path.addLine(to: CGPoint(x: rect.width * 0.76, y: rect.height * 0.735))
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.78))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.93))
      path.move(to: CGPoint(x: rect.width * 0.43, y: rect.height * 0.82))
      path.addLine(to: CGPoint(x: rect.width * 0.57, y: rect.height * 0.86))
      path.move(to: CGPoint(x: rect.width * 0.43, y: rect.height * 0.87))
      path.addLine(to: CGPoint(x: rect.width * 0.57, y: rect.height * 0.91))
    }
  }
}

private struct SpiritSwordGlyph: View {
  let color: Color
  let energy: Double

  var body: some View {
    SpiritSwordFormationShape()
      .fill(
        LinearGradient(
          colors: [
            Color.white.opacity(0.98),
            color.opacity(0.92),
            Color(red: 0.025, green: 0.21, blue: 0.14).opacity(0.96),
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .overlay {
        SpiritSwordFormationShape()
          .stroke(Color.white.opacity(0.72), lineWidth: 0.65 + energy * 0.45)
      }
      .overlay {
        SpiritSwordDetailShape()
          .stroke(
            Color(red: 0.03, green: 0.32, blue: 0.2).opacity(0.9),
            style: StrokeStyle(lineWidth: 0.55, lineCap: .round, lineJoin: .round)
          )
      }
  }
}

private struct LeafFormationShape: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addCurve(
        to: CGPoint(x: rect.midX, y: rect.maxY),
        control1: CGPoint(x: rect.maxX, y: rect.height * 0.24),
        control2: CGPoint(x: rect.maxX, y: rect.height * 0.72)
      )
      path.addCurve(
        to: CGPoint(x: rect.midX, y: rect.minY),
        control1: CGPoint(x: rect.minX, y: rect.height * 0.72),
        control2: CGPoint(x: rect.minX, y: rect.height * 0.24)
      )
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.18))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.88))
    }
  }
}

private struct LeafVeinFormationShape: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.12))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.height * 0.9))

      for index in 1...3 {
        let y = rect.height * (0.24 + CGFloat(index) * 0.15)
        let reach = rect.width * (0.34 - CGFloat(index) * 0.045)
        path.move(to: CGPoint(x: rect.midX, y: y))
        path.addLine(to: CGPoint(x: rect.midX - reach, y: y - rect.height * 0.11))
        path.move(to: CGPoint(x: rect.midX, y: y + rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.midX + reach, y: y - rect.height * 0.07))
      }
    }
  }
}

private struct SolarFireDragonFormation: View {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height) * 0.62
      let solarRadius = unit * 0.145
      let auraRect = CGRect(
        x: center.x - solarRadius * 2.25,
        y: center.y - solarRadius * 2.25,
        width: solarRadius * 4.5,
        height: solarRadius * 4.5
      )

      var solarAura = context
      solarAura.addFilter(.blur(radius: 18 + energy * 10))
      solarAura.fill(
        Path(ellipseIn: auraRect),
        with: .radialGradient(
          Gradient(colors: [
            Color.white.opacity(0.72),
            Color.yellow.opacity(0.82),
            Color.orange.opacity(0.5),
            Color.red.opacity(0.12),
            .clear,
          ]),
          center: center,
          startRadius: 0,
          endRadius: solarRadius * 2.2
        )
      )

      for index in 0..<20 {
        let seed = Double(index + 1)
        let angle = seed * 2 * .pi / 20 + time * 0.055
        let innerRadius = solarRadius * 0.96
        let rayVariation = seed.truncatingRemainder(dividingBy: 5) * 0.07
        let rayPulse = sin(time * 1.8 + seed) * 0.045
        let outerRadius = solarRadius * CGFloat(1.32 + rayVariation + rayPulse)
        let halfWidth: Double = Double.pi / 55.0
        var ray = Path()
        ray.move(
          to: CGPoint(
            x: center.x + cos(angle - halfWidth) * innerRadius,
            y: center.y + sin(angle - halfWidth) * innerRadius
          )
        )
        ray.addLine(
          to: CGPoint(
            x: center.x + cos(angle) * outerRadius,
            y: center.y + sin(angle) * outerRadius
          )
        )
        ray.addLine(
          to: CGPoint(
            x: center.x + cos(angle + halfWidth) * innerRadius,
            y: center.y + sin(angle + halfWidth) * innerRadius
          )
        )
        ray.closeSubpath()
        context.fill(
          ray,
          with: .linearGradient(
            Gradient(colors: [Color.yellow.opacity(0.72), Color.orange.opacity(0.08)]),
            startPoint: center,
            endPoint: CGPoint(
              x: center.x + cos(angle) * outerRadius,
              y: center.y + sin(angle) * outerRadius
            )
          )
        )
      }

      let sunRect = CGRect(
        x: center.x - solarRadius,
        y: center.y - solarRadius,
        width: solarRadius * 2,
        height: solarRadius * 2
      )
      context.fill(
        Path(ellipseIn: sunRect),
        with: .radialGradient(
          Gradient(colors: [
            Color.white,
            Color(red: 1, green: 0.91, blue: 0.32),
            Color.orange,
            Color(red: 0.78, green: 0.07, blue: 0.01),
          ]),
          center: CGPoint(x: center.x - solarRadius * 0.22, y: center.y - solarRadius * 0.2),
          startRadius: 0,
          endRadius: solarRadius
        )
      )
      context.stroke(
        Path(ellipseIn: sunRect.insetBy(dx: solarRadius * 0.16, dy: solarRadius * 0.16)),
        with: .color(Color.white.opacity(0.58 + energy * 0.16)),
        lineWidth: 1.2 + energy
      )

      for index in 0..<4 {
        let start = Double(index) * 1.43 + time * (index.isMultiple(of: 2) ? 0.12 : -0.09)
        var prominence = Path()
        prominence.addArc(
          center: center,
          radius: solarRadius * (1.12 + CGFloat(index) * 0.08),
          startAngle: .radians(start),
          endAngle: .radians(start + 0.62 + Double(index) * 0.08),
          clockwise: false
        )
        var prominenceGlow = context
        prominenceGlow.addFilter(.blur(radius: 5 + CGFloat(index)))
        prominenceGlow.stroke(
          prominence,
          with: .color(Color.orange.opacity(0.48)),
          style: StrokeStyle(lineWidth: 7 - CGFloat(index), lineCap: .round)
        )
        context.stroke(
          prominence,
          with: .color(Color.yellow.opacity(0.68)),
          style: StrokeStyle(lineWidth: 1.35, lineCap: .round)
        )
      }

      for index in 0..<7 {
        let seed = Double(index + 1)
        let base = CGPoint(
          x: center.x + CGFloat(index - 3) * unit * 0.044,
          y: center.y + unit * (0.18 + CGFloat(abs(index - 3)) * 0.006)
        )
        let flame = naturalFlamePath(
          base: base,
          width: unit * CGFloat(0.1 + seed.truncatingRemainder(dividingBy: 3) * 0.016),
          height: unit * CGFloat(0.14 + seed.truncatingRemainder(dividingBy: 4) * 0.032),
          phase: time * (1.55 + seed * 0.025) + seed
        )
        context.fill(
          flame,
          with: .linearGradient(
            Gradient(colors: [
              Color.yellow.opacity(0.88),
              Color.orange.opacity(0.92),
              Color(red: 0.72, green: 0.025, blue: 0.006).opacity(0.68),
              .clear,
            ]),
            startPoint: CGPoint(x: base.x, y: base.y - unit * 0.22),
            endPoint: base
          )
        )
      }

      let dragon = dragonBodyPath(center: center, unit: unit)
      var dragonAura = context
      dragonAura.addFilter(.blur(radius: 9 + energy * 6))
      dragonAura.stroke(
        dragon,
        with: .color(Color(red: 0.74, green: 0.02, blue: 0.006).opacity(0.58)),
        style: StrokeStyle(lineWidth: unit * 0.072, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragon,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.58, green: 0.015, blue: 0.004),
            Color.orange,
            Color(red: 0.82, green: 0.11, blue: 0.008),
          ]),
          startPoint: CGPoint(x: center.x - unit * 0.35, y: center.y + unit * 0.32),
          endPoint: CGPoint(x: center.x + unit * 0.35, y: center.y - unit * 0.3)
        ),
        style: StrokeStyle(lineWidth: unit * 0.052, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragon,
        with: .color(Color.yellow.opacity(0.34 + energy * 0.12)),
        style: StrokeStyle(lineWidth: 0.9 + energy * 0.6, lineCap: .round)
      )

      for index in 2..<19 {
        let fraction = Double(index) / 20
        let bodyPoint = dragonPoint(center: center, unit: unit, fraction: fraction)
        let normalAngle = dragonTangentAngle(fraction: fraction) + Double.pi / 2
        let normal = CGPoint(x: cos(normalAngle), y: sin(normalAngle))
        let radial = CGPoint(x: bodyPoint.x - center.x, y: bodyPoint.y - center.y)
        let direction: CGFloat = radial.x * normal.x + radial.y * normal.y >= 0 ? 1 : -1
        let outward = CGPoint(x: normal.x * direction, y: normal.y * direction)
        let inner = CGPoint(
          x: bodyPoint.x - outward.x * unit * 0.021,
          y: bodyPoint.y - outward.y * unit * 0.021
        )
        let outer = CGPoint(
          x: bodyPoint.x + outward.x * unit * 0.021,
          y: bodyPoint.y + outward.y * unit * 0.021
        )
        var scaleBand = Path()
        scaleBand.move(to: inner)
        scaleBand.addQuadCurve(
          to: outer,
          control: bodyPoint
        )
        context.stroke(
          scaleBand,
          with: .color(Color(red: 0.42, green: 0.01, blue: 0.004).opacity(0.72)),
          style: StrokeStyle(lineWidth: 0.75, lineCap: .round)
        )

        if index.isMultiple(of: 2) {
          var spine = Path()
          spine.move(to: outer)
          spine.addLine(
            to: CGPoint(
              x: bodyPoint.x + outward.x * unit * (0.047 + CGFloat(index % 3) * 0.008),
              y: bodyPoint.y + outward.y * unit * (0.047 + CGFloat(index % 3) * 0.008)
            )
          )
          context.stroke(
            spine,
            with: .color(Color.orange.opacity(0.78)),
            style: StrokeStyle(lineWidth: 1.3, lineCap: .round)
          )
        }
      }

      let tailCenter = dragonPoint(center: center, unit: unit, fraction: 0)
      let tailFlame = dragonTailFlamePath(
        center: tailCenter,
        scale: unit * 0.12,
        angle: dragonTangentAngle(fraction: 0) + .pi
      )
      context.fill(
        tailFlame,
        with: .linearGradient(
          Gradient(colors: [Color.white, Color.yellow, Color.orange, Color.red.opacity(0.1)]),
          startPoint: tailCenter,
          endPoint: CGPoint(x: tailCenter.x - unit * 0.14, y: tailCenter.y)
        )
      )

      for fraction in [0.22, 0.4, 0.61, 0.78] {
        let claw = dragonClawPath(center: center, unit: unit, fraction: fraction)
        var clawGlow = context
        clawGlow.addFilter(.blur(radius: 3.5))
        clawGlow.stroke(
          claw,
          with: .color(Color.orange.opacity(0.52)),
          style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
          claw,
          with: .color(Color(red: 0.42, green: 0.008, blue: 0.003).opacity(0.98)),
          style: StrokeStyle(lineWidth: 6.4, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
          claw,
          with: .color(Color.yellow.opacity(0.92)),
          style: StrokeStyle(lineWidth: 1.45, lineCap: .round, lineJoin: .round)
        )
      }

      let headCenter = dragonPoint(center: center, unit: unit, fraction: 1)
      let headAngle = dragonTangentAngle(fraction: 1) + sin(time * 1.7) * 0.065
      let headScale = unit * (0.225 + sin(time * 1.25) * 0.008)
      let mane = dragonManePath(center: headCenter, scale: headScale, angle: headAngle)
      var maneGlow = context
      maneGlow.addFilter(.blur(radius: 7 + energy * 4))
      maneGlow.fill(mane, with: .color(Color.orange.opacity(0.58)))
      context.fill(
        mane,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.42, green: 0.006, blue: 0.003),
            Color.orange,
            Color(red: 0.22, green: 0.002, blue: 0.001),
          ]),
          startPoint: CGPoint(x: headCenter.x, y: headCenter.y - headScale),
          endPoint: CGPoint(x: headCenter.x - headScale, y: headCenter.y + headScale)
        )
      )
      let head = dragonHeadPath(
        center: headCenter,
        scale: headScale,
        angle: headAngle
      )
      var headGlow = context
      headGlow.addFilter(.blur(radius: 8 + energy * 5))
      headGlow.fill(head, with: .color(Color.orange.opacity(0.72)))
      context.fill(
        head,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.95, green: 0.2, blue: 0.01),
            Color.orange,
            Color(red: 0.48, green: 0.008, blue: 0.003),
          ]
          ),
          startPoint: CGPoint(x: headCenter.x - unit * 0.08, y: headCenter.y),
          endPoint: CGPoint(x: headCenter.x + unit * 0.08, y: headCenter.y)
        )
      )
      context.stroke(
        head,
        with: .color(Color(red: 0.34, green: 0.006, blue: 0.002).opacity(0.9)),
        style: StrokeStyle(lineWidth: 1.7, lineJoin: .round)
      )
      var hornGlow = context
      hornGlow.addFilter(.blur(radius: 5))
      hornGlow.stroke(
        dragonHornPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color.orange.opacity(0.56)),
        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonHornPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .linearGradient(
          Gradient(colors: [Color(red: 0.56, green: 0.2, blue: 0.03), Color.yellow, Color.white]),
          startPoint: CGPoint(x: headCenter.x - headScale, y: headCenter.y),
          endPoint: CGPoint(x: headCenter.x + headScale, y: headCenter.y - headScale)
        ),
        style: StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonHeadDetails(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color(red: 0.28, green: 0.004, blue: 0.002).opacity(0.96)),
        style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonWhiskerPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color(red: 1, green: 0.9, blue: 0.46).opacity(0.96)),
        style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round)
      )
      context.stroke(
        dragonFangPath(center: headCenter, scale: headScale, angle: headAngle),
        with: .color(Color.white.opacity(0.96)),
        style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
      )
      let eye = transform(
        point: CGPoint(x: 0.13, y: -0.055),
        center: headCenter,
        scale: headScale,
        angle: headAngle
      )
      let eyeRect = CGRect(x: eye.x - 2.8, y: eye.y - 2.8, width: 5.6, height: 5.6)
      context.fill(
        Path(ellipseIn: eyeRect), with: .color(Color(red: 0.08, green: 0.16, blue: 0.18)))
      context.fill(
        Path(ellipseIn: eyeRect.insetBy(dx: 1, dy: 1)),
        with: .color(Color(red: 0.88, green: 1, blue: 0.78).opacity(0.98))
      )

      for index in 0..<18 {
        let seed = Double(index + 1)
        let angle = seed * 2.17 + time * (index.isMultiple(of: 2) ? 0.44 : -0.31)
        let radius = unit * CGFloat(0.29 + seed.truncatingRemainder(dividingBy: 5) * 0.027)
        let spark = CGPoint(
          x: center.x + cos(angle) * radius,
          y: center.y + sin(angle) * radius
        )
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: spark.x - CGFloat(index.isMultiple(of: 4) ? 1.5 : 0.7),
              y: spark.y - CGFloat(index.isMultiple(of: 4) ? 1.5 : 0.7),
              width: CGFloat(index.isMultiple(of: 4) ? 3 : 1.4),
              height: CGFloat(index.isMultiple(of: 4) ? 3 : 1.4)
            )
          ),
          with: .color(
            (index.isMultiple(of: 4) ? Color.white : Color.orange)
              .opacity(0.42 + energy * 0.18)
          )
        )
      }
    }
    .frame(width: diameter, height: diameter)
    .scaleEffect(0.98 + sin(time * 1.6) * 0.018 + energy * 0.025)
  }

  private func dragonBodyPath(center: CGPoint, unit: CGFloat) -> Path {
    Path { path in
      for index in 0...96 {
        let fraction = Double(index) / 96
        let point = dragonPoint(center: center, unit: unit, fraction: fraction)
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
    }
  }

  private func dragonPoint(center: CGPoint, unit: CGFloat, fraction: Double) -> CGPoint {
    let point = normalizedDragonPoint(fraction: fraction)
    let orbitAngle = dragonOrbitAngle
    let orbitScale = 0.96 + sin(time * 0.74) * 0.035
    let flightX = cos(time * 0.47) * unit * 0.018
    let flightY = sin(time * 0.61) * unit * 0.026
    return CGPoint(
      x: center.x + flightX
        + (point.x * cos(orbitAngle) - point.y * sin(orbitAngle)) * unit * orbitScale,
      y: center.y + flightY
        + (point.x * sin(orbitAngle) + point.y * cos(orbitAngle)) * unit * orbitScale
    )
  }

  private var dragonOrbitAngle: Double {
    time * 0.15 + sin(time * 0.72) * 0.09
  }

  private func normalizedDragonPoint(fraction: Double) -> CGPoint {
    let sway = CGFloat(sin(time * 0.62)) * 0.008
    let points = [
      CGPoint(x: -0.4, y: 0.31),
      CGPoint(x: -0.43, y: 0.08),
      CGPoint(x: -0.29, y: -0.26),
      CGPoint(x: 0.02 + sway, y: -0.34),
      CGPoint(x: 0.3, y: -0.18),
      CGPoint(x: 0.31, y: 0.1),
      CGPoint(x: 0.08 - sway, y: 0.27),
      CGPoint(x: -0.14, y: 0.13),
      CGPoint(x: -0.04, y: -0.08),
      CGPoint(x: 0.21, y: -0.17),
      CGPoint(x: 0.39, y: -0.31),
    ]
    let clamped = max(0, min(1, fraction))
    let progress = clamped * Double(points.count - 1)
    let index = min(Int(progress), points.count - 2)
    let local = CGFloat(progress - Double(index))
    let p0 = points[max(index - 1, 0)]
    let p1 = points[index]
    let p2 = points[index + 1]
    let p3 = points[min(index + 2, points.count - 1)]
    let base = catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: local)
    let wave = sin(time * 2.05 - fraction * 11.5) * (0.026 - fraction * 0.009)
    return CGPoint(
      x: base.x + cos(time * 1.3 - fraction * 7.2) * 0.008,
      y: base.y + wave
    )
  }

  private func catmullRom(
    p0: CGPoint,
    p1: CGPoint,
    p2: CGPoint,
    p3: CGPoint,
    t: CGFloat
  ) -> CGPoint {
    let t2 = t * t
    let t3 = t2 * t
    let x =
      0.5
      * ((2 * p1.x) + (-p0.x + p2.x) * t
        + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2
        + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3)
    let y =
      0.5
      * ((2 * p1.y) + (-p0.y + p2.y) * t
        + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
        + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3)
    return CGPoint(x: x, y: y)
  }

  private func dragonTangentAngle(fraction: Double) -> Double {
    let start = normalizedDragonPoint(fraction: max(0, fraction - 0.006))
    let end = normalizedDragonPoint(fraction: min(1, fraction + 0.006))
    return atan2(end.y - start.y, end.x - start.x) + dragonOrbitAngle
  }

  private func naturalFlamePath(
    base: CGPoint,
    width: CGFloat,
    height: CGFloat,
    phase: Double
  ) -> Path {
    let drift = CGFloat(sin(phase)) * width * 0.38
    let notch = CGFloat(cos(phase * 0.73)) * width * 0.16
    return Path { path in
      path.move(to: CGPoint(x: base.x - width / 2, y: base.y))
      path.addCurve(
        to: CGPoint(x: base.x - width * 0.18 + notch, y: base.y - height * 0.46),
        control1: CGPoint(x: base.x - width * 0.64, y: base.y - height * 0.16),
        control2: CGPoint(x: base.x - width * 0.42, y: base.y - height * 0.38)
      )
      path.addCurve(
        to: CGPoint(x: base.x + drift, y: base.y - height),
        control1: CGPoint(x: base.x - width * 0.06, y: base.y - height * 0.68),
        control2: CGPoint(x: base.x + drift - width * 0.2, y: base.y - height * 0.88)
      )
      path.addCurve(
        to: CGPoint(x: base.x + width * 0.2 - notch, y: base.y - height * 0.38),
        control1: CGPoint(x: base.x + drift + width * 0.24, y: base.y - height * 0.82),
        control2: CGPoint(x: base.x + width * 0.36, y: base.y - height * 0.58)
      )
      path.addCurve(
        to: CGPoint(x: base.x + width / 2, y: base.y),
        control1: CGPoint(x: base.x + width * 0.48, y: base.y - height * 0.24),
        control2: CGPoint(x: base.x + width * 0.64, y: base.y - height * 0.12)
      )
      path.closeSubpath()
    }
  }

  private func dragonManePath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let flutter = CGFloat(sin(time * 2.35)) * 0.08
    let points = [
      CGPoint(x: -0.58, y: 0.3), CGPoint(x: -0.7, y: 0.02),
      CGPoint(x: -1.02 - flutter, y: -0.16), CGPoint(x: -0.72, y: -0.34),
      CGPoint(x: -0.92 + flutter, y: -0.68), CGPoint(x: -0.48, y: -0.58),
      CGPoint(x: -0.26, y: -0.32), CGPoint(x: 0.08, y: 0.08),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() { path.addLine(to: point) }
      path.closeSubpath()
    }
  }

  private func dragonTailFlamePath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let points = [
      CGPoint(x: 0.12, y: 0), CGPoint(x: -0.18, y: -0.24),
      CGPoint(x: -0.82, y: -0.06), CGPoint(x: -0.42, y: 0.13),
      CGPoint(x: -0.7, y: 0.42), CGPoint(x: -0.08, y: 0.2),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() { path.addLine(to: point) }
      path.closeSubpath()
    }
  }

  private func dragonHeadPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    let points = [
      CGPoint(x: -0.62, y: 0.18),
      CGPoint(x: -0.28, y: -0.15),
      CGPoint(x: 0.18, y: -0.18),
      CGPoint(x: 0.5, y: -0.04),
      CGPoint(x: 0.72, y: 0.06),
      CGPoint(x: 0.5, y: 0.18),
      CGPoint(x: 0.7, y: 0.4),
      CGPoint(x: 0.24, y: 0.31),
      CGPoint(x: 0.02, y: 0.58),
      CGPoint(x: -0.22, y: 0.27),
    ].map { transform(point: $0, center: center, scale: scale, angle: angle) }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() {
        path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func dragonHeadDetails(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(-0.08, -0.05))
      path.addLine(to: point(0.24, -0.03))
      path.addLine(to: point(0.08, 0.08))

      path.move(to: point(0.18, 0.22))
      path.addCurve(
        to: point(0.68, 0.17),
        control1: point(0.36, 0.28),
        control2: point(0.54, 0.17)
      )

      path.move(to: point(-0.52, 0.16))
      path.addCurve(
        to: point(0.08, 0.46),
        control1: point(-0.32, 0.42),
        control2: point(-0.06, 0.18)
      )
    }
  }

  private func dragonHornPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(-0.3, -0.1))
      path.addCurve(
        to: point(-0.6, -0.88),
        control1: point(-0.5, -0.36),
        control2: point(-0.72, -0.68)
      )
      path.addLine(to: point(-0.38, -0.72))

      path.move(to: point(0.0, -0.15))
      path.addCurve(
        to: point(0.22, -0.9),
        control1: point(-0.02, -0.44),
        control2: point(0.08, -0.76)
      )
      path.addLine(to: point(0.36, -0.68))
    }
  }

  private func dragonWhiskerPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(0.43, 0.1))
      path.addCurve(
        to: point(1.36, -0.15),
        control1: point(0.76, -0.08),
        control2: point(1.02, 0.1)
      )
      path.move(to: point(0.4, 0.24))
      path.addCurve(
        to: point(1.25, 0.64),
        control1: point(0.7, 0.48),
        control2: point(0.98, 0.34)
      )
    }
  }

  private func dragonFangPath(center: CGPoint, scale: CGFloat, angle: Double) -> Path {
    Path { path in
      func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        transform(point: CGPoint(x: x, y: y), center: center, scale: scale, angle: angle)
      }

      path.move(to: point(0.35, 0.14))
      path.addLine(to: point(0.42, 0.34))
      path.move(to: point(0.54, 0.15))
      path.addLine(to: point(0.58, 0.3))
    }
  }

  private func dragonClawPath(center: CGPoint, unit: CGFloat, fraction: Double) -> Path {
    let base = dragonPoint(center: center, unit: unit, fraction: fraction)
    let tangentAngle = dragonTangentAngle(fraction: fraction)
    let tangent = CGPoint(x: cos(tangentAngle), y: sin(tangentAngle))
    var outward = CGPoint(x: -tangent.y, y: tangent.x)
    let radial = CGPoint(x: base.x - center.x, y: base.y - center.y)
    if radial.x * outward.x + radial.y * outward.y < 0 {
      outward = CGPoint(x: -outward.x, y: -outward.y)
    }
    let flex = CGFloat(sin(time * 2.2 + fraction * 12))
    let reach = unit * (0.068 + flex * 0.009)
    let elbow = CGPoint(
      x: base.x + outward.x * reach + tangent.x * unit * (0.018 + flex * 0.006),
      y: base.y + outward.y * reach + tangent.y * unit * (0.018 + flex * 0.006)
    )
    let palm = CGPoint(
      x: elbow.x + outward.x * unit * 0.052 - tangent.x * unit * 0.03,
      y: elbow.y + outward.y * unit * 0.052 - tangent.y * unit * 0.03
    )

    return Path { path in
      path.move(to: base)
      path.addQuadCurve(to: palm, control: elbow)
      for toe in -1...1 {
        path.move(to: palm)
        path.addLine(
          to: CGPoint(
            x: palm.x + outward.x * unit * 0.042 + tangent.x * CGFloat(toe) * unit * 0.025,
            y: palm.y + outward.y * unit * 0.042 + tangent.y * CGFloat(toe) * unit * 0.025
          )
        )
      }
    }
  }

  nonisolated private func transform(
    point: CGPoint,
    center: CGPoint,
    scale: CGFloat,
    angle: Double
  ) -> CGPoint {
    CGPoint(
      x: center.x + (point.x * cos(angle) - point.y * sin(angle)) * scale,
      y: center.y + (point.x * sin(angle) + point.y * cos(angle)) * scale
    )
  }
}

private struct EarthSealFormation: View {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let color: Color

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = min(size.width, size.height) * 0.46
      let sealRect = CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
      )
      let seal = Path(ellipseIn: sealRect)
      var terrain = context
      terrain.clip(to: seal)

      let mainRect = CGRect(
        x: sealRect.minX,
        y: sealRect.minY + radius * 0.42,
        width: sealRect.width,
        height: radius * 1.32
      )
      let mainRidge = earthRidge(in: mainRect, seed: 2, closesAtBottom: true)
      terrain.fill(
        mainRidge,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.88, green: 0.63, blue: 0.36).opacity(0.58 + energy * 0.12),
            color.opacity(0.62),
            Color(red: 0.16, green: 0.07, blue: 0.025).opacity(0.9),
          ]),
          startPoint: CGPoint(x: center.x, y: mainRect.minY),
          endPoint: CGPoint(x: center.x, y: mainRect.maxY)
        )
      )

      for ridge in 0..<3 {
        let ridgeRect = CGRect(
          x: sealRect.minX - CGFloat(ridge) * radius * 0.035,
          y: sealRect.minY + radius * (0.34 + CGFloat(ridge) * 0.24),
          width: sealRect.width + CGFloat(ridge) * radius * 0.07,
          height: radius * (0.82 + CGFloat(ridge) * 0.12)
        )
        let path = earthRidge(in: ridgeRect, seed: 7 + ridge * 5, closesAtBottom: false)
        var glow = terrain
        glow.addFilter(.blur(radius: 3 + CGFloat(ridge)))
        glow.stroke(
          path,
          with: .color(color.opacity((0.16 + Double(2 - ridge) * 0.06) + energy * 0.08)),
          lineWidth: 5 - CGFloat(ridge)
        )
        terrain.stroke(
          path,
          with: .color(
            (ridge == 0 ? Color.white : color)
              .opacity(0.34 - Double(ridge) * 0.06 + energy * 0.14)
          ),
          style: StrokeStyle(
            lineWidth: 1.15 + CGFloat(2 - ridge) * 0.32,
            lineCap: .round,
            lineJoin: .round
          )
        )
      }

      for index in 0..<7 {
        let angle = Double(index) * .pi / 6 + .pi
        let edge = CGPoint(
          x: center.x + cos(angle) * radius,
          y: center.y + sin(angle) * radius
        )
        let anchorOffset = CGFloat(abs(index - 3))
        let anchor = CGPoint(
          x: center.x + CGFloat(index - 3) * radius * 0.16,
          y: center.y + radius * (0.1 + anchorOffset * 0.035)
        )
        var meridian = Path()
        meridian.move(to: edge)
        meridian.addLine(to: anchor)
        context.stroke(
          meridian,
          with: .color(color.opacity(0.12 + energy * 0.1)),
          style: StrokeStyle(lineWidth: index.isMultiple(of: 3) ? 1.1 : 0.55, dash: [4, 5])
        )
      }

      context.stroke(
        seal,
        with: .color(color.opacity(0.42 + energy * 0.2)),
        style: StrokeStyle(lineWidth: 1.35 + energy, dash: [8, 4, 2, 4])
      )
      context.stroke(
        Path(ellipseIn: sealRect.insetBy(dx: radius * 0.1, dy: radius * 0.1)),
        with: .color(Color.white.opacity(0.16 + energy * 0.12)),
        lineWidth: 0.65
      )
    }
    .frame(width: diameter, height: diameter)
    .rotationEffect(.degrees(sin(time * 0.45) * 0.5))
  }

  private func earthRidge(in rect: CGRect, seed: Int, closesAtBottom: Bool) -> Path {
    Path { path in
      let pointCount = 14
      if closesAtBottom {
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      }
      for index in 0...pointCount {
        let fraction = CGFloat(index) / CGFloat(pointCount)
        let x = rect.minX + rect.width * fraction
        let hash = abs(sin(Double((index + 3) * (seed + 5)) * 1.73))
        let accent = (index + seed) % 6 == 0 ? 0.22 : 0
        let height = min(0.82, 0.16 + hash * 0.43 + accent)
        let y = rect.maxY - rect.height * CGFloat(height)
        if index == 0 && !closesAtBottom {
          path.move(to: CGPoint(x: x, y: y))
        } else {
          path.addLine(to: CGPoint(x: x, y: y))
        }
      }
      if closesAtBottom {
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
      }
    }
  }
}

private struct WaterTideFormation: View {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let color: Color

  var body: some View {
    Canvas { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = min(size.width, size.height) * 0.46
      let sealRect = CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
      )
      let seal = Path(ellipseIn: sealRect)
      var tide = context
      tide.clip(to: seal)

      for band in 0..<4 {
        let waveRect = CGRect(
          x: sealRect.minX - radius * 0.06,
          y: center.y - radius * 0.08 + CGFloat(band) * radius * 0.17,
          width: sealRect.width + radius * 0.12,
          height: radius * 0.88
        )
        let wavePhase = time * (1.05 + Double(band) * 0.14) + Double(band) * 0.8
        let wave = tideWave(
          in: waveRect,
          phase: wavePhase,
          closesAtBottom: true
        )
        tide.fill(
          wave,
          with: .linearGradient(
            Gradient(colors: [
              Color.white.opacity((0.12 - Double(band) * 0.018) + energy * 0.05),
              color.opacity(0.2 + Double(band) * 0.055),
              Color(red: 0.015, green: 0.08, blue: 0.2).opacity(0.54),
            ]),
            startPoint: CGPoint(x: center.x, y: waveRect.minY),
            endPoint: CGPoint(x: center.x, y: waveRect.maxY)
          )
        )
        tide.stroke(
          tideWave(
            in: waveRect,
            phase: wavePhase,
            closesAtBottom: false
          ),
          with: .color(
            (band == 0 ? Color.white : color)
              .opacity(0.42 - Double(band) * 0.06 + energy * 0.12)
          ),
          style: StrokeStyle(
            lineWidth: 1.45 - CGFloat(band) * 0.17,
            lineCap: .round,
            lineJoin: .round
          )
        )

        let foam = tideFoam(in: waveRect, phase: wavePhase)
        var foamGlow = tide
        foamGlow.addFilter(.blur(radius: 3 + CGFloat(band)))
        foamGlow.stroke(
          foam,
          with: .color(Color.white.opacity(0.24 + energy * 0.12)),
          style: StrokeStyle(lineWidth: 4 + CGFloat(band), lineCap: .round)
        )
        tide.stroke(
          foam,
          with: .color(Color.white.opacity(0.58 - Double(band) * 0.065 + energy * 0.1)),
          style: StrokeStyle(lineWidth: 0.85, lineCap: .round, lineJoin: .round)
        )
      }

      for index in 0..<22 {
        let seed = Double(index + 1)
        let x =
          sealRect.minX + sealRect.width
          * CGFloat(
            abs(sin(seed * 9.73)).truncatingRemainder(dividingBy: 1)
          )
        let travel = (time * (58 + seed.truncatingRemainder(dividingBy: 31)) + seed * 13)
          .truncatingRemainder(dividingBy: Double(radius * 1.08))
        let y = sealRect.minY + CGFloat(travel)
        let length = radius * CGFloat(0.055 + seed.truncatingRemainder(dividingBy: 4) * 0.012)
        var rain = Path()
        rain.move(to: CGPoint(x: x, y: y))
        rain.addLine(to: CGPoint(x: x - length * 0.12, y: y + length))
        tide.stroke(
          rain,
          with: .color(
            (index.isMultiple(of: 5) ? Color.white : color)
              .opacity(0.22 + Double(index % 4) * 0.055 + energy * 0.08)
          ),
          style: StrokeStyle(lineWidth: index.isMultiple(of: 5) ? 1.25 : 0.62, lineCap: .round)
        )
      }

      for index in 0..<6 {
        let phase = (time * 0.72 + Double(index) * 0.19).truncatingRemainder(dividingBy: 1)
        let rippleRadius = radius * CGFloat(0.06 + phase * 0.16)
        let x = center.x + sin(Double(index) * 2.34) * radius * 0.54
        let y = center.y + radius * CGFloat(0.28 + Double(index % 3) * 0.12)
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: x - rippleRadius,
              y: y - rippleRadius * 0.2,
              width: rippleRadius * 2,
              height: rippleRadius * 0.4
            )
          ),
          with: .color(color.opacity((1 - phase) * (0.28 + energy * 0.12))),
          lineWidth: 0.75
        )
      }

      context.stroke(
        seal,
        with: .color(color.opacity(0.46 + energy * 0.2)),
        style: StrokeStyle(lineWidth: 1.35 + energy, dash: [10, 4, 2, 4])
      )
      context.stroke(
        Path(ellipseIn: sealRect.insetBy(dx: radius * 0.11, dy: radius * 0.11)),
        with: .color(Color.white.opacity(0.18 + energy * 0.12)),
        lineWidth: 0.65
      )
    }
    .frame(width: diameter, height: diameter)
    .shadow(color: color.opacity(0.5), radius: 7 + energy * 7)
  }

  private func tideWave(in rect: CGRect, phase: Double, closesAtBottom: Bool) -> Path {
    Path { path in
      if closesAtBottom {
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      }
      for index in 0...64 {
        let fraction = CGFloat(index) / 64
        let primary = sin(Double(fraction) * .pi * 2.35 - phase)
        let chop = sin(Double(fraction) * .pi * 5.7 - phase * 1.45) * 0.17
        let crest = max(0, primary) * 0.12
        let y = rect.minY + rect.height * CGFloat(0.37 - primary * 0.16 - chop - crest)
        let point = CGPoint(x: rect.minX + rect.width * fraction, y: y)
        if index == 0 && !closesAtBottom {
          path.move(to: point)
        } else {
          path.addLine(to: point)
        }
      }
      if closesAtBottom {
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
      }
    }
  }

  private func tideFoam(in rect: CGRect, phase: Double) -> Path {
    Path { path in
      var drawing = false
      for index in 0...64 {
        let fraction = CGFloat(index) / 64
        let primary = sin(Double(fraction) * .pi * 2.35 - phase)
        let chop = sin(Double(fraction) * .pi * 5.7 - phase * 1.45) * 0.17
        let crest = max(0, primary) * 0.12
        let point = CGPoint(
          x: rect.minX + rect.width * fraction,
          y: rect.minY + rect.height * CGFloat(0.37 - primary * 0.16 - chop - crest)
        )
        guard primary > 0.42 else {
          drawing = false
          continue
        }
        drawing ? path.addLine(to: point) : path.move(to: point)
        drawing = true
      }
    }
  }
}
