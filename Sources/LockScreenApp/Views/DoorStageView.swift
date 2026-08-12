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
  let formationTrajectory: FormationTrajectory
  let woodKnockCount: Int
  let onSolarActivate: () -> Void

  @State private var rendersSplitDoors = false
  @State private var splitDoorsOpen = false

  private var isOpen: Bool { phase != .awaitingSequence }

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size

      ZStack {
        PortalRevealView(theme: theme, isOpen: isOpen)

        if theme == .solar {
          SolarSystemArtwork(isActivated: isOpen, onActivate: onSolarActivate)
        } else if rendersSplitDoors {
          HStack(spacing: 1) {
            leaf(side: .left, fullSize: size)
              .rotation3DEffect(
                .degrees(splitDoorsOpen ? -104 : 0),
                axis: (x: 0, y: 1, z: 0),
                anchor: .leading,
                perspective: 0.62
              )
              .offset(x: splitDoorsOpen ? -size.width * 0.06 : 0)

            leaf(side: .right, fullSize: size)
              .rotation3DEffect(
                .degrees(splitDoorsOpen ? 104 : 0),
                axis: (x: 0, y: 1, z: 0),
                anchor: .trailing,
                perspective: 0.62
              )
              .offset(x: splitDoorsOpen ? size.width * 0.06 : 0)
          }
          .animation(.easeInOut(duration: 1.45), value: splitDoorsOpen)
          .transition(.identity)
        } else {
          // While sealed, both clipped leaves show halves of the same full
          // artwork. Render that artwork once and only create split copies when
          // the door actually opens; Five Phases is otherwise needlessly built
          // and rasterized twice on its first frame.
          DoorArtworkView(
            theme: theme,
            phase: phase,
            formationEnergy: formationEnergy,
            formationTrajectory: formationTrajectory,
            woodKnockCount: woodKnockCount
          )
          .frame(width: size.width, height: size.height)
          .transition(.identity)
        }

        // Light spilling through the seam as the doors part.
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                theme.palette.accentSoft.opacity(0),
                theme.palette.accent.opacity(0.9),
                theme.palette.accentSoft.opacity(0),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: 70, height: size.height)
          .blur(radius: 26)
          .scaleEffect(x: isOpen ? 2.4 : 0.15)
          .opacity(isOpen ? 0.8 : 0)
          .blendMode(.plusLighter)
          .allowsHitTesting(false)

        ThresholdDetailOverlay(theme: theme, isOpen: isOpen)
      }
      .background(Color.black)
      .clipped()
      .onChange(of: isOpen) {
        prepareDoorPresentation(isOpen: isOpen)
      }
    }
    .animation(.easeInOut(duration: 1.45), value: isOpen)
    .accessibilityElement(children: theme == .solar ? .contain : .ignore)
    .accessibilityLabel("\(theme.title), \(isOpen ? "open" : "sealed")")
  }

  private func prepareDoorPresentation(isOpen: Bool) {
    guard theme != .solar else {
      splitDoorsOpen = false
      rendersSplitDoors = false
      return
    }

    guard isOpen else {
      splitDoorsOpen = false
      rendersSplitDoors = false
      return
    }

    rendersSplitDoors = true
    splitDoorsOpen = false
    Task { @MainActor in
      await Task.yield()
      splitDoorsOpen = true
    }
  }

  private func leaf(side: DoorSide, fullSize: CGSize) -> some View {
    DoorArtworkView(
      theme: theme,
      phase: phase,
      formationEnergy: formationEnergy,
      formationTrajectory: formationTrajectory,
      woodKnockCount: woodKnockCount
    )
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
  let formationTrajectory: FormationTrajectory
  let woodKnockCount: Int

  @ViewBuilder
  var body: some View {
    switch theme {
    case .solar:
      Color.black
    case .wood:
      WoodenDoorArtwork(knockCount: woodKnockCount)
    case .formation:
      FormationDoorArtwork(
        energy: formationEnergy,
        isActivated: phase != .awaitingSequence,
        trajectory: formationTrajectory
      )
    case .vault:
      VaultDoorArtwork()
    }
  }
}

private struct PortalRevealView: View {
  let theme: DoorTheme
  let isOpen: Bool
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused

  var body: some View {
    let palette = theme.palette

    TimelineView(
      .animation(minimumInterval: 1 / 24, paused: ritualAnimationsPaused)
    ) { timeline in
      let time = timeline.date.timeIntervalSinceReferenceDate

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

          Circle()
            .stroke(
              palette.accent.opacity(0.5),
              style: StrokeStyle(lineWidth: 1, dash: [3, 7])
            )
            .frame(width: unit * 0.34, height: unit * 0.34)
            .rotationEffect(.degrees(time * 10))

          Circle()
            .stroke(
              palette.detail.opacity(0.35),
              style: StrokeStyle(lineWidth: 1, dash: [10, 6])
            )
            .frame(width: unit * 0.44, height: unit * 0.44)
            .rotationEffect(.degrees(-time * 7))

          VStack(spacing: 18) {
            Text(portalSymbol)
              .font(.system(size: unit * 0.16, weight: .ultraLight))
              .shadow(color: palette.accent.opacity(0.8), radius: isOpen ? 18 : 4)
            Text("THRESHOLD OPEN")
              .font(.system(size: 12, weight: .semibold, design: .monospaced))
              .tracking(6)
          }
          .foregroundStyle(palette.primaryText)
          .opacity(isOpen ? 1 : 0.35)
          .scaleEffect(isOpen ? 1 : 0.82)
          .accessibilityHidden(!isOpen)
        }
      }
    }
  }

  private var portalSymbol: String {
    switch theme {
    case .solar:
      "☉"
    case .wood:
      "✦"
    case .formation:
      "◇"
    case .vault:
      "▣"
    }
  }
}
