import AppKit
import LockScreenCore
import SwiftUI

struct LockScreenView: View {
  @State private var flow: LockFlow
  @State private var controlsVisible = true
  @State private var controlsVisibilityTask: Task<Void, Never>?
  @State private var isImmersive = false
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  private let backgroundMode: Bool

  init(
    initialTheme: DoorTheme = .solar, vaultPasscode: String = "1024",
    backgroundMode: Bool = false
  ) {
    self.backgroundMode = backgroundMode
    _flow = State(initialValue: LockFlow(theme: initialTheme, vaultPasscode: vaultPasscode))
  }

  var body: some View {
    let palette = flow.theme.palette

    GeometryReader { proxy in
      ZStack {
        DoorStageView(
          theme: flow.theme,
          phase: flow.phase,
          formationEnergy: flow.formationEnergy,
          formationTrajectory: flow.formationTrajectory,
          woodKnockCount: flow.woodKnockCount,
          onSolarActivate: activateSolarSystem
        )
        .frame(width: proxy.size.width, height: proxy.size.height)
        .ignoresSafeArea()

        LinearGradient(
          colors: [.black.opacity(0.38), .clear, .black.opacity(0.46)],
          startPoint: .top,
          endPoint: .bottom
        )
        .allowsHitTesting(false)

        if flow.theme == .formation {
          FormationTraceView(
            trajectory: flow.formationTrajectory,
            energy: flow.formationEnergy,
            showsControls: controlsVisible,
            onSelectTrajectory: selectFormationTrajectory,
            onTrace: traceFormation
          )
          .padding(.horizontal, max(24, proxy.size.width * 0.045))
          .padding(.top, 24)
          .padding(.bottom, 28)
          .opacity(flow.phase == .awaitingSequence ? 1 : 0)
          .allowsHitTesting(flow.phase == .awaitingSequence)
          .animation(.easeOut(duration: 0.35), value: flow.phase)
        }

        VStack(spacing: 0) {
          header(palette: palette)

          Spacer(minLength: 24)

          switch flow.theme {
          case .solar:
            EmptyView()
          case .wood:
            WoodDoorRingView(knockCount: flow.woodKnockCount, onKnock: knockWoodDoor)
              .ignoresSafeArea()
          case .formation:
            EmptyView()
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
      .onContinuousHover { phase in
        if case .active = phase {
          revealControls()
        }
      }
    }
    .preferredColorScheme(.dark)
    .onAppear {
      revealControls()
      refreshImmersiveState()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
      refreshImmersiveState()
    }
    .onDisappear {
      controlsVisibilityTask?.cancel()
    }
    .onChange(of: flow.theme) {
      revealControls()
    }
  }

  private func header(palette: ThemePalette) -> some View {
    ZStack(alignment: .top) {
      TimelineView(
        .animation(minimumInterval: 1, paused: ritualAnimationsPaused)
      ) { timeline in
        VStack(spacing: 5) {
          Text(timeline.date, format: .dateTime.hour().minute())
            .font(.system(size: 64, weight: .bold, design: .rounded))
            .monospacedDigit()
          Text(timeline.date, format: .dateTime.weekday(.wide).month(.wide).day())
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .tracking(1.8)
            .foregroundStyle(palette.secondaryText)
        }
        .foregroundStyle(palette.primaryText)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(timeline.date.formatted(date: .complete, time: .shortened))
      }

      HStack {
        themeSelector(palette: palette)

        Spacer()

        if !isImmersive {
          Button {
            WindowPresentation.toggle(NSApp.keyWindow ?? NSApp.windows.first)
            refreshImmersiveState()
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
    }
    .frame(maxWidth: .infinity)
  }

  private func themeSelector(palette: ThemePalette) -> some View {
    Menu {
      ForEach(DoorTheme.allCases) { theme in
        Button {
          flow.selectTheme(theme)
        } label: {
          Label(
            theme.title,
            systemImage: theme == flow.theme ? "checkmark" : theme.symbolName
          )
        }
        .accessibilityLabel("Use \(theme.title) theme")
      }
    } label: {
      HStack(spacing: 10) {
        Image(systemName: flow.theme.symbolName)
          .font(.system(size: 15, weight: .medium))
          .frame(width: 22)

        VStack(alignment: .leading, spacing: 2) {
          Text(flow.theme.title.uppercased())
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.3)
          Text(flow.theme.subtitle)
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(palette.secondaryText)
        }

        Image(systemName: "chevron.down")
          .font(.system(size: 8, weight: .bold))
          .opacity(0.55)
      }
      .padding(.horizontal, 12)
      .frame(height: 42)
      .background(.black.opacity(0.24), in: Capsule())
      .overlay {
        Capsule()
          .stroke(palette.detail.opacity(0.24), lineWidth: 0.8)
      }
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.hidden)
    .fixedSize()
    .foregroundStyle(palette.secondaryText)
    .accessibilityLabel("Choose door theme; current theme is \(flow.theme.title)")
    .help("Choose door theme")
  }

  private func knockWoodDoor() {
    guard flow.knockWoodDoor() == .completed else { return }

    beginUnlockSequence()
  }

  private func activateSolarSystem() {
    guard flow.activateSolarSystem() == .completed else { return }

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
    controlsVisibilityTask?.cancel()
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(1_400))
      guard flow.phase == .unlocking else { return }
      flow.finishUnlockAnimation()

      try? await Task.sleep(for: .milliseconds(180))
      guard flow.phase == .open else { return }
      flow.finishReveal()
      await returnToDesktop()
    }
  }

  private func revealControls() {
    guard flow.phase == .awaitingSequence else { return }

    controlsVisibilityTask?.cancel()
    if !controlsVisible {
      withAnimation(.easeOut(duration: 0.24)) {
        controlsVisible = true
      }
    }

    controlsVisibilityTask = Task { @MainActor in
      do {
        try await Task.sleep(for: .seconds(2.8))
      } catch {
        return
      }
      guard flow.phase == .awaitingSequence else { return }
      withAnimation(.easeInOut(duration: 0.65)) {
        controlsVisible = false
      }
    }
  }

  @MainActor
  private func returnToDesktop() async {
    let ritualWindow = WindowPresentation.mainRitualWindow()
    await WindowPresentation.fadeOut(ritualWindow)

    if backgroundMode {
      // Re-seal only after the faded window is invisible, then lurk until the
      // next ⌘L instead of flashing the sealed artwork during the retreat.
      flow.reset()
      WindowPresentation.retreatToBackground(ritualWindow)
      return
    }

    NSApp.hide(nil)
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }

  private func refreshImmersiveState() {
    guard let window = WindowPresentation.mainRitualWindow() else { return }
    isImmersive = WindowPresentation.isImmersive(window)
  }
}

extension DoorTheme {
  fileprivate var symbolName: String {
    switch self {
    case .solar:
      "sun.max.fill"
    case .formation:
      "seal.fill"
    case .wood:
      "door.left.hand.closed"
    case .vault:
      "lock.square.fill"
    }
  }
}
