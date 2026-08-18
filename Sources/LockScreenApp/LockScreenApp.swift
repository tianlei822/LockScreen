import AppKit
import LockScreenCore
import SwiftUI

@main
struct LockScreenApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      if AppConfiguration.backgroundMode {
        // The background scene only bootstraps AppKit. Building the full ritual
        // here would leave a hidden SwiftUI animation tree running forever.
        Color.clear
          .frame(minWidth: 900, minHeight: 640)
          .accessibilityHidden(true)
      } else {
        LockScreenView(
          initialTheme: AppConfiguration.initialTheme,
          vaultPasscode: AppConfiguration.vaultPasscode,
          backgroundMode: false
        )
        .frame(minWidth: 900, minHeight: 640)
      }
    }
    .defaultSize(width: 1180, height: 780)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentMinSize)
  }
}

@MainActor
final class RitualRenderActivity: ObservableObject {
  @Published private(set) var state = RitualRenderState()

  func present() {
    guard !state.isPresented else { return }
    state.present()
  }

  func retreat() {
    guard state.isPresented else { return }
    state.retreat()
  }
}

struct HostedRitualView: View {
  @ObservedObject var activity: RitualRenderActivity

  var body: some View {
    LockScreenView(
      initialTheme: AppConfiguration.initialTheme,
      vaultPasscode: AppConfiguration.vaultPasscode,
      backgroundMode: AppConfiguration.backgroundMode
    )
    .environment(\.ritualAnimationsPaused, activity.state.pausesAnimations)
  }
}
