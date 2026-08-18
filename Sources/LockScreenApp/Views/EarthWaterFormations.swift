import LockScreenCore
import SwiftUI

struct EarthSealFormation: View {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let color: Color

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = min(size.width, size.height) * 0.46
      let sealRect = CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
      )
      let seal = Path(ellipseIn: sealRect)
      var terrain = context
      terrain.clip(to: seal)

      let mainRect = CGRect(
        x: sealRect.minX,
        y: sealRect.minY + radius * 0.42,
        width: sealRect.width,
        height: radius * 1.32
      )
      let mainRidge = earthRidge(in: mainRect, seed: 2, closesAtBottom: true)
      terrain.fill(
        mainRidge,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.88, green: 0.63, blue: 0.36).opacity(0.58 + energy * 0.12),
            color.opacity(0.62),
            Color(red: 0.16, green: 0.07, blue: 0.025).opacity(0.9),
          ]),
          startPoint: CGPoint(x: center.x, y: mainRect.minY),
          endPoint: CGPoint(x: center.x, y: mainRect.maxY)
        )
      )

      for ridge in 0..<3 {
        let ridgeRect = CGRect(
          x: sealRect.minX - CGFloat(ridge) * radius * 0.035,
          y: sealRect.minY + radius * (0.34 + CGFloat(ridge) * 0.24),
          width: sealRect.width + CGFloat(ridge) * radius * 0.07,
          height: radius * (0.82 + CGFloat(ridge) * 0.12)
        )
        let filledPath = earthRidge(in: ridgeRect, seed: 7 + ridge * 5, closesAtBottom: true)
        terrain.fill(
          filledPath,
          with: .linearGradient(
            Gradient(colors: [
              Color(red: 0.93, green: 0.66, blue: 0.36).opacity(
                0.16 + Double(2 - ridge) * 0.08),
              color.opacity(0.22 + Double(ridge) * 0.08),
              Color(red: 0.12, green: 0.045, blue: 0.015).opacity(0.74),
            ]),
            startPoint: CGPoint(x: ridgeRect.midX, y: ridgeRect.minY),
            endPoint: CGPoint(x: ridgeRect.midX, y: ridgeRect.maxY)
          )
        )

        let path = earthRidge(in: ridgeRect, seed: 7 + ridge * 5, closesAtBottom: false)
        var glow = terrain
        glow.addFilter(.blur(radius: 3 + CGFloat(ridge)))
        glow.stroke(
          path,
          with: .color(color.opacity((0.16 + Double(2 - ridge) * 0.06) + energy * 0.08)),
          lineWidth: 5 - CGFloat(ridge)
        )
        terrain.stroke(
          path,
          with: .color(
            (ridge == 0 ? Color.white : color)
              .opacity(0.34 - Double(ridge) * 0.06 + energy * 0.14)
          ),
          style: StrokeStyle(
            lineWidth: 1.15 + CGFloat(2 - ridge) * 0.32,
            lineCap: .round,
            lineJoin: .round
          )
        )
      }

      for index in 0..<7 {
        let angle = Double(index) * .pi / 6 + .pi
        let edge = CGPoint(
          x: center.x + cos(angle) * radius,
          y: center.y + sin(angle) * radius
        )
        let anchorOffset = CGFloat(abs(index - 3))
        let anchor = CGPoint(
          x: center.x + CGFloat(index - 3) * radius * 0.16,
          y: center.y + radius * (0.1 + anchorOffset * 0.035)
        )
        var meridian = Path()
        meridian.move(to: edge)
        meridian.addLine(to: anchor)
        context.stroke(
          meridian,
          with: .color(color.opacity(0.12 + energy * 0.1)),
          style: StrokeStyle(lineWidth: index.isMultiple(of: 3) ? 1.1 : 0.55, dash: [4, 5])
        )
      }

      context.stroke(
        seal,
        with: .color(color.opacity(0.42 + energy * 0.2)),
        style: StrokeStyle(lineWidth: 1.35 + energy, dash: [8, 4, 2, 4])
      )
      context.stroke(
        Path(ellipseIn: sealRect.insetBy(dx: radius * 0.1, dy: radius * 0.1)),
        with: .color(Color.white.opacity(0.16 + energy * 0.12)),
        lineWidth: 0.65
      )
    }
    .frame(width: diameter, height: diameter)
    .rotationEffect(.degrees(sin(time * 0.45) * 0.5))
  }

  private func earthRidge(in rect: CGRect, seed: Int, closesAtBottom: Bool) -> Path {
    Path { path in
      let pointCount = 14
      if closesAtBottom {
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      }
      for index in 0...pointCount {
        let fraction = CGFloat(index) / CGFloat(pointCount)
        let x = rect.minX + rect.width * fraction
        let hash = abs(sin(Double((index + 3) * (seed + 5)) * 1.73))
        let accent = (index + seed) % 6 == 0 ? 0.22 : 0
        let height = min(0.82, 0.16 + hash * 0.43 + accent)
        let y = rect.maxY - rect.height * CGFloat(height)
        if index == 0 && !closesAtBottom {
          path.move(to: CGPoint(x: x, y: y))
        } else {
          path.addLine(to: CGPoint(x: x, y: y))
        }
      }
      if closesAtBottom {
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
      }
    }
  }
}

struct WaterTideFormation: View {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let color: Color

  var body: some View {
    Canvas(rendersAsynchronously: true) { context, size in
      let center = CGPoint(x: size.width / 2, y: size.height / 2)
      let radius = min(size.width, size.height) * 0.46
      let sealRect = CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
      )
      let seal = Path(ellipseIn: sealRect)
      var tide = context
      tide.clip(to: seal)

      for band in 0..<4 {
        let waveRect = CGRect(
          x: sealRect.minX - radius * 0.06,
          y: center.y - radius * 0.08 + CGFloat(band) * radius * 0.17,
          width: sealRect.width + radius * 0.12,
          height: radius * 0.88
        )
        let wavePhase = time * (1.05 + Double(band) * 0.14) + Double(band) * 0.8
        let wave = tideWave(
          in: waveRect,
          phase: wavePhase,
          closesAtBottom: true
        )
        tide.fill(
          wave,
          with: .linearGradient(
            Gradient(colors: [
              Color.white.opacity((0.12 - Double(band) * 0.018) + energy * 0.05),
              color.opacity(0.2 + Double(band) * 0.055),
              Color(red: 0.015, green: 0.08, blue: 0.2).opacity(0.54),
            ]),
            startPoint: CGPoint(x: center.x, y: waveRect.minY),
            endPoint: CGPoint(x: center.x, y: waveRect.maxY)
          )
        )
        tide.stroke(
          tideWave(
            in: waveRect,
            phase: wavePhase,
            closesAtBottom: false
          ),
          with: .color(
            (band == 0 ? Color.white : color)
              .opacity(0.42 - Double(band) * 0.06 + energy * 0.12)
          ),
          style: StrokeStyle(
            lineWidth: 1.45 - CGFloat(band) * 0.17,
            lineCap: .round,
            lineJoin: .round
          )
        )

        let foam = tideFoam(in: waveRect, phase: wavePhase)
        var foamGlow = tide
        foamGlow.addFilter(.blur(radius: 3 + CGFloat(band)))
        foamGlow.stroke(
          foam,
          with: .color(Color.white.opacity(0.24 + energy * 0.12)),
          style: StrokeStyle(lineWidth: 4 + CGFloat(band), lineCap: .round)
        )
        tide.stroke(
          foam,
          with: .color(Color.white.opacity(0.58 - Double(band) * 0.065 + energy * 0.1)),
          style: StrokeStyle(lineWidth: 0.85, lineCap: .round, lineJoin: .round)
        )
      }

      for index in 0..<22 {
        let seed = Double(index + 1)
        let x =
          sealRect.minX + sealRect.width
          * CGFloat(
            abs(sin(seed * 9.73)).truncatingRemainder(dividingBy: 1)
          )
        let travel = (time * (58 + seed.truncatingRemainder(dividingBy: 31)) + seed * 13)
          .truncatingRemainder(dividingBy: Double(radius * 1.08))
        let y = sealRect.minY + CGFloat(travel)
        let length = radius * CGFloat(0.055 + seed.truncatingRemainder(dividingBy: 4) * 0.012)
        var rain = Path()
        rain.move(to: CGPoint(x: x, y: y))
        rain.addLine(to: CGPoint(x: x - length * 0.12, y: y + length))
        tide.stroke(
          rain,
          with: .color(
            (index.isMultiple(of: 5) ? Color.white : color)
              .opacity(0.22 + Double(index % 4) * 0.055 + energy * 0.08)
          ),
          style: StrokeStyle(lineWidth: index.isMultiple(of: 5) ? 1.25 : 0.62, lineCap: .round)
        )
      }

      for index in 0..<6 {
        let phase = (time * 0.72 + Double(index) * 0.19).truncatingRemainder(dividingBy: 1)
        let rippleRadius = radius * CGFloat(0.06 + phase * 0.16)
        let x = center.x + sin(Double(index) * 2.34) * radius * 0.54
        let y = center.y + radius * CGFloat(0.28 + Double(index % 3) * 0.12)
        context.stroke(
          Path(
            ellipseIn: CGRect(
              x: x - rippleRadius,
              y: y - rippleRadius * 0.2,
              width: rippleRadius * 2,
              height: rippleRadius * 0.4
            )
          ),
          with: .color(color.opacity((1 - phase) * (0.28 + energy * 0.12))),
          lineWidth: 0.75
        )
      }

      context.stroke(
        seal,
        with: .color(color.opacity(0.46 + energy * 0.2)),
        style: StrokeStyle(lineWidth: 1.35 + energy, dash: [10, 4, 2, 4])
      )
      context.stroke(
        Path(ellipseIn: sealRect.insetBy(dx: radius * 0.11, dy: radius * 0.11)),
        with: .color(Color.white.opacity(0.18 + energy * 0.12)),
        lineWidth: 0.65
      )
    }
    .frame(width: diameter, height: diameter)
    .shadow(color: color.opacity(0.5), radius: 7 + energy * 7)
  }

  private func tideWave(in rect: CGRect, phase: Double, closesAtBottom: Bool) -> Path {
    Path { path in
      if closesAtBottom {
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      }
      for index in 0...64 {
        let fraction = CGFloat(index) / 64
        let primary = sin(Double(fraction) * .pi * 2.35 - phase)
        let chop = sin(Double(fraction) * .pi * 5.7 - phase * 1.45) * 0.17
        let crest = max(0, primary) * 0.12
        let y = rect.minY + rect.height * CGFloat(0.37 - primary * 0.16 - chop - crest)
        let point = CGPoint(x: rect.minX + rect.width * fraction, y: y)
        if index == 0 && !closesAtBottom {
          path.move(to: point)
        } else {
          path.addLine(to: point)
        }
      }
      if closesAtBottom {
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
      }
    }
  }

  private func tideFoam(in rect: CGRect, phase: Double) -> Path {
    Path { path in
      var drawing = false
      for index in 0...64 {
        let fraction = CGFloat(index) / 64
        let primary = sin(Double(fraction) * .pi * 2.35 - phase)
        let chop = sin(Double(fraction) * .pi * 5.7 - phase * 1.45) * 0.17
        let crest = max(0, primary) * 0.12
        let point = CGPoint(
          x: rect.minX + rect.width * fraction,
          y: rect.minY + rect.height * CGFloat(0.37 - primary * 0.16 - chop - crest)
        )
        guard primary > 0.42 else {
          drawing = false
          continue
        }
        drawing ? path.addLine(to: point) : path.move(to: point)
        drawing = true
      }
    }
  }
}
