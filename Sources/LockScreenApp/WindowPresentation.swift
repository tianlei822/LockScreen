import AppKit
import SwiftUI

@MainActor
private final class RitualPanel: NSPanel {
  override var canBecomeKey: Bool { true }
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

  /// Cover ordinary Spaces plus other apps' full-screen and Stage Manager sets.
  /// Source: https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/canjoinallapplications
  static let overlayCollectionBehavior: NSWindow.CollectionBehavior = [
    .canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .stationary, .ignoresCycle,
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
    guard let screen = sourceWindow.screen ?? NSScreen.main else { return }

    // Accessory semantics plus a nonactivating panel let this system-style
    // overlay join other Spaces without activating and moving its owning app.
    // Source: https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel
    NSApp.setActivationPolicy(.accessory)
    let window = dedicatedRitualWindow(from: sourceWindow)

    renderActivity.present()
    restoreWindowOpacity(window)

    configureForImmersivePresentation(window)
    setWindowButtonsHidden(true, in: window)

    window.orderFrontRegardless()
    window.makeKey()
    NSApp.presentationOptions = kioskOptions

    // A borderless window can match the display exactly. Standard titled
    // windows get re-constrained after wake/Space changes and expose their
    // rounded corners even when their frame is temporarily overscanned.
    window.setFrame(screen.frame, display: true)

    IdleSuppression.begin()
    coverSecondaryScreens(except: screen)
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

    configureForImmersivePresentation(window)

    let target = screen.frame
    if window.frame != target {
      window.setFrame(target, display: true)
    }
    window.orderFrontRegardless()
    window.makeKey()
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

  /// Background mode: after a completed ritual, re-seal and lurk until summoned again.
  static func retreatToBackground(_ window: NSWindow?) {
    coverageReassertionTask?.cancel()
    dismissScreenCovers()
    NSApp.presentationOptions = []
    IdleSuppression.end()
    renderActivity.retreat()

    window?.level = .normal
    window?.orderOut(nil)
    window?.alphaValue = 1
    NSApp.setActivationPolicy(.accessory)
    NSApp.hide(nil)
  }

  static func fadeOut(_ window: NSWindow?) async {
    guard let window else { return }

    await NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.28
      context.allowsImplicitAnimation = true
      window.animator().alphaValue = 0
    }
  }

  static func restoreWindowOpacity(_ window: NSWindow) {
    window.alphaValue = 1
  }

  private static func enterWindowed(_ window: NSWindow) {
    guard let screen = window.screen ?? NSScreen.main else { return }

    renderActivity.present()
    restoreWindowOpacity(window)

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
    window.minSize = NSSize(width: 760, height: 520)
    if let panel = window as? NSPanel {
      panel.isFloatingPanel = false
      panel.hidesOnDeactivate = true
    }
    setWindowButtonsHidden(false, in: window)

    if !AppConfiguration.backgroundMode {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate()
    }

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
  /// render the ritual in a dedicated nonactivating AppKit panel instead.
  private static func dedicatedRitualWindow(from sourceWindow: NSWindow) -> NSWindow {
    if let ritualWindow {
      return ritualWindow
    }

    let frame = sourceWindow.screen?.frame ?? NSScreen.main?.frame ?? sourceWindow.frame
    let window = makeRitualPanel(contentRect: frame)
    window.title = ProductMetadata.displayName
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

  static func makeRitualPanel(contentRect: NSRect) -> NSPanel {
    let panel = RitualPanel(
      contentRect: contentRect,
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    configureForImmersivePresentation(panel)
    return panel
  }

  static func configureForImmersivePresentation(_ window: NSWindow) {
    window.styleMask = [.borderless, .nonactivatingPanel]
    if let panel = window as? NSPanel {
      panel.isFloatingPanel = true
      panel.hidesOnDeactivate = false
    }
    window.level = .screenSaver
    window.collectionBehavior = overlayCollectionBehavior
    window.isMovable = false
    window.hasShadow = false
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
      cover.collectionBehavior = overlayCollectionBehavior
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
