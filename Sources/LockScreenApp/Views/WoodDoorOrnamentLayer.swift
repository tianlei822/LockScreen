import SwiftUI

/// Structural hardware and carved trim that make the wooden surface read as a built door.
struct WoodDoorOrnamentLayer: View {
  let knockCount: Int

  private let soot = Color(red: 0.075, green: 0.031, blue: 0.016)
  private let bronze = Color(red: 0.8, green: 0.57, blue: 0.25)
  private let ember = Color(red: 1, green: 0.48, blue: 0.12)

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let charge = Double(knockCount) / 3

      ZStack {
        nestedDoorFrame(size: size, charge: charge)
        lintelAndThreshold(size: size, charge: charge)
        hingeHardware(size: size)
        cornerBraces(size: size)
        seamOrnaments(size: size, charge: charge)
      }
      .allowsHitTesting(false)
    }
  }

  private func nestedDoorFrame(size: CGSize, charge: Double) -> some View {
    ZStack {
      Rectangle()
        .stroke(
          LinearGradient(
            colors: [Color.black.opacity(0.9), bronze.opacity(0.28), Color.black.opacity(0.94)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 12
        )
        .padding(12)

      Rectangle()
        .stroke(Color.black.opacity(0.72), lineWidth: 3)
        .padding(23)

      Rectangle()
        .stroke(bronze.opacity(0.12 + charge * 0.18), lineWidth: 1)
        .padding(28)
        .shadow(color: ember.opacity(charge * 0.3), radius: 7)
    }
    .frame(width: size.width, height: size.height)
  }

  private func lintelAndThreshold(size: CGSize, charge: Double) -> some View {
    VStack(spacing: 0) {
      structuralRail(charge: charge, inverted: false)
        .frame(height: 30)

      Spacer()

      structuralRail(charge: charge, inverted: true)
        .frame(height: 38)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 16)
    .frame(width: size.width, height: size.height)
  }

  private func structuralRail(charge: Double, inverted: Bool) -> some View {
    ZStack {
      Rectangle()
        .fill(
          LinearGradient(
            colors: inverted
              ? [soot, Color.black.opacity(0.4), bronze.opacity(0.2)]
              : [bronze.opacity(0.16), Color.black.opacity(0.42), soot],
            startPoint: .top,
            endPoint: .bottom
          ))

      Rectangle()
        .stroke(Color.black.opacity(0.78), lineWidth: 2)

      HStack(spacing: 18) {
        ForEach(0..<9, id: \.self) { index in
          DiamondStud()
            .fill(index.isMultiple(of: 2) ? bronze.opacity(0.48) : bronze.opacity(0.22))
            .frame(width: 6, height: 6)
        }
      }

      Rectangle()
        .fill(bronze.opacity(0.14 + charge * 0.22))
        .frame(height: 1)
        .shadow(color: ember.opacity(charge * 0.35), radius: 5)
    }
  }

  private func hingeHardware(size: CGSize) -> some View {
    ZStack {
      ForEach(0..<6, id: \.self) { index in
        let isLeft = index.isMultiple(of: 2)
        let row = index / 2

        HingePlate()
          .fill(
            LinearGradient(
              colors: [bronze.opacity(0.5), soot, bronze.opacity(0.18)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .overlay(HingePlate().stroke(Color.black.opacity(0.8), lineWidth: 1))
          .frame(width: 46, height: 28)
          .shadow(color: Color.black.opacity(0.8), radius: 4, y: 2)
          .position(
            x: isLeft ? 31 : size.width - 31,
            y: size.height * (0.23 + Double(row) * 0.28)
          )
          .scaleEffect(x: isLeft ? 1 : -1)
      }
    }
  }

  private func cornerBraces(size: CGSize) -> some View {
    ZStack {
      ForEach(0..<4, id: \.self) { index in
        CornerBrace()
          .stroke(
            LinearGradient(
              colors: [bronze.opacity(0.52), bronze.opacity(0.12)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            style: StrokeStyle(lineWidth: 4, lineCap: .square, lineJoin: .miter)
          )
          .frame(width: 54, height: 54)
          .position(
            x: index.isMultiple(of: 2) ? 53 : size.width - 53,
            y: index < 2 ? 53 : size.height - 53
          )
          .rotationEffect(.degrees(Double(index) * 90))
      }
    }
  }

  private func seamOrnaments(size: CGSize, charge: Double) -> some View {
    VStack {
      CrownOrnament()
        .stroke(bronze.opacity(0.38 + charge * 0.2), lineWidth: 1.2)
        .frame(width: 72, height: 44)

      Spacer()

      CrownOrnament()
        .stroke(bronze.opacity(0.34 + charge * 0.22), lineWidth: 1.2)
        .frame(width: 72, height: 44)
        .rotationEffect(.degrees(180))
    }
    .padding(.vertical, 48)
    .position(x: size.width / 2, y: size.height / 2)
  }
}

private struct DiamondStud: Shape {
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

private struct HingePlate: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.minX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.minX + rect.height * 0.34, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX - rect.height * 0.22, y: rect.minY + 4))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
      path.addLine(to: CGPoint(x: rect.maxX - rect.height * 0.22, y: rect.maxY - 4))
      path.addLine(to: CGPoint(x: rect.minX + rect.height * 0.34, y: rect.maxY))
      path.closeSubpath()
    }
  }
}

private struct CornerBrace: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
      path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
      path.move(to: CGPoint(x: rect.minX + 12, y: rect.minY + 12))
      path.addLine(to: CGPoint(x: rect.maxX * 0.68, y: rect.maxY * 0.68))
    }
  }
}

private struct CrownOrnament: Shape {
  func path(in rect: CGRect) -> Path {
    Path { path in
      path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
      path.addCurve(
        to: CGPoint(x: rect.midX, y: rect.minY),
        control1: CGPoint(x: rect.width * 0.32, y: rect.maxY),
        control2: CGPoint(x: rect.width * 0.3, y: rect.height * 0.2)
      )
      path.addCurve(
        to: CGPoint(x: rect.maxX, y: rect.maxY),
        control1: CGPoint(x: rect.width * 0.7, y: rect.height * 0.2),
        control2: CGPoint(x: rect.width * 0.68, y: rect.maxY)
      )
      path.move(to: CGPoint(x: rect.midX, y: rect.height * 0.25))
      path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    }
  }
}
