import LockScreenCore
import SwiftUI

extension FivePhaseElement {
  var accessibilityName: String {
    switch self {
    case .wood: "Wood"
    case .fire: "Fire"
    case .earth: "Earth"
    case .metal: "Metal"
    case .water: "Water"
    }
  }

  var color: Color {
    switch self {
    case .wood: Color(red: 0.34, green: 0.95, blue: 0.48)
    case .fire: Color(red: 0.95, green: 0.18, blue: 0.045)
    case .earth: Color(red: 0.72, green: 0.43, blue: 0.2)
    case .metal: Color(red: 0.42, green: 0.95, blue: 0.7)
    case .water: Color(red: 0.22, green: 0.62, blue: 1)
    }
  }
}

/// An elemental mark built from line language rather than a literal pictogram or word.
struct FivePhaseSigil: View {
  let element: FivePhaseElement
  let size: CGFloat
  let energy: Double
  let time: TimeInterval

  var body: some View {
    let pulse = 0.5 + 0.5 * sin(time * 2.1 + Double(element.rawValue))

    ZStack {
      Circle()
        .trim(from: 0.08, to: 0.82)
        .stroke(
          element.color.opacity(0.18 + energy * 0.24),
          style: StrokeStyle(lineWidth: 0.8 + energy, lineCap: .round, dash: [2, 5])
        )
        .rotationEffect(.degrees(time * (element.rawValue.isMultiple(of: 2) ? 18 : -18)))

      Canvas(rendersAsynchronously: true) { context, canvasSize in
        let paths = paths(for: element, in: canvasSize)

        for (index, path) in paths.enumerated() {
          var glow = context
          glow.addFilter(.blur(radius: 3 + energy * 4))
          glow.stroke(
            path,
            with: .color(element.color.opacity(0.24 + energy * 0.25)),
            style: StrokeStyle(
              lineWidth: 4 + CGFloat(index.isMultiple(of: 2) ? energy * 2 : energy),
              lineCap: .round,
              lineJoin: .round
            )
          )

          context.stroke(
            path,
            with: .color(index == 0 ? Color.white.opacity(0.82) : element.color),
            style: StrokeStyle(
              lineWidth: index == 0 ? 1.8 + energy : 1 + energy * 0.7,
              lineCap: .round,
              lineJoin: .round
            )
          )
        }
      }
      .padding(size * 0.2)

      Circle()
        .fill(element.color)
        .frame(width: 3 + energy * 3, height: 3 + energy * 3)
        .shadow(color: element.color, radius: 4 + energy * 6)
        .offset(y: -size * 0.43)
        .rotationEffect(.degrees(time * 24 + Double(element.rawValue) * 72))
    }
    .frame(width: size, height: size)
    .scaleEffect(0.97 + pulse * 0.06 + energy * 0.04)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(element.accessibilityName)
  }

  private func paths(for element: FivePhaseElement, in size: CGSize) -> [Path] {
    switch element {
    case .wood:
      woodPaths(size: size)
    case .fire:
      firePaths(size: size)
    case .earth:
      earthPaths(size: size)
    case .metal:
      metalPaths(size: size)
    case .water:
      waterPaths(size: size)
    }
  }

  private func woodPaths(size: CGSize) -> [Path] {
    let w = size.width
    let h = size.height
    return [
      Path { path in
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.88))
        path.addCurve(
          to: CGPoint(x: w * 0.5, y: h * 0.12),
          control1: CGPoint(x: w * 0.42, y: h * 0.62),
          control2: CGPoint(x: w * 0.58, y: h * 0.38)
        )
      },
      Path { path in
        path.move(to: CGPoint(x: w * 0.48, y: h * 0.54))
        path.addCurve(
          to: CGPoint(x: w * 0.16, y: h * 0.3),
          control1: CGPoint(x: w * 0.36, y: h * 0.48),
          control2: CGPoint(x: w * 0.3, y: h * 0.3)
        )
        path.move(to: CGPoint(x: w * 0.52, y: h * 0.4))
        path.addCurve(
          to: CGPoint(x: w * 0.84, y: h * 0.22),
          control1: CGPoint(x: w * 0.66, y: h * 0.37),
          control2: CGPoint(x: w * 0.7, y: h * 0.2)
        )
      },
    ]
  }

  private func firePaths(size: CGSize) -> [Path] {
    let w = size.width
    let h = size.height
    return [
      Path { path in
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.9))
        path.addCurve(
          to: CGPoint(x: w * 0.58, y: h * 0.1),
          control1: CGPoint(x: w * 0.1, y: h * 0.65),
          control2: CGPoint(x: w * 0.78, y: h * 0.48)
        )
        path.addCurve(
          to: CGPoint(x: w * 0.5, y: h * 0.9),
          control1: CGPoint(x: w * 0.96, y: h * 0.6),
          control2: CGPoint(x: w * 0.76, y: h * 0.88)
        )
      },
      Path { path in
        path.move(to: CGPoint(x: w * 0.49, y: h * 0.77))
        path.addCurve(
          to: CGPoint(x: w * 0.48, y: h * 0.39),
          control1: CGPoint(x: w * 0.32, y: h * 0.65),
          control2: CGPoint(x: w * 0.6, y: h * 0.56)
        )
      },
    ]
  }

  private func earthPaths(size: CGSize) -> [Path] {
    let w = size.width
    let h = size.height
    return (0..<3).map { index in
      let y = h * (0.32 + CGFloat(index) * 0.2)
      return Path { path in
        path.move(to: CGPoint(x: w * (0.14 + CGFloat(index) * 0.06), y: y))
        path.addCurve(
          to: CGPoint(x: w * (0.86 - CGFloat(index) * 0.06), y: y),
          control1: CGPoint(x: w * 0.36, y: y - h * 0.1),
          control2: CGPoint(x: w * 0.64, y: y + h * 0.1)
        )
      }
    }
  }

  private func metalPaths(size: CGSize) -> [Path] {
    let w = size.width
    let h = size.height
    return [
      Path { path in
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.08))
        path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.4))
        path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.34))
        path.closeSubpath()
      },
      Path { path in
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.08))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62))
        path.addLine(to: CGPoint(x: w * 0.28, y: h * 0.82))
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.62))
        path.addLine(to: CGPoint(x: w * 0.86, y: h * 0.4))
      },
    ]
  }

  private func waterPaths(size: CGSize) -> [Path] {
    let w = size.width
    let h = size.height
    return (0..<3).map { index in
      let y = h * (0.32 + CGFloat(index) * 0.2)
      return Path { path in
        path.move(to: CGPoint(x: w * 0.08, y: y))
        path.addCurve(
          to: CGPoint(x: w * 0.5, y: y),
          control1: CGPoint(x: w * 0.22, y: y - h * 0.16),
          control2: CGPoint(x: w * 0.36, y: y + h * 0.16)
        )
        path.addCurve(
          to: CGPoint(x: w * 0.92, y: y),
          control1: CGPoint(x: w * 0.64, y: y - h * 0.16),
          control2: CGPoint(x: w * 0.78, y: y + h * 0.16)
        )
      }
    }
  }
}

struct ResonantRing: Shape {
  let phase: Double
  let lobes: Int
  let amplitude: CGFloat

  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2
    var path = Path()

    for index in 0...160 {
      let angle = Double(index) / 160 * 2 * .pi
      let primaryWave = sin(angle * Double(lobes) + phase)
      let secondaryWave = sin(angle * Double(lobes + 3) - phase * 0.62) * 0.35
      let r = radius * (1 + amplitude * CGFloat(primaryWave + secondaryWave))
      let point = CGPoint(
        x: center.x + cos(angle) * r,
        y: center.y + sin(angle) * r
      )
      index == 0 ? path.move(to: point) : path.addLine(to: point)
    }
    path.closeSubpath()
    return path
  }
}
