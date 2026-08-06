import LockScreenCore
import SwiftUI

struct AtmosphericBackground: View {
  let theme: DoorTheme

  var body: some View {
    let palette = theme.palette

    TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

      GeometryReader { proxy in
        let size = proxy.size

        ZStack {
          palette.backdrop

          RadialGradient(
            colors: [palette.haze.opacity(0.52), palette.backdrop.opacity(0)],
            center: .center,
            startRadius: 40,
            endRadius: 650
          )
          .scaleEffect(1 + sin(time * 0.35) * 0.04)

          RadialGradient(
            colors: [palette.accentSoft.opacity(0.30), palette.backdrop.opacity(0)],
            center: .center,
            startRadius: 20,
            endRadius: 520
          )
          .offset(x: sin(time * 0.21) * 140, y: cos(time * 0.16) * 100)
          .scaleEffect(1 + cos(time * 0.27) * 0.06)

          lightShafts(size: size, time: time, palette: palette)

          driftingMotes(size: size, time: time, palette: palette)
        }
      }
    }
    .ignoresSafeArea()
    .animation(.easeInOut(duration: 0.7), value: theme)
  }

  /// Soft diagonal shafts of light swaying slowly, like light through deep water.
  private func lightShafts(size: CGSize, time: TimeInterval, palette: ThemePalette) -> some View {
    ZStack {
      ForEach(0..<3, id: \.self) { index in
        let fraction = [-0.26, 0.06, 0.34][index]
        Capsule()
          .fill(
            LinearGradient(
              colors: [palette.accent.opacity(0.06 - Double(index) * 0.012), .clear],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: 150 - CGFloat(index) * 30, height: size.height * 1.5)
          .rotationEffect(.degrees(16))
          .offset(
            x: size.width * fraction + sin(time * 0.09 + Double(index) * 2.1) * 36,
            y: -size.height * 0.12
          )
      }
    }
    .blur(radius: 26)
    .blendMode(.plusLighter)
  }

  private func driftingMotes(size: CGSize, time: TimeInterval, palette: ThemePalette) -> some View {
    Canvas { context, canvasSize in
      for index in 0..<64 {
        let seed = Double(index)
        let baseX = (seed * 83).truncatingRemainder(dividingBy: Double(canvasSize.width))
        let baseY = (seed * 47).truncatingRemainder(dividingBy: Double(canvasSize.height))
        let drift = (time * (4 + seed.truncatingRemainder(dividingBy: 7)))
          .truncatingRemainder(dividingBy: Double(canvasSize.height + 60))
        let y =
          (baseY - drift + Double(canvasSize.height + 60))
          .truncatingRemainder(dividingBy: Double(canvasSize.height + 60)) - 30
        let sway = sin(time * 0.45 + seed * 1.7) * 9
        let twinkle =
          0.5 + 0.5 * sin(time * (0.6 + seed.truncatingRemainder(dividingBy: 1.3)) + seed * 2.3)
        let radius = 0.8 + seed.truncatingRemainder(dividingBy: 2.4)
        let alpha =
          (0.10 + seed.truncatingRemainder(dividingBy: 3) * 0.06) * (0.45 + twinkle * 0.55)
        let rect = CGRect(x: baseX + sway, y: y, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: rect), with: .color(palette.accent.opacity(alpha)))
      }

      var soft = context
      soft.addFilter(.blur(radius: 9))
      for index in 0..<9 {
        let seed = Double(index) + 100
        let x = (seed * 131).truncatingRemainder(dividingBy: Double(canvasSize.width))
        let yDrift = (time * (2.5 + seed.truncatingRemainder(dividingBy: 3)))
          .truncatingRemainder(dividingBy: Double(canvasSize.height + 160))
        let y =
          ((seed * 97).truncatingRemainder(dividingBy: Double(canvasSize.height)) - yDrift
          + Double(canvasSize.height + 160))
          .truncatingRemainder(dividingBy: Double(canvasSize.height + 160)) - 80
        let radius = 9 + seed.truncatingRemainder(dividingBy: 13)
        let twinkle = 0.5 + 0.5 * sin(time * 0.5 + seed)
        let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
        soft.fill(
          Path(ellipseIn: rect),
          with: .color(palette.accentSoft.opacity(0.05 + twinkle * 0.05))
        )
      }
    }
  }
}
