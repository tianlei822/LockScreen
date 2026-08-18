import LockScreenCore
import SwiftUI

struct BranchFormationShape: Shape {
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

struct CurlingVineShape: Shape {
  let phase: Double

  func path(in rect: CGRect) -> Path {
    let sway = CGFloat(sin(phase)) * rect.width * 0.1
    return Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addCurve(
        to: CGPoint(x: rect.midX + sway, y: rect.height * 0.32),
        control1: CGPoint(x: rect.width * 0.18, y: rect.height * 0.78),
        control2: CGPoint(x: rect.width * 0.84, y: rect.height * 0.55)
      )
      path.addCurve(
        to: CGPoint(x: rect.midX - rect.width * 0.06, y: rect.height * 0.12),
        control1: CGPoint(x: rect.width * 0.12, y: rect.height * 0.2),
        control2: CGPoint(x: rect.width * 0.3, y: rect.height * 0.02)
      )
      path.addCurve(
        to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.height * 0.2),
        control1: CGPoint(x: rect.width * 0.72, y: rect.height * 0.04),
        control2: CGPoint(x: rect.width * 0.8, y: rect.height * 0.18)
      )
    }
  }
}

struct WaterCurrentSpiral: Shape {
  let phase: Double

  func path(in rect: CGRect) -> Path {
    Path { path in
      for index in 0...96 {
        let progress = CGFloat(index) / 96
        let angle = Double(progress) * .pi * 3.4 + phase
        let radiusX = rect.width * (0.08 + progress * 0.42)
        let radiusY = rect.height * (0.08 + progress * 0.42)
        let ripple = 1 + CGFloat(sin(angle * 2.2 - phase)) * 0.055
        let point = CGPoint(
          x: rect.midX + cos(angle) * radiusX * ripple,
          y: rect.midY + sin(angle) * radiusY * ripple
        )
        index == 0 ? path.move(to: point) : path.addLine(to: point)
      }
    }
  }
}

struct WaterDropletShape: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addCurve(
        to: CGPoint(x: rect.midX, y: rect.maxY),
        control1: CGPoint(x: rect.maxX * 1.04, y: rect.height * 0.46),
        control2: CGPoint(x: rect.maxX * 0.9, y: rect.height * 0.82)
      )
      path.addCurve(
        to: CGPoint(x: rect.midX, y: rect.minY),
        control1: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.height * 0.82),
        control2: CGPoint(x: rect.minX - rect.width * 0.04, y: rect.height * 0.46)
      )
      path.closeSubpath()
    }
  }
}

struct SpiritSwordFormationShape: Shape {
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

struct SpiritSwordDetailShape: Shape {
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

struct SpiritSwordGlyph: View {
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

struct LeafFormationShape: Shape {
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

struct LeafVeinFormationShape: Shape {
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
