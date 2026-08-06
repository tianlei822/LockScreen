import LockScreenCore
import SwiftUI

struct FormationDoorArtwork: View {
  let energy: Double
  let isActivated: Bool

  private let ink = Color(red: 0.008, green: 0.025, blue: 0.048)
  private let cyan = Color(red: 0.18, green: 0.91, blue: 0.84)
  private let jade = Color(red: 0.52, green: 0.95, blue: 0.71)

  var body: some View {
    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
      GeometryReader { proxy in
        let size = proxy.size
        let time = timeline.date.timeIntervalSinceReferenceDate
        let diameter = min(size.width, size.height) * 0.78
        let level = max(0, min(1, energy))
        let speed = isActivated ? 3.8 : 1 + level * 1.8
        let pulse = 1 + sin(time * 1.5 * speed) * (0.012 + level * 0.018)

        ZStack {
          LinearGradient(
            colors: [ink, Color(red: 0.018, green: 0.12, blue: 0.15), ink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )

          formationLattice(size: size, time: time)

          formationSpokes(size: size, diameter: diameter)

          Circle()
            .fill(cyan.opacity(0.08))
            .frame(width: diameter * 0.92, height: diameter * 0.92)
            .blur(radius: 18)

          ring(diameter: diameter, dash: [2, 10], lineWidth: 1.2)
            .rotationEffect(.degrees(time * 14 * speed))

          ring(diameter: diameter * 0.78, dash: [20, 7, 3, 7], lineWidth: 1.8)
            .rotationEffect(.degrees(-time * 22 * speed))

          radialTicks(diameter: diameter * 0.88)
            .rotationEffect(.degrees(time * 4 * speed))

          Circle()
            .trim(from: 0.01, to: max(0.012, CGFloat(level)))
            .stroke(
              AngularGradient(colors: [cyan, jade, .white, cyan], center: .center),
              style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
            .frame(width: diameter * 0.84, height: diameter * 0.84)
            .rotationEffect(.degrees(-90))
            .shadow(color: cyan.opacity(0.65 + level * 0.3), radius: 8 + level * 12)

          FormationPolygon(sides: 8)
            .stroke(cyan.opacity(0.62), style: StrokeStyle(lineWidth: 1, dash: [5, 7]))
            .frame(width: diameter * 0.64, height: diameter * 0.64)
            .rotationEffect(.degrees(time * 9 * speed))

          FormationPolygon(sides: 3)
            .stroke(jade.opacity(0.54), lineWidth: 1.5)
            .frame(width: diameter * 0.48, height: diameter * 0.48)
            .rotationEffect(.degrees(-time * 15 * speed))

          FormationPolygon(sides: 6)
            .stroke(cyan.opacity(0.18 + level * 0.45), lineWidth: 1)
            .frame(width: diameter * 0.34, height: diameter * 0.34)
            .rotationEffect(.degrees(time * 21 * speed))

          runeOrbit(diameter: diameter * 0.71, time: time * speed)

          orbitingNodes(diameter: diameter * 0.57, time: time * speed, level: level)

          ZStack {
            Circle()
              .stroke(cyan.opacity(0.28 + level * 0.55), lineWidth: 8 + level * 8)
              .blur(radius: 7 + level * 7)
            Circle()
              .stroke(jade.opacity(0.7 + level * 0.3), lineWidth: 1.5 + level * 2)
            Text("◇")
              .font(.system(size: diameter * 0.12, weight: .ultraLight))
              .foregroundStyle(jade)
              .rotationEffect(.degrees(time * 18 * speed))
          }
          .frame(width: diameter * 0.2, height: diameter * 0.2)
          .scaleEffect(1 + level * 0.12)
          .shadow(color: cyan.opacity(0.55 + level * 0.4), radius: 12 + level * 18)

          Rectangle()
            .fill(cyan.opacity(0.7))
            .frame(width: 1)
            .blendMode(.plusLighter)

          cornerMarks(size: size)

          if isActivated {
            Circle()
              .stroke(Color.white.opacity(0.72), lineWidth: 2)
              .frame(width: diameter * 0.93, height: diameter * 0.93)
              .blur(radius: 2)
              .transition(.scale.combined(with: .opacity))
          }
        }
        .scaleEffect(pulse)
      }
    }
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

  private func formationSpokes(size: CGSize, diameter: CGFloat) -> some View {
    Canvas { context, _ in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let innerRadius = diameter * 0.16
      let outerRadius = diameter * 0.38

      for index in 0..<12 {
        let angle = Double(index) * Double.pi / 6 - Double.pi / 2
        var path = Path()
        path.move(
          to: CGPoint(
            x: center.x + cos(angle) * innerRadius,
            y: center.y + sin(angle) * innerRadius
          ))
        path.addLine(
          to: CGPoint(
            x: center.x + cos(angle) * outerRadius,
            y: center.y + sin(angle) * outerRadius
          ))
        context.stroke(path, with: .color(cyan.opacity(0.16)), lineWidth: 0.8)
      }
    }
  }

  private func ring(diameter: CGFloat, dash: [CGFloat], lineWidth: CGFloat) -> some View {
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

  private func runeOrbit(diameter: CGFloat, time: TimeInterval) -> some View {
    ZStack {
      ForEach(0..<12, id: \.self) { index in
        let angle = Double(index) * 30
        Text(Rune.allCases[index % Rune.allCases.count].symbol)
          .font(.system(size: 14, weight: .light, design: .monospaced))
          .foregroundStyle(index.isMultiple(of: 3) ? jade : cyan.opacity(0.76))
          .offset(y: -diameter / 2)
          .rotationEffect(.degrees(-angle))
          .rotationEffect(.degrees(-time * 11))
          .rotationEffect(.degrees(angle), anchor: .center)
      }
    }
    .frame(width: diameter, height: diameter)
    .rotationEffect(.degrees(time * 11))
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
