import AppKit
import LockScreenCore
import SwiftUI

enum AppConfiguration {
  /// `--background`: lurk windowless and summon the ritual with ⌘L instead.
  static let backgroundMode = ProcessInfo.processInfo.arguments.contains("--background")

  static var initialTheme: DoorTheme {
    let arguments = ProcessInfo.processInfo.arguments
    if arguments.contains("--vault") { return .vault }
    if arguments.contains("--wood") { return .wood }
    return .formation
  }

  static var vaultPasscode: String {
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
private final class RitualRenderActivity: ObservableObject {
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

private struct HostedRitualView: View {
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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
  private var screenObserver: NSObjectProtocol?
  private var workspaceObservers: [NSObjectProtocol] = []
  private var statusItem: NSStatusItem?
  private var statusMenu: NSMenu?
  private var hotKey: GlobalHotKey?

  func applicationWillFinishLaunching(_ notification: Notification) {
    guard AppConfiguration.backgroundMode else { return }

    // Establish accessory/background semantics before SwiftUI creates its
    // WindowGroup so the scene never receives an initial foreground frame.
    NSApp.setActivationPolicy(.accessory)
  }

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

    let workspaceCenter = NSWorkspace.shared.notificationCenter
    for name in [NSWorkspace.sessionDidBecomeActiveNotification, NSWorkspace.didWakeNotification] {
      workspaceObservers.append(
        workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { _ in
          Task { @MainActor in
            WindowPresentation.refreshScreenCovers()
          }
        })
    }

    if AppConfiguration.backgroundMode {
      NSApp.setActivationPolicy(.accessory)
      for window in NSApp.windows {
        window.orderOut(nil)
      }
      NSApp.hide(nil)
      installStatusItem()
    }

    hotKey = GlobalHotKey { [weak self] in
      self?.presentRitual()
    }
    if hotKey?.register() != true {
      FileHandle.standardError.write(
        Data("Threshold: could not register ⌘L (already taken?)\n".utf8))
    }

    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(300))
      guard let window = WindowPresentation.mainRitualWindow() else { return }

      window.titleVisibility = .hidden
      window.titlebarAppearsTransparent = true
      window.backgroundColor = .black
      window.delegate = self

      let opensWindowed = ProcessInfo.processInfo.arguments.contains("--windowed")
      if AppConfiguration.backgroundMode {
        window.orderOut(nil)
      } else if !opensWindowed {
        WindowPresentation.enterImmersive(window)
      }
    }
  }

  /// ⌘L (or the status menu): show the ritual and take over the screen.
  func presentRitual() {
    guard let window = WindowPresentation.mainRitualWindow(),
      !WindowPresentation.isImmersive(window)
    else { return }

    NSApp.unhide(nil)
    WindowPresentation.enterImmersive(window)
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

  func applicationWillTerminate(_ notification: Notification) {
    IdleSuppression.end()
    hotKey?.unregister()
    if let screenObserver {
      NotificationCenter.default.removeObserver(screenObserver)
    }
    let workspaceCenter = NSWorkspace.shared.notificationCenter
    for observer in workspaceObservers {
      workspaceCenter.removeObserver(observer)
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    !AppConfiguration.backgroundMode
  }

  /// In background mode the window is only hidden, never closed, so ⌘L can
  /// always bring the same ritual back.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard AppConfiguration.backgroundMode else { return true }
    sender.orderOut(nil)
    return false
  }

  private func installStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = item.button {
      let image = NSImage(
        systemSymbolName: "lock", accessibilityDescription: "Threshold"
      )?.withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
      image?.isTemplate = true

      let imageView = NSImageView(image: image ?? NSImage())
      imageView.imageScaling = .scaleProportionallyDown
      imageView.contentTintColor = .labelColor
      imageView.translatesAutoresizingMaskIntoConstraints = false

      // `isBordered = false` only removes the bezel. The status-bar button can
      // still draw its own dark backing when highlighted, so make the button
      // fully transparent and render the template symbol in a child view.
      button.image = nil
      button.title = ""
      button.isBordered = false
      button.isTransparent = true
      if let buttonCell = button.cell as? NSButtonCell {
        buttonCell.highlightsBy = []
        buttonCell.showsStateBy = []
      }
      button.addSubview(imageView)
      button.target = self
      button.action = #selector(showStatusMenu(_:))
      button.setAccessibilityLabel("Threshold")
      clearStatusItemHighlight(button)

      NSLayoutConstraint.activate([
        imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        imageView.widthAnchor.constraint(equalToConstant: 15),
        imageView.heightAnchor.constraint(equalToConstant: 15),
      ])
    }

    let menu = NSMenu()
    let lockItem = NSMenuItem(
      title: "Lock Now (⌘L)", action: #selector(lockNowFromMenu), keyEquivalent: "")
    lockItem.target = self
    menu.addItem(lockItem)
    menu.addItem(.separator())
    let quitItem = NSMenuItem(
      title: "Quit Threshold", action: #selector(quitFromMenu), keyEquivalent: "")
    quitItem.target = self
    menu.addItem(quitItem)

    menu.delegate = self
    // IMPORTANT: Do not assign this menu to `item.menu`. AppKit owns the
    // standard status-item highlight while an attached menu is tracking and
    // can restore its dark backing after our transparent button is configured.
    // Presenting the retained menu ourselves keeps that system highlight path
    // detached without changing the menu's behavior.
    statusMenu = menu
    statusItem = item
  }

  @objc private func showStatusMenu(_ sender: NSStatusBarButton) {
    guard let statusMenu else { return }

    clearStatusItemHighlight(sender)
    statusMenu.popUp(positioning: nil, at: .zero, in: sender)
    clearStatusItemHighlight(sender)
  }

  func menuWillOpen(_ menu: NSMenu) {
    clearStatusItemHighlight()
  }

  func menuDidClose(_ menu: NSMenu) {
    clearStatusItemHighlight()
  }

  private func clearStatusItemHighlight(_ button: NSStatusBarButton? = nil) {
    guard let button = button ?? statusItem?.button else { return }
    button.state = .off
    button.highlight(false)
    button.needsDisplay = true
  }

  @objc private func lockNowFromMenu() {
    presentRitual()
  }

  @objc private func quitFromMenu() {
    NSApp.terminate(nil)
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
  private static var ritualWindow: NSWindow?
  private static var coverageReassertionTask: Task<Void, Never>?
  private static let renderActivity = RitualRenderActivity()

  /// The ritual window, as opposed to a secondary-display cover.
  static func mainRitualWindow() -> NSWindow? {
    ritualWindow ?? NSApp.windows.first { !screenCovers.contains($0) }
  }

  static func toggle(_ window: NSWindow?) {
    guard let window else { return }
    isImmersive(window) ? enterWindowed(window) : enterImmersive(window)
  }

  static func enterImmersive(_ sourceWindow: NSWindow) {
    let window = dedicatedRitualWindow(from: sourceWindow)
    guard let screen = window.screen ?? NSScreen.main else { return }

    renderActivity.present()

    window.level = .screenSaver
    window.collectionBehavior = [
      .canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle,
    ]
    window.isMovable = false
    window.hasShadow = false
    setWindowButtonsHidden(true, in: window)

    // Keep background mode status-bar-only. Normal and unbundled launches
    // still need the regular activation policy to become frontmost.
    if !AppConfiguration.backgroundMode {
      NSApp.setActivationPolicy(.regular)
    }
    window.makeKeyAndOrderFront(nil)
    NSApp.activate()
    NSApp.presentationOptions = kioskOptions

    // A borderless window can match the display exactly. Standard titled
    // windows get re-constrained after wake/Space changes and expose their
    // rounded corners even when their frame is temporarily overscanned.
    window.setFrame(screen.frame, display: true)

    IdleSuppression.begin()
    coverSecondaryScreens(except: screen)
    window.styleMask = [.borderless]
    scheduleCoverageReassertion()
  }

  /// Kiosk options only apply while the app is frontmost; re-assert them
  /// when focus returns or something briefly steals it mid-ritual. The frame
  /// is re-applied too because the display can briefly report an intermediate
  /// frame while the menu bar, Dock, Space, or login session is transitioning.
  static func reassertKiosk() {
    guard !NSApp.isHidden,
      let window = mainRitualWindow(),
      isImmersive(window),
      let screen = window.screen
    else { return }

    NSApp.presentationOptions = kioskOptions
    if !NSApp.isActive {
      NSApp.activate()
    }

    window.level = .screenSaver
    window.hasShadow = false

    let target = screen.frame
    if window.frame != target {
      window.setFrame(target, display: true)
    }
    window.orderFrontRegardless()
    window.styleMask = [.borderless]
  }

  /// Re-blank secondary displays after a display is (dis)connected mid-session.
  static func refreshScreenCovers() {
    guard let window = mainRitualWindow(),
      isImmersive(window),
      let screen = window.screen
    else { return }

    reassertKiosk()
    coverSecondaryScreens(except: screen)
    scheduleCoverageReassertion()
  }

  /// Background mode: after a completed ritual, re-seal and lurk until ⌘L.
  static func retreatToBackground(_ window: NSWindow?) {
    coverageReassertionTask?.cancel()
    dismissScreenCovers()
    NSApp.presentationOptions = []
    IdleSuppression.end()
    renderActivity.retreat()

    window?.level = .normal
    window?.orderOut(nil)
    NSApp.setActivationPolicy(.accessory)
    NSApp.hide(nil)
  }

  private static func enterWindowed(_ window: NSWindow) {
    guard let screen = window.screen ?? NSScreen.main else { return }

    renderActivity.present()

    coverageReassertionTask?.cancel()
    dismissScreenCovers()
    NSApp.presentationOptions = []
    IdleSuppression.end()

    window.styleMask = [.borderless]
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

  /// AppKit finishes hiding system UI and restoring a login session over
  /// several run-loop turns. Re-apply the exact display frame during that
  /// transition instead of relying on a single timing-sensitive assignment.
  private static func scheduleCoverageReassertion() {
    coverageReassertionTask?.cancel()
    coverageReassertionTask = Task { @MainActor in
      for delay in [150, 350, 700, 2_000] {
        do {
          try await Task.sleep(for: .milliseconds(delay))
        } catch {
          return
        }
        reassertKiosk()
      }
    }
  }

  /// SwiftUI owns the WindowGroup style and can restore its title bar after a
  /// kiosk or login-session transition. Keep that scene window hidden and
  /// render the ritual in a dedicated AppKit borderless window instead.
  private static func dedicatedRitualWindow(from sourceWindow: NSWindow) -> NSWindow {
    if let ritualWindow {
      return ritualWindow
    }

    let frame = sourceWindow.screen?.frame ?? NSScreen.main?.frame ?? sourceWindow.frame
    let window = NSWindow(
      contentRect: frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.title = "Threshold"
    window.backgroundColor = .black
    window.isOpaque = true
    window.hasShadow = false
    window.isReleasedWhenClosed = false
    window.delegate = sourceWindow.delegate

    let hostingView = NSHostingView(
      rootView: HostedRitualView(activity: renderActivity)
    )
    hostingView.autoresizingMask = [.width, .height]
    window.contentView = hostingView

    sourceWindow.orderOut(nil)
    ritualWindow = window
    return window
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

  static func isImmersive(_ window: NSWindow) -> Bool {
    window.level == .screenSaver
  }

  private static func setWindowButtonsHidden(_ hidden: Bool, in window: NSWindow) {
    let buttonTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
    for buttonType in buttonTypes {
      window.standardWindowButton(buttonType)?.isHidden = hidden
    }
  }
}
