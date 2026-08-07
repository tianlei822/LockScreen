import SwiftUI

struct WoodenDoorArtwork: View {
  let knockCount: Int

  private let darkWood = Color(red: 0.11, green: 0.052, blue: 0.024)
  private let warmWood = Color(red: 0.34, green: 0.15, blue: 0.055)
  private let edgeWood = Color(red: 0.052, green: 0.025, blue: 0.014)
  private let brass = Color(red: 0.76, green: 0.55, blue: 0.24)

  @State private var rippleProgress = 1.0

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size

      ZStack {
        LinearGradient(
          colors: [edgeWood, warmWood, darkWood, edgeWood],
          startPoint: .leading,
          endPoint: .trailing
        )

        plankDepth(size: size)

        woodGrain(size: size)

        woodKnots(size: size)

        agedWoodWear(size: size)

        ForEach(0..<2, id: \.self) { column in
          ForEach(0..<2, id: \.self) { row in
            carvedPanel(column: column, row: row, size: size)
          }
        }

        doorSeam(size: size)

        knockSeals(size: size)

        knockResponse(size: size)

        WoodDoorOrnamentLayer(knockCount: knockCount)

        ForEach(0..<12, id: \.self) { index in
          Circle()
            .fill(brass.opacity(0.76))
            .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1))
            .frame(width: 8, height: 8)
            .position(
              x: index.isMultiple(of: 2) ? 18 : size.width - 18,
              y: 28 + CGFloat(index / 2) * (size.height - 56) / 5
            )
        }
      }
      .overlay {
        Rectangle()
          .stroke(edgeWood, lineWidth: 10)
          .padding(5)
      }
      .onChange(of: knockCount) { _, count in
        guard count > 0 else { return }
        rippleProgress = 0
        DispatchQueue.main.async {
          withAnimation(.easeOut(duration: 0.68)) {
            rippleProgress = 1
          }
        }
      }
    }
  }

  private func plankDepth(size: CGSize) -> some View {
    HStack(spacing: 0) {
      ForEach(0..<8, id: \.self) { index in
        LinearGradient(
          colors: [
            Color.white.opacity(index.isMultiple(of: 2) ? 0.035 : 0.012),
            .clear,
            Color.black.opacity(index.isMultiple(of: 3) ? 0.2 : 0.1),
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
        .overlay(alignment: .trailing) {
          Rectangle().fill(edgeWood.opacity(0.48)).frame(width: 1)
        }
      }
    }
    .frame(width: size.width, height: size.height)
    .allowsHitTesting(false)
  }

  private func woodGrain(size: CGSize) -> some View {
    Canvas { context, _ in
      for index in 0..<25 {
        let y = CGFloat(index + 1) * size.height / 26
        let bend = CGFloat((index % 5) - 2) * 4
        var path = Path()
        path.move(to: CGPoint(x: 12, y: y))
        path.addCurve(
          to: CGPoint(x: size.width - 12, y: y + bend),
          control1: CGPoint(x: size.width * 0.28, y: y - 8 - bend),
          control2: CGPoint(x: size.width * 0.72, y: y + 8 + bend)
        )
        context.stroke(
          path, with: .color(Color.white.opacity(index.isMultiple(of: 3) ? 0.045 : 0.022)),
          lineWidth: 1)
      }

      for index in 1..<8 {
        let x = CGFloat(index) * size.width / 8
        var seam = Path()
        seam.move(to: CGPoint(x: x, y: 10))
        seam.addLine(to: CGPoint(x: x + CGFloat(index % 2) * 2, y: size.height - 10))
        context.stroke(seam, with: .color(edgeWood.opacity(0.54)), lineWidth: 1.5)
      }
    }
    .allowsHitTesting(false)
  }

  private func woodKnots(size: CGSize) -> some View {
    Canvas { context, _ in
      let positions = [
        CGPoint(x: size.width * 0.16, y: size.height * 0.16),
        CGPoint(x: size.width * 0.82, y: size.height * 0.38),
        CGPoint(x: size.width * 0.28, y: size.height * 0.78),
        CGPoint(x: size.width * 0.69, y: size.height * 0.88),
      ]

      for (index, position) in positions.enumerated() {
        for ring in 0..<3 {
          let width = CGFloat(18 + ring * 13 + index * 2)
          let height = width * 0.42
          let rect = CGRect(
            x: position.x - width / 2,
            y: position.y - height / 2,
            width: width,
            height: height
          )
          context.stroke(
            Path(ellipseIn: rect),
            with: .color(Color.black.opacity(0.15 - Double(ring) * 0.025)),
            lineWidth: ring == 0 ? 2 : 1
          )
        }
      }
    }
    .allowsHitTesting(false)
  }

  private func agedWoodWear(size: CGSize) -> some View {
    Canvas { context, _ in
      drawDampStains(in: &context, size: size)
      drawLongitudinalFibers(in: &context, size: size)
      drawBranchingCracks(in: &context, size: size)
      drawScratches(in: &context, size: size)
    }
    .overlay {
      LinearGradient(
        colors: [
          Color(red: 0.72, green: 0.68, blue: 0.57).opacity(0.08),
          .clear,
          Color.black.opacity(0.2),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .blendMode(.softLight)
    }
    .allowsHitTesting(false)
  }

  private func drawDampStains(in context: inout GraphicsContext, size: CGSize) {
    let stains: [(CGPoint, CGSize, Double)] = [
      (CGPoint(x: size.width * 0.2, y: size.height * 0.08), CGSize(width: 96, height: 170), 0.1),
      (
        CGPoint(x: size.width * 0.78, y: size.height * 0.58), CGSize(width: 120, height: 230), 0.075
      ),
      (CGPoint(x: size.width * 0.44, y: size.height * 0.96), CGSize(width: 180, height: 90), 0.13),
    ]

    var blurred = context
    blurred.addFilter(.blur(radius: 18))
    for (center, stainSize, opacity) in stains {
      let rect = CGRect(
        x: center.x - stainSize.width / 2,
        y: center.y - stainSize.height / 2,
        width: stainSize.width,
        height: stainSize.height
      )
      blurred.fill(Path(ellipseIn: rect), with: .color(Color.black.opacity(opacity)))
    }
  }

  private func drawLongitudinalFibers(in context: inout GraphicsContext, size: CGSize) {
    for index in 0..<52 {
      let seed = Double(index + 1)
      let plank = CGFloat(index % 8)
      let x = (plank + 0.12 + CGFloat(abs(sin(seed * 4.73))) * 0.76) * size.width / 8
      let startY = size.height * CGFloat(abs(sin(seed * 8.31)) * 0.86)
      let length = size.height * CGFloat(0.06 + abs(sin(seed * 2.17)) * 0.22)
      let drift = CGFloat(sin(seed * 7.41)) * 5

      var fiber = Path()
      fiber.move(to: CGPoint(x: x, y: startY))
      fiber.addCurve(
        to: CGPoint(x: x + drift, y: min(size.height, startY + length)),
        control1: CGPoint(x: x - drift * 0.6, y: startY + length * 0.3),
        control2: CGPoint(x: x + drift * 1.2, y: startY + length * 0.72)
      )
      context.stroke(
        fiber,
        with: .color(
          index.isMultiple(of: 4)
            ? Color.black.opacity(0.24)
            : Color(red: 0.82, green: 0.7, blue: 0.5).opacity(0.075)
        ),
        style: StrokeStyle(
          lineWidth: index.isMultiple(of: 7) ? 1.35 : 0.55,
          lineCap: .round
        )
      )
    }
  }

  private func drawBranchingCracks(in context: inout GraphicsContext, size: CGSize) {
    let origins = [
      CGPoint(x: size.width * 0.11, y: size.height * 0.22),
      CGPoint(x: size.width * 0.36, y: size.height * 0.64),
      CGPoint(x: size.width * 0.63, y: size.height * 0.14),
      CGPoint(x: size.width * 0.88, y: size.height * 0.72),
    ]

    for (index, origin) in origins.enumerated() {
      let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
      let depth = size.height * (0.11 + CGFloat(index) * 0.018)
      var crack = Path()
      crack.move(to: origin)
      crack.addLine(to: CGPoint(x: origin.x + direction * 4, y: origin.y + depth * 0.32))
      crack.addLine(to: CGPoint(x: origin.x - direction * 3, y: origin.y + depth * 0.66))
      crack.addLine(to: CGPoint(x: origin.x + direction * 6, y: origin.y + depth))
      context.stroke(
        crack,
        with: .color(Color.black.opacity(0.62)),
        style: StrokeStyle(lineWidth: 1.4 + CGFloat(index % 2) * 0.7, lineCap: .round)
      )

      var split = Path()
      split.move(to: CGPoint(x: origin.x + direction * 1.5, y: origin.y + depth * 0.47))
      split.addCurve(
        to: CGPoint(x: origin.x + direction * 18, y: origin.y + depth * 0.7),
        control1: CGPoint(x: origin.x + direction * 8, y: origin.y + depth * 0.5),
        control2: CGPoint(x: origin.x + direction * 9, y: origin.y + depth * 0.66)
      )
      context.stroke(split, with: .color(Color.black.opacity(0.48)), lineWidth: 0.9)

      var wornEdge = crack
      wornEdge = wornEdge.offsetBy(dx: direction * 1.2, dy: 0)
      context.stroke(
        wornEdge,
        with: .color(Color(red: 0.72, green: 0.57, blue: 0.36).opacity(0.12)),
        lineWidth: 0.6
      )
    }
  }

  private func drawScratches(in context: inout GraphicsContext, size: CGSize) {
    for index in 0..<18 {
      let seed = Double(index + 3)
      let x = size.width * CGFloat(0.08 + abs(sin(seed * 2.91)) * 0.84)
      let y = size.height * CGFloat(0.08 + abs(sin(seed * 6.17)) * 0.84)
      let length = CGFloat(7 + abs(sin(seed * 4.37)) * 19)
      var scratch = Path()
      scratch.move(to: CGPoint(x: x, y: y))
      scratch.addLine(to: CGPoint(x: x + sin(seed) * 4, y: y + length))
      context.stroke(
        scratch,
        with: .color(Color(red: 0.84, green: 0.7, blue: 0.5).opacity(0.1)),
        lineWidth: 0.65
      )
    }
  }

  private func carvedPanel(column: Int, row: Int, size: CGSize) -> some View {
    let halfWidth = size.width / 2
    let x = CGFloat(column) * halfWidth + halfWidth / 2
    let panelHeight = size.height * (row == 0 ? 0.29 : 0.37)
    let y = size.height * (row == 0 ? 0.25 : 0.68)

    return RoundedRectangle(cornerRadius: 4)
      .fill(
        LinearGradient(
          colors: [Color.black.opacity(0.46), darkWood.opacity(0.18), warmWood.opacity(0.15)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .stroke(brass.opacity(0.18), lineWidth: 1)
          .padding(5)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .stroke(Color.black.opacity(0.56), lineWidth: 3)
      }
      .overlay {
        CarvedWoodMotif()
          .stroke(brass.opacity(0.13), lineWidth: 1)
          .padding(18)
      }
      .frame(width: halfWidth - 52, height: panelHeight)
      .position(x: x, y: y)
  }

  private func doorSeam(size: CGSize) -> some View {
    let charge = Double(knockCount) / 3

    return ZStack {
      Rectangle()
        .fill(edgeWood.opacity(0.94))
        .frame(width: 7)
      Rectangle()
        .fill(brass.opacity(0.08 + charge * 0.34))
        .frame(width: 1.5)
        .shadow(color: Color.orange.opacity(charge * 0.8), radius: 5 + charge * 8)
    }
    .frame(height: size.height)
    .allowsHitTesting(false)
  }

  private func knockSeals(size: CGSize) -> some View {
    VStack(spacing: 13) {
      ForEach(0..<3, id: \.self) { index in
        Diamond()
          .fill(index < knockCount ? brass : edgeWood)
          .overlay(Diamond().stroke(brass.opacity(0.62), lineWidth: 1))
          .frame(width: 8, height: 8)
          .shadow(color: index < knockCount ? Color.orange.opacity(0.9) : .clear, radius: 6)
      }
    }
    .position(x: size.width / 2, y: size.height * 0.68)
    .allowsHitTesting(false)
  }

  private func knockResponse(size: CGSize) -> some View {
    let remaining = 1 - rippleProgress
    let unit = min(size.width, size.height)

    return ZStack {
      ForEach(0..<3, id: \.self) { index in
        let delayedProgress = max(
          0,
          min(1, rippleProgress * 1.24 - Double(index) * 0.13)
        )
        let diameter = unit * (0.18 + delayedProgress * (0.7 + Double(index) * 0.12))
        Circle()
          .stroke(
            brass.opacity((1 - delayedProgress) * (0.72 - Double(index) * 0.11)),
            lineWidth: 5 - CGFloat(index) * 0.8
          )
          .frame(width: diameter, height: diameter)
          .shadow(color: Color.orange.opacity((1 - delayedProgress) * 0.3), radius: 10)
      }

      RoundedRectangle(cornerRadius: 8)
        .stroke(brass.opacity(remaining * 0.32), lineWidth: 3)
        .frame(
          width: size.width * (0.78 + rippleProgress * 0.14),
          height: size.height * (0.6 + rippleProgress * 0.28)
        )

      RadialGradient(
        colors: [Color.orange.opacity(remaining * 0.16), .clear],
        center: .center,
        startRadius: 0,
        endRadius: max(size.width, size.height) * 0.42
      )
    }
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

}

private struct CarvedWoodMotif: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addCurve(
      to: CGPoint(x: rect.midX, y: rect.maxY),
      control1: CGPoint(x: rect.minX, y: rect.midY * 0.72),
      control2: CGPoint(x: rect.maxX, y: rect.midY * 1.28)
    )
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addCurve(
      to: CGPoint(x: rect.maxX, y: rect.midY),
      control1: CGPoint(x: rect.midX * 0.72, y: rect.minY),
      control2: CGPoint(x: rect.midX * 1.28, y: rect.maxY)
    )
    return path
  }
}

private struct Diamond: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.midX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
      path.closeSubpath()
    }
  }
}
