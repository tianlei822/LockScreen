import LockScreenCore
import SwiftUI

struct SolarSystemArtwork: View {
  let isActivated: Bool
  let onActivate: () -> Void
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced
  @State private var exitStartedAt: Date?

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let unit = min(size.width, size.height)
      let center = CGPoint(x: size.width * 0.5, y: size.height * 0.56)

      ZStack {
        TimelineView(
          .animation(
            minimumInterval: 1 / 30,
            paused: RitualMotionPolicy.pausesVisualEffects(
              renderingPaused: ritualAnimationsPaused,
              reduceMotion: ritualMotionReduced
            )
          )
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
        .opacity(isActivated && ritualMotionReduced ? 0 : 1)

        VStack {
          Spacer()
          HStack(spacing: 14) {
            Rectangle()
              .fill(Color.white.opacity(0.24))
              .frame(width: 44, height: 1)
            Text(L10n.text("DOUBLE-CLICK THE SUN TO UNLOCK"))
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
    .animation(.easeOut(duration: ritualMotionReduced ? 0.18 : 0.28), value: isActivated)
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
      Button(L10n.text("Sun — double-click to unlock"), action: onActivate)
    }
    .help(L10n.text("Double-click the sun to unlock"))
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
