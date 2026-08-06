import LockScreenCore
import SwiftUI

private enum DoorSide {
  case left
  case right
}

struct DoorStageView: View {
  let theme: DoorTheme
  let phase: LockPhase
  let formationEnergy: Double

  private var isOpen: Bool { phase != .awaitingSequence }

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size

      ZStack {
        PortalRevealView(theme: theme, isOpen: isOpen)

        HStack(spacing: 1) {
          leaf(side: .left, fullSize: size)
            .rotation3DEffect(
              .degrees(isOpen ? -104 : 0),
              axis: (x: 0, y: 1, z: 0),
              anchor: .leading,
              perspective: 0.62
            )
            .offset(x: isOpen ? -size.width * 0.06 : 0)

          leaf(side: .right, fullSize: size)
            .rotation3DEffect(
              .degrees(isOpen ? 104 : 0),
              axis: (x: 0, y: 1, z: 0),
              anchor: .trailing,
              perspective: 0.62
            )
            .offset(x: isOpen ? size.width * 0.06 : 0)
        }
      }
      .background(Color.black)
      .clipped()
    }
    .animation(.easeInOut(duration: 1.45), value: isOpen)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(theme.title), \(isOpen ? "open" : "sealed")")
  }

  private func leaf(side: DoorSide, fullSize: CGSize) -> some View {
    DoorArtworkView(theme: theme, phase: phase, formationEnergy: formationEnergy)
      .frame(width: fullSize.width, height: fullSize.height)
      .offset(x: side == .left ? fullSize.width / 4 : -fullSize.width / 4)
      .frame(width: fullSize.width / 2, height: fullSize.height)
      .clipped()
  }
}

private struct DoorArtworkView: View {
  let theme: DoorTheme
  let phase: LockPhase
  let formationEnergy: Double

  @ViewBuilder
  var body: some View {
    switch theme {
    case .wood:
      WoodenDoorArtwork()
    case .formation:
      FormationDoorArtwork(
        energy: formationEnergy,
        isActivated: phase != .awaitingSequence
      )
    case .vault:
      VaultDoorArtwork()
    }
  }
}

private struct PortalRevealView: View {
  let theme: DoorTheme
  let isOpen: Bool

  var body: some View {
    let palette = theme.palette

    GeometryReader { proxy in
      let unit = min(proxy.size.width, proxy.size.height)

      ZStack {
        RadialGradient(
          colors: [palette.accentSoft, palette.haze, palette.backdrop],
          center: .center,
          startRadius: 20,
          endRadius: max(proxy.size.width, proxy.size.height) * 0.68
        )

        Circle()
          .fill(palette.accent.opacity(0.24))
          .blur(radius: unit * 0.08)
          .frame(width: unit * 0.52, height: unit * 0.52)

        VStack(spacing: 18) {
          Text(portalSymbol)
            .font(.system(size: unit * 0.16, weight: .ultraLight))
          Text("THRESHOLD OPEN")
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .tracking(6)
        }
        .foregroundStyle(palette.primaryText)
        .opacity(isOpen ? 1 : 0.35)
        .scaleEffect(isOpen ? 1 : 0.82)
      }
    }
  }

  private var portalSymbol: String {
    switch theme {
    case .wood:
      "✦"
    case .formation:
      "◇"
    case .vault:
      "▣"
    }
  }
}
