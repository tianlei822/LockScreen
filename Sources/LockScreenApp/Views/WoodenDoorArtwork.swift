import SwiftUI

struct WoodenDoorArtwork: View {
  private let darkWood = Color(red: 0.14, green: 0.065, blue: 0.026)
  private let warmWood = Color(red: 0.42, green: 0.19, blue: 0.065)
  private let edgeWood = Color(red: 0.075, green: 0.032, blue: 0.016)
  private let brass = Color(red: 0.76, green: 0.55, blue: 0.24)

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size

      ZStack {
        LinearGradient(
          colors: [edgeWood, warmWood, darkWood, edgeWood],
          startPoint: .leading,
          endPoint: .trailing
        )

        woodGrain(size: size)

        ForEach(0..<2, id: \.self) { column in
          ForEach(0..<2, id: \.self) { row in
            carvedPanel(column: column, row: row, size: size)
          }
        }

        Rectangle()
          .fill(edgeWood.opacity(0.92))
          .frame(width: 5)

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
    }
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

  private func carvedPanel(column: Int, row: Int, size: CGSize) -> some View {
    let halfWidth = size.width / 2
    let x = CGFloat(column) * halfWidth + halfWidth / 2
    let panelHeight = size.height * (row == 0 ? 0.29 : 0.37)
    let y = size.height * (row == 0 ? 0.25 : 0.68)

    return RoundedRectangle(cornerRadius: 4)
      .fill(darkWood.opacity(0.36))
      .overlay {
        RoundedRectangle(cornerRadius: 4)
          .stroke(brass.opacity(0.18), lineWidth: 1)
          .padding(5)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 2)
          .stroke(Color.black.opacity(0.56), lineWidth: 3)
      }
      .frame(width: halfWidth - 52, height: panelHeight)
      .position(x: x, y: y)
  }

}
