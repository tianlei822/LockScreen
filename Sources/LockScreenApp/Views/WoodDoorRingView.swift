import SwiftUI

private enum DoorRingSide {
  case left
  case right

  var localizedName: String {
    switch self {
    case .left: L10n.text("left")
    case .right: L10n.text("right")
    }
  }
}

struct WoodDoorRingView: View {
  let knockCount: Int
  let onKnock: () -> Void

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        HStack(spacing: min(150, proxy.size.width * 0.075)) {
          DoorRingButton(side: .left, knockCount: knockCount, onKnock: onKnock)
          DoorRingButton(side: .right, knockCount: knockCount, onKnock: onKnock)
        }
        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.54)

        VStack(spacing: 10) {
          Text(L10n.text("KNOCK THREE TIMES"))
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .tracking(4)

          HStack(spacing: 9) {
            ForEach(0..<3, id: \.self) { index in
              Circle()
                .fill(index < knockCount ? Color(red: 0.95, green: 0.69, blue: 0.31) : .clear)
                .overlay {
                  Circle()
                    .stroke(Color(red: 0.95, green: 0.69, blue: 0.31).opacity(0.7), lineWidth: 1)
                }
                .frame(width: 7, height: 7)
                .shadow(
                  color: index < knockCount ? Color.orange.opacity(0.8) : .clear,
                  radius: 6
                )
            }
          }
        }
        .foregroundStyle(Color(red: 0.93, green: 0.78, blue: 0.55).opacity(0.88))
        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.76)
        .allowsHitTesting(false)
      }
    }
  }
}

private struct DoorRingButton: View {
  let side: DoorRingSide
  let knockCount: Int
  let onKnock: () -> Void

  @State private var swing = 0.0
  @State private var rippleProgress = 1.0
  @State private var struck = false
  @State private var knockID = 0
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced

  private let brass = Color(red: 0.78, green: 0.55, blue: 0.22)

  private var strikeAngle: Double {
    let magnitude = 13 + Double(min(knockCount, 2)) * 2
    return side == .left ? magnitude : -magnitude
  }

  var body: some View {
    Button(action: knock) {
      ZStack(alignment: .top) {
        ForEach(0..<3, id: \.self) { index in
          let delayedProgress = max(
            0,
            min(1, rippleProgress * 1.28 - Double(index) * 0.14)
          )
          Circle()
            .stroke(
              brass.opacity((1 - delayedProgress) * (0.62 - Double(index) * 0.1)),
              lineWidth: 4.2 - CGFloat(index) * 0.75
            )
            .frame(width: 132, height: 132)
            .scaleEffect(0.54 + delayedProgress * (0.48 + Double(index) * 0.15))
            .offset(y: 20)
        }

        VStack(spacing: -2) {
          RoundedRectangle(cornerRadius: 3)
            .fill(brass)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black.opacity(0.65)))
            .frame(width: 12, height: 18)

          Circle()
            .stroke(
              AngularGradient(
                colors: [
                  Color.black, brass, Color(red: 1, green: 0.83, blue: 0.44), brass, Color.black,
                ],
                center: .center
              ),
              lineWidth: 11
            )
            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1).padding(4))
            .frame(width: 92, height: 92)
        }
        .frame(width: 92, height: 108, alignment: .top)
        .rotationEffect(.degrees(swing), anchor: .top)
        .offset(y: 24)
        .shadow(color: .black.opacity(0.82), radius: 8, y: 9)

        Circle()
          .fill(
            RadialGradient(
              colors: [Color(red: 0.98, green: 0.8, blue: 0.4), brass, Color.black],
              center: .topLeading,
              startRadius: 1,
              endRadius: 34
            )
          )
          .overlay(Circle().stroke(Color.black.opacity(0.72), lineWidth: 2))
          .overlay(Circle().fill(Color.white.opacity(struck ? 0.22 : 0)))
          .frame(width: 48, height: 48)
      }
      .frame(width: 140, height: 154)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(L10n.format("Knock %@ door ring", side.localizedName))
    .accessibilityValue(L10n.format("%lld of 3 knocks", knockCount))
    .help(L10n.text("Knock either ring three times"))
  }

  private func knock() {
    guard !ritualMotionReduced else {
      onKnock()
      return
    }

    knockID += 1
    let currentKnock = knockID
    var resetTransaction = Transaction()
    resetTransaction.disablesAnimations = true
    withTransaction(resetTransaction) {
      rippleProgress = 0
    }
    struck = false
    onKnock()

    // Swing the complete ring-and-link assembly around the boss's fixed pin.
    withAnimation(.easeOut(duration: 0.11)) {
      swing = strikeAngle
    }

    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(100))
      guard currentKnock == knockID else { return }

      // Impact: halo, boss flash, then a damped pendulum settle.
      struck = true
      withAnimation(.easeOut(duration: 0.68)) {
        rippleProgress = 1
      }
      withAnimation(.spring(response: 0.55, dampingFraction: 0.36)) {
        swing = 0
      }

      try? await Task.sleep(for: .milliseconds(180))
      guard currentKnock == knockID else { return }
      withAnimation(.easeOut(duration: 0.3)) {
        struck = false
      }
    }
  }
}
