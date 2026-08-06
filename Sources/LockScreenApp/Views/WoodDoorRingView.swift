import SwiftUI

struct WoodDoorRingView: View {
  let knockCount: Int
  let onKnock: () -> Void

  var body: some View {
    GeometryReader { proxy in
      ZStack {
        HStack(spacing: min(150, proxy.size.width * 0.075)) {
          DoorRingButton(sideName: "left", knockCount: knockCount, onKnock: onKnock)
          DoorRingButton(sideName: "right", knockCount: knockCount, onKnock: onKnock)
        }
        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.54)

        VStack(spacing: 10) {
          Text("KNOCK THREE TIMES")
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
  let sideName: String
  let knockCount: Int
  let onKnock: () -> Void

  @State private var swing = 0.0
  @State private var pulse = false

  private let brass = Color(red: 0.78, green: 0.55, blue: 0.22)

  var body: some View {
    Button(action: knock) {
      ZStack(alignment: .top) {
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
          .frame(width: 48, height: 48)

        Circle()
          .stroke(brass.opacity(pulse ? 0 : 0.42), lineWidth: 1.5)
          .frame(width: pulse ? 132 : 88, height: pulse ? 132 : 88)
          .offset(y: 29)
          .animation(.easeOut(duration: 0.42), value: pulse)

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
          .offset(y: 37)
          .rotation3DEffect(
            .degrees(swing),
            axis: (x: 1, y: 0, z: 0),
            anchor: .top,
            perspective: 0.45
          )
          .shadow(color: .black.opacity(0.82), radius: 8, y: 9)
      }
      .frame(width: 140, height: 154)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Knock (sideName) door ring")
    .accessibilityValue("(knockCount) of 3 knocks")
    .help("Knock either ring three times")
  }

  private func knock() {
    swing = swing == 0 ? (sideName == "left" ? 30 : -30) : -swing
    pulse = true
    onKnock()

    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(190))
      withAnimation(.spring(response: 0.32, dampingFraction: 0.48)) {
        swing = 0
      }
      try? await Task.sleep(for: .milliseconds(240))
      pulse = false
    }
  }
}
