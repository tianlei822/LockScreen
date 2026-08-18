import LockScreenCore
import SwiftUI

struct VaultDoorArtwork: View {
  private let graphite = Color(red: 0.025, green: 0.031, blue: 0.036)
  private let steel = Color(red: 0.18, green: 0.21, blue: 0.22)
  private let warmSteel = Color(red: 0.32, green: 0.3, blue: 0.25)
  private let amber = Color(red: 0.94, green: 0.61, blue: 0.18)
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced

  var body: some View {
    TimelineView(
      .animation(
        minimumInterval: 1 / 20,
        paused: RitualMotionPolicy.pausesVisualEffects(
          renderingPaused: ritualAnimationsPaused,
          reduceMotion: ritualMotionReduced
        )
      )
    ) { timeline in
      GeometryReader { proxy in
        let size = proxy.size
        let unit = min(size.width, size.height)
        let time = timeline.date.timeIntervalSinceReferenceDate

        ZStack {
          LinearGradient(
            colors: [graphite, steel.opacity(0.86), graphite],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )

          brushedMetal(size: size)

          Rectangle()
            .fill(Color.black.opacity(0.64))
            .frame(width: 5)

          safeHousing(unit: unit, time: time)

          structuralBolts(size: size)

          Rectangle()
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
            .padding(18)
        }
      }
    }
  }

  private func safeHousing(unit: CGFloat, time: TimeInterval) -> some View {
    let width = unit * 0.48
    let height = unit * 0.56

    return ZStack {
      RoundedRectangle(cornerRadius: 18)
        .fill(Color.black.opacity(0.7))
        .frame(width: width + 34, height: height + 34)
        .shadow(color: .black.opacity(0.82), radius: 34, y: 18)

      RoundedRectangle(cornerRadius: 14)
        .fill(
          LinearGradient(
            colors: [steel, graphite, warmSteel.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .overlay {
          RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.15), lineWidth: 2)
            .padding(5)
        }
        .overlay {
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color.black.opacity(0.8), lineWidth: 5)
            .padding(12)
        }
        .frame(width: width, height: height)

      ForEach(0..<12, id: \.self) { index in
        Capsule()
          .fill(index.isMultiple(of: 3) ? amber.opacity(0.72) : Color.white.opacity(0.2))
          .frame(width: index.isMultiple(of: 3) ? 4 : 2, height: 16)
          .offset(y: -height * 0.31)
          .rotationEffect(.degrees(Double(index) * 30))
      }

      ZStack {
        Circle()
          .fill(
            AngularGradient(
              colors: [Color.black, steel, Color.white.opacity(0.42), graphite, steel],
              center: .center
            )
          )
        Circle()
          .stroke(Color.black.opacity(0.86), lineWidth: 9)
        Circle()
          .stroke(Color.white.opacity(0.18), lineWidth: 1)
          .padding(11)
        Circle()
          .trim(from: 0.03, to: 0.42)
          .stroke(amber.opacity(0.66), style: StrokeStyle(lineWidth: 3, lineCap: .round))
          .padding(17)
          .rotationEffect(.degrees(time * 7))
          .shadow(color: amber.opacity(0.52), radius: 8)
      }
      .frame(width: unit * 0.27, height: unit * 0.27)
      .offset(y: -height * 0.11)

      VStack(spacing: 7) {
        Text(L10n.text("THRESHOLD // VAULT"))
          .font(.system(size: 10, weight: .semibold, design: .monospaced))
          .tracking(3)
        Rectangle()
          .fill(amber.opacity(0.65))
          .frame(width: 54, height: 1)
      }
      .foregroundStyle(Color.white.opacity(0.58))
      .offset(y: height * 0.34)
    }
  }

  private func brushedMetal(size: CGSize) -> some View {
    Canvas { context, _ in
      for index in 0..<72 {
        let y = CGFloat(index) * size.height / 71
        var line = Path()
        line.move(to: CGPoint(x: 0, y: y))
        line.addLine(to: CGPoint(x: size.width, y: y + CGFloat(index % 3) - 1))
        context.stroke(
          line,
          with: .color(Color.white.opacity(index.isMultiple(of: 4) ? 0.025 : 0.011)),
          lineWidth: 0.7
        )
      }

      for index in 1..<6 {
        let x = CGFloat(index) * size.width / 6
        var seam = Path()
        seam.move(to: CGPoint(x: x, y: 0))
        seam.addLine(to: CGPoint(x: x, y: size.height))
        context.stroke(seam, with: .color(Color.black.opacity(0.22)), lineWidth: 1)
      }
    }
    .allowsHitTesting(false)
  }

  private func structuralBolts(size: CGSize) -> some View {
    ZStack {
      ForEach(0..<16, id: \.self) { index in
        let column = index % 4
        let row = index / 4
        Circle()
          .fill(
            RadialGradient(
              colors: [Color.white.opacity(0.3), steel, Color.black],
              center: .topLeading,
              startRadius: 1,
              endRadius: 7
            )
          )
          .frame(width: 12, height: 12)
          .position(
            x: 34 + CGFloat(column) * (size.width - 68) / 3,
            y: 38 + CGFloat(row) * (size.height - 76) / 3
          )
      }
    }
  }
}
