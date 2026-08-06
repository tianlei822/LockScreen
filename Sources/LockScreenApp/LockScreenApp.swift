import AppKit
import LockScreenCore
import SwiftUI

@main
struct LockScreenApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    WindowGroup {
      LockScreenView(
        initialTheme: initialTheme,
        vaultPasscode: configuredVaultPasscode
      )
      .frame(minWidth: 900, minHeight: 640)
    }
    .defaultSize(width: 1180, height: 780)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentMinSize)
  }

  private var initialTheme: DoorTheme {
    let arguments = ProcessInfo.processInfo.arguments
    if arguments.contains("--vault") { return .vault }
    if arguments.contains("--formation") { return .formation }
    return .wood
  }

  private var configuredVaultPasscode: String {
    let prefix = "--passcode="
    guard
      let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix(prefix) })
    else {
      return "1024"
    }

    let passcode = String(argument.dropFirst(prefix.count))
    guard (4...8).contains(passcode.count), passcode.allSatisfy(\.isNumber) else {
      return "1024"
    }
    return passcode
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(300))
      guard let window = NSApp.windows.first else { return }

      window.titleVisibility = .hidden
      window.titlebarAppearsTransparent = true
      window.backgroundColor = .black

      let opensWindowed = ProcessInfo.processInfo.arguments.contains("--windowed")
      if !opensWindowed {
        WindowPresentation.enterImmersive(window)
      }
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@MainActor
enum WindowPresentation {
  static func toggle(_ window: NSWindow?) {
    guard let window else { return }
    isImmersive(window) ? enterWindowed(window) : enterImmersive(window)
  }

  static func enterImmersive(_ window: NSWindow) {
    guard let screen = window.screen ?? NSScreen.main else { return }

    window.level = .screenSaver
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.isMovable = false
    window.hasShadow = false
    setWindowButtonsHidden(true, in: window)
    window.setFrame(screen.frame, display: true)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private static func enterWindowed(_ window: NSWindow) {
    guard let screen = window.screen ?? NSScreen.main else { return }

    window.level = .normal
    window.collectionBehavior = [.fullScreenPrimary]
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovable = true
    window.hasShadow = true
    setWindowButtonsHidden(false, in: window)

    let visibleFrame = screen.visibleFrame
    let size = NSSize(
      width: min(1_180, visibleFrame.width - 80),
      height: min(780, visibleFrame.height - 80)
    )
    let origin = NSPoint(
      x: visibleFrame.midX - size.width / 2,
      y: visibleFrame.midY - size.height / 2
    )
    window.setFrame(NSRect(origin: origin, size: size), display: true, animate: true)
  }

  private static func isImmersive(_ window: NSWindow) -> Bool {
    window.level == .screenSaver
  }

  private static func setWindowButtonsHidden(_ hidden: Bool, in window: NSWindow) {
    let buttonTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
    for buttonType in buttonTypes {
      window.standardWindowButton(buttonType)?.isHidden = hidden
    }
  }
}
