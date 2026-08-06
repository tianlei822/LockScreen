import LockScreenCore
import SwiftUI

struct AtmosphericBackground: View {
  let theme: DoorTheme

  var body: some View {
    let palette = theme.palette

    TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

      ZStack {
        palette.backdrop

        RadialGradient(
          colors: [palette.haze.opacity(0.52), palette.backdrop.opacity(0)],
          center: .center,
          startRadius: 40,
          endRadius: 650
        )
        .scaleEffect(1 + sin(time * 0.35) * 0.04)

        Canvas { context, size in
          for index in 0..<46 {
            let seed = Double(index)
            let x = (seed * 83).truncatingRemainder(dividingBy: Double(size.width))
            let baseY = (seed * 47).truncatingRemainder(dividingBy: Double(size.height))
            let drift = (time * (4 + seed.truncatingRemainder(dividingBy: 7)))
              .truncatingRemainder(dividingBy: Double(size.height + 60))
            let y =
              (baseY - drift + Double(size.height + 60))
              .truncatingRemainder(dividingBy: Double(size.height + 60)) - 30
            let radius = 0.8 + seed.truncatingRemainder(dividingBy: 2.4)
            let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
            context.fill(
              Path(ellipseIn: rect),
              with: .color(
                palette.accent.opacity(0.16 + seed.truncatingRemainder(dividingBy: 3) * 0.07))
            )
          }
        }
      }
    }
    .ignoresSafeArea()
    .animation(.easeInOut(duration: 0.7), value: theme)
  }
}
