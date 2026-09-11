import AppKit
import SwiftUI

@MainActor
private enum WoodMaterialAsset {
  static let image: NSImage = {
    guard let url = Bundle.module.url(forResource: "WoodSurface", withExtension: "png"),
      let image = NSImage(contentsOf: url)
    else { return NSImage() }
    return image
  }()
}

struct WoodenDoorArtwork: View {
  let knockCount: Int

  private let darkWood = Color(red: 0.155, green: 0.07, blue: 0.026)
  private let warmWood = Color(red: 0.36, green: 0.16, blue: 0.055)
  private let edgeWood = Color(red: 0.055, green: 0.022, blue: 0.01)
  private let brass = Color(red: 0.8, green: 0.57, blue: 0.25)

  @State private var rippleProgress = 1.0
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size

      ZStack {
        LinearGradient(
          colors: [edgeWood, darkWood, warmWood.opacity(0.82), darkWood, edgeWood],
          startPoint: .leading,
          endPoint: .trailing
        )

        plankDepth(size: size)

        woodMaterial(size: size, alignment: .center)
          .opacity(0.6)

        agedWoodWear(size: size)

        woodGrain(size: size)
          .opacity(0.4)

        ForEach(0..<2, id: \.self) { column in
          ForEach(0..<2, id: \.self) { row in
            carvedPanel(column: column, row: row, size: size)
          }
        }

        materialLighting(size: size)

        doorSeam(size: size)

        knockSeals(size: size)

        knockResponse(size: size)

        WoodDoorOrnamentLayer(knockCount: knockCount)

        ForEach(0..<12, id: \.self) { index in
          Circle()
            .fill(
              RadialGradient(
                colors: [
                  Color(red: 0.94, green: 0.72, blue: 0.34),
                  brass,
                  Color(red: 0.19, green: 0.105, blue: 0.035),
                ],
                center: UnitPoint(x: 0.34, y: 0.3),
                startRadius: 0,
                endRadius: 6
              )
            )
            .overlay(Circle().stroke(Color.black.opacity(0.72), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.52), radius: 2, x: 1, y: 2)
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
      .task(id: knockCount) {
        guard knockCount > 0, !ritualMotionReduced else {
          rippleProgress = 1
          return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { rippleProgress = 0 }
        await Task.yield()
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.68)) {
          rippleProgress = 1
        }
      }
    }
  }

  private func woodMaterial(size: CGSize, alignment: Alignment) -> some View {
    Image(nsImage: WoodMaterialAsset.image)
      .resizable()
      .scaledToFill()
      .frame(width: size.width, height: size.height, alignment: alignment)
      .clipped()
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }

  private func plankDepth(size: CGSize) -> some View {
    HStack(spacing: 0) {
      ForEach(0..<8, id: \.self) { index in
        Rectangle()
          .fill(
            LinearGradient(
              colors: plankColors(index: index),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay {
            LinearGradient(
              colors: [
                Color.black.opacity(0.18),
                Color.white.opacity(index.isMultiple(of: 3) ? 0.05 : 0.025),
                .clear,
                Color.black.opacity(0.16),
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
            .blendMode(.softLight)
          }
          .overlay(alignment: .trailing) {
            ZStack(alignment: .trailing) {
              Rectangle().fill(Color.black.opacity(0.72)).frame(width: 1.5)
              Rectangle().fill(Color.white.opacity(0.045)).frame(width: 0.5).offset(x: -1.5)
            }
          }
      }
    }
    .frame(width: size.width, height: size.height)
    .allowsHitTesting(false)
  }

  private func woodGrain(size: CGSize, plankCount: Int = 8, seedOffset: Int = 0) -> some View {
    Canvas { context, _ in
      let plankWidth = size.width / CGFloat(plankCount)
      for plank in 0..<plankCount {
        let knotSeed = Double(plank + seedOffset + 71)
        let knotX = plankWidth * (CGFloat(plank) + 0.3 + woodHash(knotSeed) * 0.4)
        let knotY = size.height * (0.23 + woodHash(knotSeed * 3.7) * 0.54)
        let knotWidth = min(plankWidth * 0.07, 13)
        for fiber in 0..<64 {
          let seed = Double(plank * 83 + fiber + seedOffset + 7)
          let baseX =
            CGFloat(plank) * plankWidth
            + plankWidth * (CGFloat(fiber) + woodHash(seed * 2.37)) / 64
          let amplitude = min(plankWidth * 0.015, 3) * (0.3 + woodHash(seed * 5.1))
          var grain = Path()
          for step in 0...96 {
            let progress = CGFloat(step) / 96
            let phase = Double(progress) * (5.5 + woodHash(seed * 3.7) * 6.2) + seed
            let distanceX = (baseX - knotX) / max(knotWidth * 3, 1)
            let distanceY = (progress * size.height - knotY) / max(knotWidth * 7, 1)
            let deflection =
              exp(-distanceX * distanceX - distanceY * distanceY)
              * knotWidth * (baseX < knotX ? -1 : 1)
            let x =
              baseX + CGFloat(sin(phase)) * amplitude
              + CGFloat(sin(phase * 0.37)) * amplitude * 0.58 + deflection
            let point = CGPoint(x: x, y: progress * size.height)
            if step == 0 { grain.move(to: point) } else { grain.addLine(to: point) }
          }
          context.stroke(
            grain,
            with: .color(
              fiber.isMultiple(of: 5)
                ? Color.black.opacity(0.24)
                : Color(red: 0.72, green: 0.43, blue: 0.19).opacity(
                  0.08 + Double(woodHash(seed)) * 0.12)
            ),
            style: StrokeStyle(
              lineWidth: fiber.isMultiple(of: 7) ? 0.85 : 0.35,
              lineCap: .round
            )
          )
        }
        let knot = CGRect(
          x: knotX - knotWidth * 0.3, y: knotY - knotWidth * 1.8,
          width: knotWidth * 0.6, height: knotWidth * 3.6
        )
        context.fill(
          Path(ellipseIn: knot),
          with: .linearGradient(
            Gradient(colors: [.clear, edgeWood.opacity(0.65), .clear]),
            startPoint: CGPoint(x: knot.midX, y: knot.minY),
            endPoint: CGPoint(x: knot.midX, y: knot.maxY)
          )
        )
      }

      for index in 0..<400 {
        let seed = Double(index + 401)
        let x = size.width * woodHash(seed * 1.73)
        let y = size.height * woodHash(seed * 4.19)
        let length = 1.5 + woodHash(seed * 8.7) * 5.5
        var pore = Path()
        pore.move(to: CGPoint(x: x, y: y))
        pore.addLine(to: CGPoint(x: x + sin(seed) * 0.8, y: y + length))
        context.stroke(
          pore,
          with: .color(Color.black.opacity(0.15 + Double(index % 3) * 0.03)),
          style: StrokeStyle(lineWidth: 0.45, lineCap: .round)
        )
      }
    }
    .allowsHitTesting(false)
  }

  private func plankColors(index: Int) -> [Color] {
    switch index % 4 {
    case 0:
      [darkWood, Color(red: 0.32, green: 0.14, blue: 0.045), edgeWood]
    case 1:
      [Color(red: 0.235, green: 0.105, blue: 0.035), warmWood, darkWood]
    case 2:
      [Color(red: 0.29, green: 0.125, blue: 0.043), darkWood, warmWood.opacity(0.82)]
    default:
      [darkWood, Color(red: 0.255, green: 0.105, blue: 0.034), edgeWood]
    }
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
    let panelSize = CGSize(width: max(1, halfWidth - 52), height: panelHeight)

    return RoundedRectangle(cornerRadius: 4)
      .fill(
        LinearGradient(
          colors: [
            Color(red: 0.19, green: 0.085, blue: 0.032),
            Color(red: 0.34, green: 0.17, blue: 0.072),
            Color(red: 0.23, green: 0.105, blue: 0.038),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        woodMaterial(size: panelSize, alignment: row == 0 ? .top : .bottom)
          .scaleEffect(x: column == 0 ? 1 : -1, y: 1)
          .opacity(0.78)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .overlay {
        woodGrain(size: panelSize, plankCount: 1, seedOffset: column * 139 + row * 57)
          .opacity(0.3)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .strokeBorder(
            LinearGradient(
              colors: [edgeWood.opacity(0.95), darkWood, brass.opacity(0.18)],
              startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            lineWidth: 9
          )
      }
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .stroke(
            LinearGradient(
              colors: [
                Color(red: 0.58, green: 0.29, blue: 0.1).opacity(0.36),
                Color.black.opacity(0.18),
                edgeWood.opacity(0.82),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1.2
          )
          .padding(10)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .stroke(Color.black.opacity(0.68), lineWidth: 4)
      }
      .frame(width: panelSize.width, height: panelHeight)
      .position(x: x, y: y)
  }

  private func materialLighting(size: CGSize) -> some View {
    ZStack {
      RadialGradient(
        colors: [
          Color(red: 0.94, green: 0.62, blue: 0.28).opacity(0.16),
          Color(red: 0.5, green: 0.22, blue: 0.07).opacity(0.055),
          .clear,
        ],
        center: UnitPoint(x: 0.34, y: 0.28),
        startRadius: 0,
        endRadius: min(size.width, size.height) * 0.62
      )

      LinearGradient(
        colors: [
          Color.black.opacity(0.26),
          .clear,
          .clear,
          Color.black.opacity(0.24),
        ],
        startPoint: .leading,
        endPoint: .trailing
      )

      LinearGradient(
        colors: [Color.white.opacity(0.05), .clear, Color.black.opacity(0.15)],
        startPoint: .top,
        endPoint: .bottom
      )
    }
    .blendMode(.softLight)
    .allowsHitTesting(false)
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

private func woodHash(_ value: Double) -> CGFloat {
  CGFloat(abs(sin(value * 12.9898) * 43_758.5453).truncatingRemainder(dividingBy: 1))
}
