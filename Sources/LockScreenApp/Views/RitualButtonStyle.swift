import SwiftUI

struct RitualButtonStyle: ButtonStyle {
  let palette: ThemePalette
  var isEmphasized = false

  @State private var isHovered = false
  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.ritualMotionReduced) private var reduceMotion

  func makeBody(configuration: Configuration) -> some View {
    let active = isEnabled && (isHovered || configuration.isPressed)

    configuration.label
      .foregroundStyle(
        isEmphasized ? palette.backdrop : (active ? palette.primaryText : palette.secondaryText)
      )
      .background {
        RoundedRectangle(cornerRadius: 6)
          .fill(
            isEmphasized
              ? palette.accent
              : palette.backdrop.opacity(reduceTransparency ? 1 : 0.8)
          )
          .overlay {
            RoundedRectangle(cornerRadius: 6)
              .fill(
                LinearGradient(
                  colors: [.white.opacity(active ? 0.14 : 0.065), .clear],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
          }
      }
      .overlay {
        RoundedRectangle(cornerRadius: 6)
          .strokeBorder(palette.detail.opacity(active ? 0.52 : 0.24), lineWidth: 1)
      }
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
      .opacity(isEnabled ? 1 : 0.4)
      .contentShape(RoundedRectangle(cornerRadius: 6))
      .onHover { isHovered = $0 }
      .animation(reduceMotion ? nil : .easeOut(duration: 0.14), value: active)
      .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
  }
}
