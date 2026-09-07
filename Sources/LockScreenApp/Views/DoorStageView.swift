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
  let onLandscapeActivate: () -> Void

  @State private var rendersSplitDoors = false
  @State private var splitDoorsOpen = false
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced

  private var isOpen: Bool { phase != .sealed }

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let palette = theme.presentationPalette

      ZStack {
        if isOpen {
          PortalRevealView(theme: theme, palette: palette, isOpen: isOpen)
            .transition(.opacity)
        }

        if theme == .solar {
          SolarSystemArtwork(isActivated: isOpen, onActivate: onSolarActivate)
        } else if rendersSplitDoors {
          HStack(spacing: 0) {
            leaf(side: .left, fullSize: size)
              .modifier(
                DoorLeafMotionModifier(
                  side: .left,
                  isOpen: splitDoorsOpen,
                  fullWidth: size.width,
                  reduceMotion: ritualMotionReduced
                )
              )

            leaf(side: .right, fullSize: size)
              .modifier(
                DoorLeafMotionModifier(
                  side: .right,
                  isOpen: splitDoorsOpen,
                  fullWidth: size.width,
                  reduceMotion: ritualMotionReduced
                )
              )
          }
          .animation(
            .easeInOut(duration: ritualMotionReduced ? 0.2 : 1.45),
            value: splitDoorsOpen
          )
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
            woodKnockCount: woodKnockCount,
            onLandscapeActivate: onLandscapeActivate
          )
          .frame(width: size.width, height: size.height)
          .transition(.identity)
        }

        // Light spilling through the seam as the doors part.
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                palette.accentSoft.opacity(0),
                palette.accent.opacity(0.9),
                palette.accentSoft.opacity(0),
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

        if theme != .landscape {
          ThresholdDetailOverlay(theme: theme, palette: palette, isOpen: isOpen)
        }
      }
      .background(Color.black)
      .clipped()
      .task(id: isOpen) {
        await prepareDoorPresentation(isOpen: isOpen)
      }
    }
    .animation(.easeInOut(duration: ritualMotionReduced ? 0.2 : 1.45), value: isOpen)
    .accessibilityElement(
      children: theme == .solar || theme == .formation || theme == .landscape ? .contain : .ignore
    )
    .accessibilityLabel(
      L10n.format(
        "%@, %@",
        theme.title,
        isOpen ? L10n.text("open") : L10n.text("sealed")
      )
    )
  }

  private func prepareDoorPresentation(isOpen: Bool) async {
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
    await Task.yield()
    guard !Task.isCancelled else { return }
    splitDoorsOpen = true
  }

  private func leaf(side: DoorSide, fullSize: CGSize) -> some View {
    DoorArtworkView(
      theme: theme,
      phase: phase,
      formationEnergy: formationEnergy,
      formationTrajectory: formationTrajectory,
      woodKnockCount: woodKnockCount,
      onLandscapeActivate: onLandscapeActivate
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
  let onLandscapeActivate: () -> Void

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
        isActivated: phase != .sealed,
        trajectory: formationTrajectory
      )
    case .landscape:
      InkLandscapeArtwork(
        isActivated: phase != .sealed,
        onBoatActivate: onLandscapeActivate
      )
    case .vault:
      VaultDoorArtwork()
    }
  }
}

private struct DoorLeafMotionModifier: ViewModifier {
  let side: DoorSide
  let isOpen: Bool
  let fullWidth: CGFloat
  let reduceMotion: Bool

  @ViewBuilder
  func body(content: Content) -> some View {
    if reduceMotion {
      content
        .opacity(isOpen ? 0 : 1)
        .offset(x: isOpen ? (side == .left ? -16 : 16) : 0)
    } else {
      content
        .rotation3DEffect(
          .degrees(isOpen ? (side == .left ? -104 : 104) : 0),
          axis: (x: 0, y: 1, z: 0),
          anchor: side == .left ? .leading : .trailing,
          perspective: 0.62
        )
        .offset(x: isOpen ? (side == .left ? -fullWidth * 0.06 : fullWidth * 0.06) : 0)
    }
  }
}

private struct PortalRevealView: View {
  let theme: DoorTheme
  let palette: ThemePalette
  let isOpen: Bool
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced

  var body: some View {
    TimelineView(
      .animation(
        minimumInterval: 1 / 24,
        paused: RitualMotionPolicy.pausesVisualEffects(
          renderingPaused: ritualAnimationsPaused,
          reduceMotion: ritualMotionReduced
        )
      )
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
            Text(L10n.text("THRESHOLD OPEN"))
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
    case .landscape:
      "山"
    case .vault:
      "▣"
    }
  }
}
