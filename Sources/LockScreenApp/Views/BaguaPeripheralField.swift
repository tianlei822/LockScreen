import SwiftUI

struct BaguaPeripheralField: View {
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool
  let style: FormationVisualStyle

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let unit = min(size.width, size.height)
      let speed = isActivated ? 1.35 : 0.82

      for ring in 0..<6 {
        let wave = max(0, sin(time * speed * 2.35 - Double(ring) * 1.05))
        let flash = 0.12 + 0.88 * pow(wave, 2.4)
        let radius = unit * (0.315 + CGFloat(ring) * 0.029)
        let segmentCount = ring.isMultiple(of: 2) ? 16 : 12

        for segment in 0..<segmentCount {
          let segmentPhase =
            Double(segment) * 2 * .pi / Double(segmentCount)
            + time * (ring.isMultiple(of: 2) ? 0.032 : -0.024)
          let gap = Double.pi / Double(segmentCount) * (ring.isMultiple(of: 2) ? 0.23 : 0.38)
          var arc = Path()
          arc.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(segmentPhase + gap),
            endAngle: .radians(
              segmentPhase + 2 * .pi / Double(segmentCount) - gap
            ),
            clockwise: false
          )
          let segmentPulse =
            0.52 + 0.48 * (0.5 + 0.5 * sin(time * 3.15 - Double(segment) * 0.63))
          context.stroke(
            arc,
            with: .color(
              (ring.isMultiple(of: 2) ? style.primary : style.secondary)
                .opacity((0.06 + energy * 0.12 + flash * 0.28) * segmentPulse)
            ),
            style: StrokeStyle(
              lineWidth: 0.45 + CGFloat(flash) * (ring.isMultiple(of: 2) ? 3.6 : 2.45),
              lineCap: .square
            )
          )
        }

        if flash > 0.38 {
          var ringGlow = context
          ringGlow.addFilter(.blur(radius: 5 + CGFloat(flash) * 5))
          ringGlow.stroke(
            Path(
              ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
              )
            ),
            with: .color(style.primary.opacity(flash * (0.08 + energy * 0.08))),
            lineWidth: 4 + CGFloat(flash) * 6
          )
        }
      }

      for ray in 0..<24 {
        let angle = Double(ray) * 2 * .pi / 24 - time * 0.045
        let pulse = 0.18 + 0.82 * pow(max(0, sin(time * 2.7 - Double(ray) * 0.4)), 2)
        let inner = unit * (ray.isMultiple(of: 3) ? 0.405 : 0.432)
        let outer = unit * (ray.isMultiple(of: 3) ? 0.475 : 0.462)
        var tick = Path()
        tick.move(
          to: CGPoint(
            x: center.x + cos(angle) * inner,
            y: center.y + sin(angle) * inner
          )
        )
        tick.addLine(
          to: CGPoint(
            x: center.x + cos(angle) * outer,
            y: center.y + sin(angle) * outer
          )
        )
        context.stroke(
          tick,
          with: .color(
            (ray.isMultiple(of: 3) ? style.secondary : style.primary)
              .opacity((0.07 + energy * 0.12) * pulse)
          ),
          style: StrokeStyle(
            lineWidth: (ray.isMultiple(of: 3) ? 2.1 : 0.65) * (0.65 + CGFloat(pulse)),
            lineCap: .square
          )
        )
      }
    }
    .blendMode(.plusLighter)
  }
}
