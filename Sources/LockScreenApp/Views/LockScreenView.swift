import AppKit
import LockScreenCore
import SwiftUI

struct LockScreenView: View {
  @StateObject private var coordinator: RitualCoordinator
  @State private var controlsVisible = true
  @State private var controlsVisibilityTask: Task<Void, Never>?
  @State private var isThemeSelectorHovered = false
  @State private var isImmersive = false
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  private var flow: LockFlow { coordinator.flow }

  init(
    initialTheme: DoorTheme = .solar,
    vaultPasscode: String = LockFlow.defaultVaultPasscode,
    backgroundMode: Bool = false, vaultPasscodeStore: VaultPasscodeStore = VaultPasscodeStore()
  ) {
    _coordinator = StateObject(
      wrappedValue: RitualCoordinator(
        initialTheme: initialTheme,
        vaultPasscode: vaultPasscode,
        backgroundMode: backgroundMode,
        vaultPasscodeStore: vaultPasscodeStore
      )
    )
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
          .opacity(flow.phase == .sealed ? 1 : 0)
          .allowsHitTesting(flow.phase == .sealed)
          .animation(.easeOut(duration: 0.35), value: flow.phase)
        }

        VStack(spacing: 0) {
          header(palette: palette, availableWidth: proxy.size.width)

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
            VaultPasscodeView(
              onSubmit: submitVaultPasscode,
              onUpdatePasscode: updateVaultPasscode
            )
          }
        }
        .padding(.horizontal, max(24, proxy.size.width * 0.045))
        .padding(.top, isImmersive ? 24 : (flow.theme == .vault ? 32 : 48))
        .padding(.bottom, 28)
        .opacity(flow.phase == .sealed ? 1 : 0)
        .allowsHitTesting(flow.phase == .sealed)
        .animation(.easeOut(duration: 0.35), value: flow.phase)
      }
      .onContinuousHover { phase in
        if case .active = phase {
          revealControls()
        }
      }
      .onKeyPress(.tab) {
        revealControls()
        return .ignored
      }
    }
    .environment(\.ritualMotionReduced, reduceMotion)
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
      coordinator.cancel()
    }
    .onChange(of: flow.theme) {
      revealControls()
    }
    .onChange(of: flow.phase) { _, phase in
      if phase != .sealed {
        controlsVisibilityTask?.cancel()
      }
    }
  }

  private func header(palette: ThemePalette, availableWidth: CGFloat) -> some View {
    let responsiveClockSize = min(64, max(44, availableWidth * 0.055))
    let clockSize = flow.theme == .vault ? min(54, responsiveClockSize) : responsiveClockSize

    return ZStack(alignment: .top) {
      TimelineView(
        .animation(minimumInterval: 1, paused: ritualAnimationsPaused)
      ) { timeline in
        VStack(spacing: 5) {
          Text(timeline.date, format: .dateTime.hour().minute())
            .font(.system(size: clockSize, weight: .bold, design: .rounded))
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

        HStack(spacing: 8) {
          HeaderIconButton(
            systemImage: "arrow.counterclockwise",
            label: L10n.text("Reset ritual"),
            help: L10n.text("Reset ritual (R)"),
            palette: palette,
            action: resetRitual
          )
          .keyboardShortcut("r", modifiers: [])

          HeaderIconButton(
            systemImage: isImmersive
              ? "arrow.down.right.and.arrow.up.left"
              : "arrow.up.left.and.arrow.down.right",
            label: isImmersive
              ? L10n.text("Exit immersive mode") : L10n.text("Enter immersive mode"),
            help: isImmersive
              ? L10n.text("Exit immersive mode (⇧⌘F)")
              : L10n.text("Enter immersive mode (⇧⌘F)"),
            palette: palette
          ) {
            WindowPresentation.toggle(NSApp.keyWindow ?? NSApp.windows.first)
            refreshImmersiveState()
          }
          .keyboardShortcut("f", modifiers: [.command, .shift])
        }
      }
    }
    .frame(maxWidth: .infinity)
  }

  private func themeSelector(palette: ThemePalette) -> some View {
    Menu {
      ForEach(DoorTheme.allCases) { theme in
        Button {
          coordinator.selectTheme(theme)
        } label: {
          Label(
            theme.title,
            systemImage: theme == flow.theme ? "checkmark" : theme.symbolName
          )
        }
        .accessibilityLabel(L10n.format("Use %@ theme", theme.title))
      }
    } label: {
      HStack(spacing: 10) {
        Image(systemName: flow.theme.symbolName)
          .font(.system(size: 15, weight: .medium))
          .frame(width: 22)
          .foregroundStyle(palette.primaryText.opacity(0.88))

        VStack(alignment: .leading, spacing: 2) {
          Text(flow.theme.title)
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .tracking(1.3)
            .foregroundStyle(palette.primaryText.opacity(0.92))
            .lineLimit(1)
          Text(flow.theme.subtitle)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(palette.secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }

        Image(systemName: "chevron.down")
          .font(.system(size: 8, weight: .bold))
          .foregroundStyle(palette.secondaryText.opacity(0.72))
      }
      .padding(.horizontal, 14)
      .frame(height: 44)
      .background(
        palette.backdrop.opacity(
          reduceTransparency ? 0.96 : (isThemeSelectorHovered ? 0.4 : 0.26)
        ),
        in: RoundedRectangle(cornerRadius: 8)
      )
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(
            palette.detail.opacity(isThemeSelectorHovered ? 0.4 : 0.24),
            lineWidth: 0.8
          )
      }
    }
    .menuStyle(.borderlessButton)
    .menuIndicator(.hidden)
    .fixedSize()
    .accessibilityLabel(
      L10n.format("Choose door theme; current theme is %@", flow.theme.title)
    )
    .help(L10n.text("Choose door theme"))
    .onHover { isThemeSelectorHovered = $0 }
    .animation(.easeOut(duration: 0.18), value: isThemeSelectorHovered)
  }

  private func knockWoodDoor() {
    coordinator.knockWoodDoor()
  }

  private func resetRitual() {
    withAnimation(.easeOut(duration: 0.24)) {
      coordinator.reset()
    }
    revealControls()
  }

  private func activateSolarSystem() {
    coordinator.activateSolarSystem()
  }

  private func selectFormationTrajectory(_ trajectory: FormationTrajectory) {
    withAnimation(.easeInOut(duration: 0.35)) {
      coordinator.selectFormationTrajectory(trajectory)
    }
  }

  private func traceFormation(_ score: Double) {
    coordinator.traceFormation(score)
  }

  private func submitVaultPasscode(_ passcode: String) -> VaultPasscodeResult {
    coordinator.submitVaultPasscode(passcode)
  }

  private func updateVaultPasscode(_ passcode: String) -> Bool {
    coordinator.updateVaultPasscode(passcode)
  }

  private func revealControls() {
    guard flow.phase == .sealed else { return }

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
      guard flow.phase == .sealed else { return }
      withAnimation(.easeInOut(duration: 0.65)) {
        controlsVisible = false
      }
    }
  }

  private func refreshImmersiveState() {
    guard let window = WindowPresentation.mainRitualWindow() else { return }
    isImmersive = WindowPresentation.isImmersive(window)
  }
}

private struct HeaderIconButton: View {
  let systemImage: String
  let label: String
  let help: String
  let palette: ThemePalette
  let action: () -> Void

  @State private var isHovered = false
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    Button(action: action) {
      Label(label, systemImage: systemImage)
        .labelStyle(.iconOnly)
        .font(.system(size: 13, weight: .semibold))
        .frame(width: 36, height: 36)
        .background(
          palette.backdrop.opacity(reduceTransparency ? 0.96 : (isHovered ? 0.42 : 0.26)),
          in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay {
          RoundedRectangle(cornerRadius: 8)
            .stroke(palette.detail.opacity(isHovered ? 0.42 : 0.24), lineWidth: 0.8)
        }
    }
    .buttonStyle(.plain)
    .foregroundStyle(isHovered ? palette.primaryText : palette.secondaryText)
    .accessibilityLabel(label)
    .help(help)
    .onHover { isHovered = $0 }
    .animation(.easeOut(duration: 0.18), value: isHovered)
  }
}
