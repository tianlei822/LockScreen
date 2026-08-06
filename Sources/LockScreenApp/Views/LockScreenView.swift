import AppKit
import LockScreenCore
import SwiftUI

struct LockScreenView: View {
  @State private var flow: LockFlow

  init(initialTheme: DoorTheme = .wood, vaultPasscode: String = "1024") {
    _flow = State(initialValue: LockFlow(theme: initialTheme, vaultPasscode: vaultPasscode))
  }

  var body: some View {
    let palette = flow.theme.palette

    GeometryReader { proxy in
      ZStack {
        DoorStageView(theme: flow.theme, phase: flow.phase, formationEnergy: flow.formationEnergy)
          .frame(width: proxy.size.width, height: proxy.size.height)
          .ignoresSafeArea()

        LinearGradient(
          colors: [.black.opacity(0.38), .clear, .black.opacity(0.46)],
          startPoint: .top,
          endPoint: .bottom
        )
        .allowsHitTesting(false)

        VStack(spacing: 0) {
          header(palette: palette)

          Spacer(minLength: 24)

          switch flow.theme {
          case .wood:
            WoodDoorRingView(knockCount: flow.woodKnockCount, onKnock: knockWoodDoor)
              .ignoresSafeArea()
          case .formation:
            FormationTraceView(
              trajectory: flow.formationTrajectory,
              energy: flow.formationEnergy,
              onSelectTrajectory: selectFormationTrajectory,
              onTrace: traceFormation
            )
          case .vault:
            VaultPasscodeView(onSubmit: submitVaultPasscode)
          }
        }
        .padding(.horizontal, max(24, proxy.size.width * 0.045))
        .padding(.top, 24)
        .padding(.bottom, 28)
        .opacity(flow.phase == .awaitingSequence ? 1 : 0)
        .allowsHitTesting(flow.phase == .awaitingSequence)
        .animation(.easeOut(duration: 0.35), value: flow.phase)
      }
    }
    .preferredColorScheme(.dark)
  }

  private func header(palette: ThemePalette) -> some View {
    HStack(alignment: .top) {
      themeSelector(palette: palette)

      Spacer()

      TimelineView(.periodic(from: .now, by: 1)) { timeline in
        VStack(spacing: 3) {
          Text(timeline.date, format: .dateTime.hour().minute())
            .font(.system(size: 36, weight: .ultraLight, design: .rounded))
            .monospacedDigit()
          Text(timeline.date, format: .dateTime.weekday(.wide).month(.wide).day())
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .tracking(1.6)
            .foregroundStyle(palette.secondaryText)
        }
        .foregroundStyle(palette.primaryText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(timeline.date.formatted(date: .complete, time: .shortened))
      }

      Spacer()

      Button {
        WindowPresentation.toggle(NSApp.keyWindow ?? NSApp.windows.first)
      } label: {
        Label("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
          .labelStyle(.iconOnly)
          .frame(width: 36, height: 30)
      }
      .buttonStyle(.plain)
      .foregroundStyle(palette.secondaryText)
      .keyboardShortcut("f", modifiers: [.command, .shift])
      .accessibilityLabel("Toggle immersive mode")
      .help("Toggle immersive mode (⇧⌘F)")
    }
  }

  private func themeSelector(palette: ThemePalette) -> some View {
    HStack(spacing: 4) {
      ForEach(DoorTheme.allCases) { theme in
        Button {
          withAnimation(.easeInOut(duration: 0.45)) {
            flow.selectTheme(theme)
          }
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(theme.title)
              .font(.system(size: 12, weight: .semibold))
            Text(theme.subtitle)
              .font(.system(size: 8, weight: .medium, design: .monospaced))
              .foregroundStyle(palette.secondaryText)
          }
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(theme == flow.theme ? palette.accent.opacity(0.14) : .clear)
          .overlay(alignment: .bottom) {
            Rectangle()
              .fill(theme == flow.theme ? palette.accent : .clear)
              .frame(height: 1)
          }
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette.primaryText)
        .accessibilityLabel("Use \(theme.title) theme")
      }
    }
  }

  private func knockWoodDoor() {
    guard flow.knockWoodDoor() == .completed else { return }

    beginUnlockSequence()
  }

  private func selectFormationTrajectory(_ trajectory: FormationTrajectory) {
    withAnimation(.easeInOut(duration: 0.35)) {
      flow.selectFormationTrajectory(trajectory)
    }
  }

  private func traceFormation(_ score: Double) {
    guard flow.applyFormationTrace(score: score) == .activated else { return }

    beginUnlockSequence()
  }

  private func submitVaultPasscode(_ passcode: String) -> VaultPasscodeResult {
    let result = flow.submitVaultPasscode(passcode)
    if result == .completed {
      beginUnlockSequence()
    }
    return result
  }

  private func beginUnlockSequence() {
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(1_450))
      guard flow.phase == .unlocking else { return }
      flow.finishUnlockAnimation()
      flow.finishReveal()
      returnToDesktop()
    }
  }

  @MainActor
  private func returnToDesktop() {
    NSApp.hide(nil)
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }
}
