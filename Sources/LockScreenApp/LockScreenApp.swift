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
  private var screenObserver: NSObjectProtocol?

  func applicationDidFinishLaunching(_ notification: Notification) {
    screenObserver = NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { _ in
      Task { @MainActor in
        WindowPresentation.refreshScreenCovers()
      }
    }

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

  func applicationDidBecomeActive(_ notification: Notification) {
    WindowPresentation.reassertKiosk()
  }

  func applicationDidResignActive(_ notification: Notification) {
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(250))
      WindowPresentation.reassertKiosk()
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

@MainActor
enum WindowPresentation {
  /// Kiosk-style options so the ritual truly owns the screen while immersive:
  /// menu bar and Dock stay hidden, app switching / force quit are disabled.
  /// ⇧⌘F and ⌘Q remain as owner escape hatches.
  private static let kioskOptions: NSApplication.PresentationOptions = [
    .hideDock,
    .hideMenuBar,
    .disableAppleMenu,
    .disableProcessSwitching,
    .disableForceQuit,
    .disableSessionTermination,
    .disableHideApplication,
  ]

  private static var screenCovers: [NSWindow] = []

  static func toggle(_ window: NSWindow?) {
    guard let window else { return }
    isImmersive(window) ? enterWindowed(window) : enterImmersive(window)
  }

  static func enterImmersive(_ window: NSWindow) {
    guard let screen = window.screen ?? NSScreen.main else { return }

    window.level = .screenSaver
    window.collectionBehavior = [
      .canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle,
    ]
    window.isMovable = false
    window.hasShadow = false
    setWindowButtonsHidden(true, in: window)

    // Kiosk options only apply while the app is frontmost, and unbundled
    // `swift run` binaries may need an explicit activation policy first.
    NSApp.setActivationPolicy(.regular)
    window.makeKeyAndOrderFront(nil)
    NSApp.activate()
    NSApp.presentationOptions = kioskOptions

    // Frame after the kiosk options: while the menu bar and Dock are still
    // visible, AppKit clamps window frames to the visible frame. Overscan
    // pushes the window's rounded corners off the visible area.
    window.setFrame(screen.frame.insetBy(dx: -12, dy: -12), display: true)

    coverSecondaryScreens(except: screen)
  }

  /// Kiosk options only apply while the app is frontmost; re-assert them
  /// when focus returns or something briefly steals it mid-ritual. The frame
  /// is re-applied too because the first attempt can be clamped while the
  /// menu bar and Dock are still animating out.
  static func reassertKiosk() {
    guard !NSApp.isHidden,
      let window = NSApp.windows.first(where: { !screenCovers.contains($0) }),
      isImmersive(window),
      let screen = window.screen
    else { return }

    NSApp.presentationOptions = kioskOptions
    if !NSApp.isActive {
      NSApp.activate()
    }

    let target = screen.frame.insetBy(dx: -12, dy: -12)
    if window.frame != target {
      window.setFrame(target, display: true)
    }
  }

  /// Re-blank secondary displays after a display is (dis)connected mid-session.
  static func refreshScreenCovers() {
    guard let window = NSApp.windows.first(where: { !screenCovers.contains($0) }),
      isImmersive(window),
      let screen = window.screen
    else { return }

    reassertKiosk()
    coverSecondaryScreens(except: screen)
  }

  private static func enterWindowed(_ window: NSWindow) {
    guard let screen = window.screen ?? NSScreen.main else { return }

    dismissScreenCovers()
    NSApp.presentationOptions = []

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

  private static func coverSecondaryScreens(except covered: NSScreen) {
    dismissScreenCovers()

    for screen in NSScreen.screens where screen != covered {
      let cover = NSWindow(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
      )
      cover.level = .screenSaver
      cover.backgroundColor = .black
      cover.isOpaque = true
      cover.hasShadow = false
      cover.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
      cover.contentView = NSHostingView(rootView: Color.black)
      cover.orderFront(nil)
      screenCovers.append(cover)
    }
  }

  private static func dismissScreenCovers() {
    for cover in screenCovers {
      cover.close()
    }
    screenCovers.removeAll()
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
