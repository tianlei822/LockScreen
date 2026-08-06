import LockScreenCore
import SwiftUI

struct FormationDoorArtwork: View {
  let energy: Double
  let isActivated: Bool

  private let ink = Color(red: 0.008, green: 0.025, blue: 0.048)
  private let cyan = Color(red: 0.18, green: 0.91, blue: 0.84)
  private let jade = Color(red: 0.52, green: 0.95, blue: 0.71)
  private let gold = Color(red: 1.0, green: 0.82, blue: 0.45)

  /// Eight trigrams used as the outer formation eyes (阵眼).
  private let trigrams = ["☰", "☱", "☲", "☳", "☴", "☵", "☶", "☷"]

  @State private var activationStart: TimeInterval?

  var body: some View {
    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
      GeometryReader { proxy in
        let size = proxy.size
        let time = timeline.date.timeIntervalSinceReferenceDate
        let diameter = min(size.width, size.height) * 0.78
        let level = max(0, min(1, energy))
        let speed = isActivated ? 3.8 : 1 + level * 1.8
        let pulse = 1 + sin(time * 1.5 * speed) * (0.012 + level * 0.018)
        let activationAge = activationStart.map { time - $0 }

        ZStack {
          LinearGradient(
            colors: [ink, Color(red: 0.018, green: 0.12, blue: 0.15), ink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )

          vignette(size: size)

          godRays(diameter: diameter, time: time, level: level)

          formationLattice(size: size, time: time)

          polarLattice(size: size, diameter: diameter)

          groundGlow(diameter: diameter, level: level, time: time)

          // Concentric rings ignite from the outside in as aether charge grows.
          ring(
            diameter: diameter, dash: [2, 10], lineWidth: 1.2,
            brightness: ignition(level: level, index: 0, of: 4)
          )
          .rotationEffect(.degrees(time * 14 * speed))

          ring(
            diameter: diameter * 0.74, dash: [20, 7, 3, 7], lineWidth: 1.8,
            brightness: ignition(level: level, index: 1, of: 4)
          )
          .rotationEffect(.degrees(-time * 22 * speed))

          ring(
            diameter: diameter * 0.52, dash: [], lineWidth: 0.8,
            brightness: ignition(level: level, index: 2, of: 4)
          )
          .rotationEffect(.degrees(-time * 7 * speed))

          ring(
            diameter: diameter * 0.4, dash: [12, 5], lineWidth: 1,
            brightness: ignition(level: level, index: 3, of: 4)
          )
          .rotationEffect(.degrees(time * 17 * speed))

          trigramBand(diameter: diameter * 0.93, time: time, level: level)

          radialTicks(diameter: diameter * 0.845)
            .rotationEffect(.degrees(time * 4 * speed))

          chargeArc(diameter: diameter * 0.8, level: level)

          FormationPolygon(sides: 8)
            .stroke(
              cyan.opacity(0.30 + 0.32 * level), style: StrokeStyle(lineWidth: 1, dash: [5, 7])
            )
            .frame(width: diameter * 0.64, height: diameter * 0.64)
            .rotationEffect(.degrees(time * 9 * speed))

          FormationPolygon(sides: 3)
            .stroke(jade.opacity(0.34 + 0.3 * level), lineWidth: 1.5)
            .frame(width: diameter * 0.48, height: diameter * 0.48)
            .rotationEffect(.degrees(-time * 15 * speed))

          FormationPolygon(sides: 6)
            .stroke(cyan.opacity(0.18 + level * 0.45), lineWidth: 1)
            .frame(width: diameter * 0.34, height: diameter * 0.34)
            .rotationEffect(.degrees(time * 21 * speed))

          starMap(diameter: diameter * 0.58, time: time, level: level)
            .rotationEffect(.degrees(time * 5 * speed))

          sweepArc(diameter: diameter * 0.62, time: time * speed, speed: 40, span: 0.16, tint: cyan)
          sweepArc(
            diameter: diameter * 0.44, time: time * speed, speed: -28, span: 0.12, tint: jade)

          runeOrbit(diameter: diameter * 0.68, time: time, level: level)

          orbitingNodes(diameter: diameter * 0.57, time: time * speed, level: level)

          risingParticles(size: size, diameter: diameter, time: time, level: level)

          centerCore(
            diameter: diameter, time: time, level: level, speed: speed, activationAge: activationAge
          )

          doorSeam(level: level)

          if let activationAge, activationAge < 2.2 {
            activationFX(diameter: diameter, size: size, age: activationAge)
          }

          cornerMarks(size: size)
        }
        .scaleEffect(pulse)
        .onChange(of: isActivated) {
          activationStart = isActivated ? Date().timeIntervalSinceReferenceDate : nil
        }
      }
    }
  }

  // MARK: - Background layers

  private func vignette(size: CGSize) -> some View {
    RadialGradient(
      colors: [.clear, ink.opacity(0.82)],
      center: .center,
      startRadius: min(size.width, size.height) * 0.34,
      endRadius: max(size.width, size.height) * 0.72
    )
  }

  private func godRays(diameter: CGFloat, time: TimeInterval, level: Double) -> some View {
    ZStack {
      ForEach(0..<8, id: \.self) { index in
        Capsule()
          .fill(
            LinearGradient(
              colors: [cyan.opacity(0), cyan.opacity(0.08 + level * 0.1), cyan.opacity(0)],
              startPoint: .bottom,
              endPoint: .top
            )
          )
          .frame(width: 24, height: diameter * 0.6)
          .offset(y: -diameter * 0.3)
          .rotationEffect(.degrees(Double(index) * 45 + sin(time * 0.5 + Double(index)) * 3))
      }
    }
    .blur(radius: 12)
    .rotationEffect(.degrees(time * 2.2))
    .blendMode(.plusLighter)
  }

  private func groundGlow(diameter: CGFloat, level: Double, time: TimeInterval) -> some View {
    Circle()
      .fill(
        RadialGradient(
          colors: [cyan.opacity(0.10 + level * 0.12), cyan.opacity(0.04), .clear],
          center: .center,
          startRadius: 0,
          endRadius: diameter * 0.52
        )
      )
      .frame(width: diameter * 1.04, height: diameter * 1.04)
      .scaleEffect(1 + sin(time * 1.1) * 0.03)
      .blur(radius: 10)
      .blendMode(.plusLighter)
  }

  private func formationLattice(size: CGSize, time: TimeInterval) -> some View {
    Canvas { context, _ in
      let spacing: CGFloat = 34
      let drift = CGFloat(time.truncatingRemainder(dividingBy: 3)) * 3

      for x in stride(from: -size.height, through: size.width + size.height, by: spacing) {
        var forward = Path()
        forward.move(to: CGPoint(x: x + drift, y: 0))
        forward.addLine(to: CGPoint(x: x - size.height + drift, y: size.height))
        context.stroke(forward, with: .color(cyan.opacity(0.045)), lineWidth: 0.6)

        var backward = Path()
        backward.move(to: CGPoint(x: x - drift, y: 0))
        backward.addLine(to: CGPoint(x: x + size.height - drift, y: size.height))
        context.stroke(backward, with: .color(jade.opacity(0.03)), lineWidth: 0.6)
      }
    }
  }

  /// Concentric guide circles with radial spokes, like the engraved base of an array disc.
  private func polarLattice(size: CGSize, diameter: CGFloat) -> some View {
    Canvas { context, _ in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)

      for step in 1...6 {
        let radius = diameter * 0.5 * CGFloat(step) / 6
        let rect = CGRect(
          x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(
          Path(ellipseIn: rect),
          with: .color(cyan.opacity(step.isMultiple(of: 2) ? 0.055 : 0.035)),
          lineWidth: 0.5
        )
      }

      for index in 0..<24 {
        let angle = Double(index) * .pi / 12
        var path = Path()
        path.move(
          to: CGPoint(
            x: center.x + cos(angle) * diameter * 0.08,
            y: center.y + sin(angle) * diameter * 0.08
          ))
        path.addLine(
          to: CGPoint(
            x: center.x + cos(angle) * diameter * 0.5,
            y: center.y + sin(angle) * diameter * 0.5
          ))
        context.stroke(
          path,
          with: .color(cyan.opacity(index.isMultiple(of: 3) ? 0.09 : 0.04)),
          lineWidth: index.isMultiple(of: 3) ? 0.8 : 0.5
        )
      }
    }
  }

  // MARK: - Rings and charge

  /// Staggered ignition: ring `index` lights up only after the rings outside it.
  private func ignition(level: Double, index: Int, of total: Int) -> Double {
    max(0, min(1, level * Double(total) - Double(index)))
  }

  private func ring(diameter: CGFloat, dash: [CGFloat], lineWidth: CGFloat, brightness: Double)
    -> some View
  {
    Circle()
      .trim(from: 0.035, to: 0.965)
      .stroke(
        AngularGradient(
          colors: [cyan.opacity(0.18), cyan, jade, cyan.opacity(0.18)],
          center: .center
        ),
        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: dash)
      )
      .frame(width: diameter, height: diameter)
      .opacity(0.3 + 0.7 * brightness)
  }

  private func chargeArc(diameter: CGFloat, level: Double) -> some View {
    ZStack {
      Circle()
        .trim(from: 0.01, to: max(0.012, CGFloat(level)))
        .stroke(
          AngularGradient(colors: [cyan, jade, .white, cyan], center: .center),
          style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .shadow(color: cyan.opacity(0.65 + level * 0.3), radius: 8 + level * 12)

      if level > 0.02 {
        Circle()
          .fill(Color.white)
          .frame(width: 6 + level * 3, height: 6 + level * 3)
          .shadow(color: jade, radius: 8)
          .offset(y: -diameter / 2)
          .rotationEffect(.degrees(level * 360))
          .blendMode(.plusLighter)
      }
    }
    .frame(width: diameter, height: diameter)
  }

  // MARK: - Formation eyes and runes

  /// Eight trigram formation eyes; they light one after another as charge rises.
  private func trigramBand(diameter: CGFloat, time: TimeInterval, level: Double) -> some View {
    ZStack {
      ForEach(0..<8, id: \.self) { index in
        let angle = Double(index) * 45 + time * 6
        let lit = isActivated || level >= Double(index + 1) / 8.5
        let chase = 0.5 + 0.5 * sin(time * 2.4 - Double(index) * (.pi / 4))

        Text(trigrams[index])
          .font(.system(size: diameter * 0.056, weight: .light))
          .foregroundStyle(lit ? Color.white : cyan.opacity(0.3 + chase * 0.42))
          .shadow(
            color: (isActivated && lit ? gold : lit ? jade : cyan).opacity(
              lit ? 0.95 : 0.3 + chase * 0.3),
            radius: lit ? 11 : 5
          )
          .scaleEffect(lit ? 1.18 : 1)
          .rotationEffect(.degrees(-angle))
          .offset(y: -diameter / 2)
          .rotationEffect(.degrees(angle))
      }
    }
    .frame(width: diameter, height: diameter)
  }

  private func runeOrbit(diameter: CGFloat, time: TimeInterval, level: Double) -> some View {
    ZStack {
      ForEach(0..<12, id: \.self) { index in
        let angle = Double(index) * 30 + time * 11

        Text(Rune.allCases[index % Rune.allCases.count].symbol)
          .font(.system(size: 14, weight: .light, design: .monospaced))
          .foregroundStyle(index.isMultiple(of: 3) ? jade : cyan.opacity(0.5 + level * 0.3))
          .shadow(color: cyan.opacity(0.35 + level * 0.45), radius: 4 + level * 4)
          .rotationEffect(.degrees(-angle))
          .offset(y: -diameter / 2)
          .rotationEffect(.degrees(angle))
      }
    }
    .frame(width: diameter, height: diameter)
  }

  private func radialTicks(diameter: CGFloat) -> some View {
    ZStack {
      ForEach(0..<36, id: \.self) { index in
        Capsule()
          .fill(index.isMultiple(of: 3) ? jade.opacity(0.72) : cyan.opacity(0.38))
          .frame(width: index.isMultiple(of: 3) ? 2 : 1, height: index.isMultiple(of: 3) ? 16 : 8)
          .offset(y: -diameter / 2)
          .rotationEffect(.degrees(Double(index) * 10))
      }
    }
    .frame(width: diameter, height: diameter)
  }

  // MARK: - Star map and sweep arcs

  /// Hexagram chord network with pulsing intersection nodes.
  private func starMap(diameter: CGFloat, time: TimeInterval, level: Double) -> some View {
    Canvas { context, _ in
      let center = CGPoint(x: diameter / 2, y: diameter / 2)
      let radius = diameter / 2
      let glow = 0.45 + 0.55 * level

      let vertices = (0..<6).map { index -> CGPoint in
        let angle = Double(index) * .pi / 3 - .pi / 2
        return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
      }

      var hexagon = Path()
      for (index, vertex) in vertices.enumerated() {
        index == 0 ? hexagon.move(to: vertex) : hexagon.addLine(to: vertex)
      }
      hexagon.closeSubpath()
      context.stroke(hexagon, with: .color(cyan.opacity(0.16 * glow)), lineWidth: 0.7)

      for offset in [0, 1] {
        var path = Path()
        for step in 0..<3 {
          let vertex = vertices[(offset + step * 2) % 6]
          step == 0 ? path.move(to: vertex) : path.addLine(to: vertex)
        }
        path.closeSubpath()
        context.stroke(path, with: .color(jade.opacity(0.30 * glow)), lineWidth: 0.9)
      }

      for vertex in vertices {
        var spoke = Path()
        spoke.move(to: vertex)
        spoke.addLine(to: center)
        context.stroke(spoke, with: .color(cyan.opacity(0.10 * glow)), lineWidth: 0.6)
      }

      for (index, vertex) in vertices.enumerated() {
        let twinkle = 0.5 + 0.5 * sin(time * 1.9 + Double(index) * 1.7)
        let nodeRadius = 1.6 + twinkle * 1.6
        let rect = CGRect(
          x: vertex.x - nodeRadius, y: vertex.y - nodeRadius, width: nodeRadius * 2,
          height: nodeRadius * 2)
        context.fill(
          Path(ellipseIn: rect),
          with: .color(
            (index.isMultiple(of: 2) ? jade : cyan).opacity((0.35 + twinkle * 0.45) * glow))
        )
      }
    }
    .frame(width: diameter, height: diameter)
  }

  /// A bright arc sweeping around the ring with a fading comet trail.
  private func sweepArc(
    diameter: CGFloat, time: TimeInterval, speed: Double, span: Double, tint: Color
  ) -> some View {
    ZStack {
      ForEach(0..<3, id: \.self) { trail in
        Circle()
          .trim(from: 0, to: span - Double(trail) * 0.04)
          .stroke(
            tint.opacity(0.5 - Double(trail) * 0.16),
            style: StrokeStyle(lineWidth: 2.4 - CGFloat(trail) * 0.7, lineCap: .round)
          )
          .rotationEffect(.degrees(time * speed - Double(trail) * 8))
      }
    }
    .frame(width: diameter, height: diameter)
    .blendMode(.plusLighter)
  }

  private func orbitingNodes(diameter: CGFloat, time: TimeInterval, level: Double) -> some View {
    ZStack {
      ForEach(0..<6, id: \.self) { index in
        Circle()
          .fill(index.isMultiple(of: 2) ? jade : cyan)
          .frame(width: 6 + level * 5, height: 6 + level * 5)
          .shadow(color: cyan, radius: 5 + level * 8)
          .offset(y: -diameter / 2)
          .rotationEffect(.degrees(Double(index) * 60))
      }
    }
    .frame(width: diameter, height: diameter)
    .rotationEffect(.degrees(time * 27))
  }

  // MARK: - Particles

  /// Spirit motes rising off the array surface; density and speed scale with charge.
  private func risingParticles(size: CGSize, diameter: CGFloat, time: TimeInterval, level: Double)
    -> some View
  {
    Canvas { context, _ in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let count = isActivated ? 110 : 34 + Int(level * 46)
      let cycle = diameter * 0.98

      for index in 0..<count {
        let seed = Double(index)
        let hash1 = abs(sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
        let hash2 = abs(sin(seed * 78.233) * 12578.1459).truncatingRemainder(dividingBy: 1)
        let hash3 = abs(sin(seed * 39.425) * 9631.317).truncatingRemainder(dividingBy: 1)

        let speedBoost = (isActivated ? 2.1 : 0.55 + level * 1.25)
        let riseSpeed = (16 + hash1 * 30) * speedBoost
        let traveled = (time * riseSpeed + seed * 61).truncatingRemainder(dividingBy: Double(cycle))
        let phase = traveled / Double(cycle)

        let baseX = center.x + (hash2 - 0.5) * diameter * 0.9
        let sway = sin(time * (0.6 + hash3 * 0.7) + seed) * (4 + hash1 * 7)
        let x = baseX + sway
        let y = center.y + diameter * 0.46 - traveled

        let dx = x - center.x
        let dy = y - center.y
        guard hypot(dx, dy) < diameter * 0.52 else { continue }

        let envelope = sin(.pi * phase)
        let twinkle = 0.55 + 0.45 * sin(time * (1.2 + hash3 * 1.6) + seed * 2.1)
        let alpha =
          (0.16 + hash1 * 0.3) * envelope * twinkle * (isActivated ? 1 : 0.55 + level * 0.65)
        let radius = 0.7 + hash3 * 1.6
        let tint = hash2 > 0.72 ? jade : hash2 > 0.18 ? cyan : Color.white

        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(alpha)))
      }
    }
    .blendMode(.plusLighter)
  }

  // MARK: - Core, seam, activation

  private func centerCore(
    diameter: CGFloat, time: TimeInterval, level: Double, speed: Double,
    activationAge: TimeInterval?
  ) -> some View {
    let pop = activationAge.map { $0 < 0.45 ? (1 - $0 / 0.45) * 0.3 : 0 } ?? 0

    return ZStack {
      Circle()
        .fill(cyan.opacity(0.16 + level * 0.2))
        .blur(radius: 14)
        .scaleEffect(1 + sin(time * 2.2) * 0.12)

      Circle()
        .stroke(cyan.opacity(0.28 + level * 0.55), lineWidth: 8 + level * 8)
        .blur(radius: 7 + level * 7)

      Circle()
        .stroke(jade.opacity(0.7 + level * 0.3), lineWidth: 1.5 + level * 2)

      Rectangle()
        .stroke(jade.opacity(0.9), lineWidth: 1.2)
        .frame(width: diameter * 0.11, height: diameter * 0.11)
        .rotationEffect(.degrees(45 + time * 18 * speed))

      Rectangle()
        .stroke((isActivated ? gold : cyan).opacity(0.85), lineWidth: 1)
        .frame(width: diameter * 0.072, height: diameter * 0.072)
        .rotationEffect(.degrees(45 - time * 26 * speed))
    }
    .frame(width: diameter * 0.2, height: diameter * 0.2)
    .scaleEffect(1 + level * 0.12 + pop)
    .shadow(color: cyan.opacity(0.55 + level * 0.4), radius: 12 + level * 18)
  }

  private func doorSeam(level: Double) -> some View {
    ZStack {
      Rectangle()
        .fill(cyan.opacity(0.14 + level * 0.2))
        .frame(width: 16)
        .blur(radius: 10)
      Rectangle()
        .fill(
          LinearGradient(
            colors: [.clear, cyan.opacity(0.75), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: 1)
    }
    .blendMode(.plusLighter)
  }

  /// Light pillar, shockwave rings and a white flash when the formation activates.
  private func activationFX(diameter: CGFloat, size: CGSize, age: TimeInterval) -> some View {
    let flashOpacity = max(0, 0.6 - age * 0.75)
    let pillarIn = min(1, age / 0.18)
    let pillarOut = max(0, 1 - max(0, age - 1.0) / 0.7)
    let pillarOpacity = pillarIn * pillarOut

    return ZStack {
      RadialGradient(
        colors: [.white.opacity(flashOpacity), .clear],
        center: .center,
        startRadius: 0,
        endRadius: diameter * 0.7
      )
      .frame(width: diameter * 1.4, height: diameter * 1.4)

      Capsule()
        .fill(
          LinearGradient(
            colors: [.clear, Color.white.opacity(0.9), cyan.opacity(0.55), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: diameter * 0.13, height: size.height * 1.1)
        .blur(radius: 16)
        .opacity(pillarOpacity)

      Capsule()
        .fill(Color.white.opacity(0.95))
        .frame(width: diameter * 0.026, height: size.height * 1.1)
        .blur(radius: 4)
        .opacity(pillarOpacity)

      ForEach(0..<3, id: \.self) { wave in
        let progress = max(0, min(1, (age - Double(wave) * 0.15) / 0.85))
        if progress > 0, progress < 1 {
          Circle()
            .stroke(
              (wave == 0 ? Color.white : wave == 1 ? jade : cyan).opacity(
                pow(1 - progress, 1.4) * 0.85),
              lineWidth: (1 - progress) * 6 + 1
            )
            .frame(
              width: diameter * (0.14 + progress * 0.62),
              height: diameter * (0.14 + progress * 0.62)
            )
        }
      }
    }
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

  private func cornerMarks(size: CGSize) -> some View {
    ZStack {
      ForEach(0..<4, id: \.self) { index in
        Path { path in
          path.move(to: CGPoint(x: 0, y: 18))
          path.addLine(to: .zero)
          path.addLine(to: CGPoint(x: 18, y: 0))
        }
        .stroke(cyan.opacity(0.48), lineWidth: 1)
        .frame(width: 18, height: 18)
        .position(
          x: index.isMultiple(of: 2) ? 27 : size.width - 27,
          y: index < 2 ? 27 : size.height - 27
        )
        .rotationEffect(.degrees(Double(index) * 90))
      }
    }
  }
}

private struct FormationPolygon: Shape {
  let sides: Int

  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    var path = Path()

    for index in 0..<sides {
      let angle = CGFloat(index) * 2 * .pi / CGFloat(sides) - .pi / 2
      let point = CGPoint(
        x: center.x + cos(angle) * radius,
        y: center.y + sin(angle) * radius
      )
      index == 0 ? path.move(to: point) : path.addLine(to: point)
    }

    path.closeSubpath()
    return path
  }
}
