import LockScreenCore
import SwiftUI

/// A restrained foreground engraving shared by every door theme.
/// It gives the screen edges physical depth without competing with the central ritual.
struct ThresholdDetailOverlay: View {
  let theme: DoorTheme
  let isOpen: Bool
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused

  var body: some View {
    let palette = theme.palette

    TimelineView(
      .animation(minimumInterval: 1 / 20, paused: ritualAnimationsPaused)
    ) { timeline in
      GeometryReader { proxy in
        let size = proxy.size
        let time = timeline.date.timeIntervalSinceReferenceDate

        ZStack {
          perimeterEtching(size: size, time: time, palette: palette)

          RadialGradient(
            colors: [
              palette.accent.opacity(isOpen ? 0.12 : 0.035),
              .clear,
            ],
            center: .center,
            startRadius: 0,
            endRadius: min(size.width, size.height) * 0.32
          )
          .blendMode(.plusLighter)

          floatingDust(size: size, time: time, palette: palette)
        }
        .allowsHitTesting(false)
      }
    }
  }

  private func perimeterEtching(
    size: CGSize, time: TimeInterval, palette: ThemePalette
  ) -> some View {
    Canvas { context, _ in
      let outerInset: CGFloat = 8
      let innerInset: CGFloat = 20
      let pulse = 0.5 + 0.5 * sin(time * 0.8)

      context.stroke(
        Path(
          CGRect(
            x: outerInset,
            y: outerInset,
            width: size.width - outerInset * 2,
            height: size.height - outerInset * 2
          )),
        with: .color(palette.detail.opacity(0.12 + pulse * 0.04)),
        lineWidth: 1
      )

      context.stroke(
        Path(
          CGRect(
            x: innerInset,
            y: innerInset,
            width: size.width - innerInset * 2,
            height: size.height - innerInset * 2
          )),
        with: .color(palette.accent.opacity(0.08)),
        style: StrokeStyle(lineWidth: 0.7, dash: [18, 8, 2, 8])
      )

      let cornerLength = min(size.width, size.height) * 0.055
      for corner in 0..<4 {
        let left = corner.isMultiple(of: 2)
        let top = corner < 2
        let origin = CGPoint(
          x: left ? innerInset : size.width - innerInset,
          y: top ? innerInset : size.height - innerInset
        )
        let horizontal = left ? cornerLength : -cornerLength
        let vertical = top ? cornerLength : -cornerLength

        var bracket = Path()
        bracket.move(to: CGPoint(x: origin.x + horizontal, y: origin.y))
        bracket.addLine(to: origin)
        bracket.addLine(to: CGPoint(x: origin.x, y: origin.y + vertical))
        context.stroke(
          bracket,
          with: .color(palette.detail.opacity(0.3 + pulse * 0.12)),
          style: StrokeStyle(lineWidth: 1.2, lineCap: .square)
        )
      }

      for index in 0..<18 {
        let fraction = CGFloat(index + 1) / 19
        let longTick = index.isMultiple(of: 3)
        let length: CGFloat = longTick ? 10 : 5
        let alpha = longTick ? 0.26 : 0.13

        for edge in 0..<2 {
          let y = edge == 0 ? innerInset : size.height - innerInset
          var tick = Path()
          tick.move(to: CGPoint(x: size.width * fraction, y: y))
          tick.addLine(
            to: CGPoint(x: size.width * fraction, y: y + (edge == 0 ? length : -length)))
          context.stroke(tick, with: .color(palette.accent.opacity(alpha)), lineWidth: 0.8)
        }
      }

      for index in 0..<10 {
        let fraction = CGFloat(index + 1) / 11
        let longTick = index.isMultiple(of: 2)
        let length: CGFloat = longTick ? 10 : 5

        for edge in 0..<2 {
          let x = edge == 0 ? innerInset : size.width - innerInset
          var tick = Path()
          tick.move(to: CGPoint(x: x, y: size.height * fraction))
          tick.addLine(
            to: CGPoint(x: x + (edge == 0 ? length : -length), y: size.height * fraction))
          context.stroke(
            tick,
            with: .color(palette.detail.opacity(longTick ? 0.24 : 0.12)),
            lineWidth: 0.8
          )
        }
      }
    }
  }

  private func floatingDust(
    size: CGSize, time: TimeInterval, palette: ThemePalette
  ) -> some View {
    Canvas { context, _ in
      for index in 0..<22 {
        let seed = Double(index + 1)
        let xSeed = abs(sin(seed * 17.17) * 913.7).truncatingRemainder(dividingBy: 1)
        let ySeed = abs(sin(seed * 31.73) * 631.9).truncatingRemainder(dividingBy: 1)
        let drift = (time * (3 + seed.truncatingRemainder(dividingBy: 4)) + ySeed * 200)
          .truncatingRemainder(dividingBy: Double(size.height))
        let x = xSeed * Double(size.width) + sin(time * 0.35 + seed) * 7
        let y = Double(size.height) - drift
        let twinkle = 0.5 + 0.5 * sin(time * 1.1 + seed * 2.3)
        let radius = 0.5 + seed.truncatingRemainder(dividingBy: 3) * 0.35
        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)

        context.fill(
          Path(ellipseIn: rect),
          with: .color(palette.detail.opacity(0.05 + twinkle * 0.12))
        )
      }
    }
    .blendMode(.plusLighter)
  }
}
