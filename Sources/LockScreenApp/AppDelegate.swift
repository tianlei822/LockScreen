import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  /// Space transitions can temporarily detach overlay windows, so refresh as
  /// soon as AppKit reports that the active Space changed.
  /// Source: https://developer.apple.com/documentation/appkit/nsworkspace/activespacedidchangenotification
  static let coverageRefreshNotifications: [NSNotification.Name] = [
    NSWorkspace.sessionDidBecomeActiveNotification,
    NSWorkspace.didWakeNotification,
    NSWorkspace.activeSpaceDidChangeNotification,
  ]

  static func shouldTerminateAfterLastWindowClosed(
    backgroundMode: Bool,
    ritualIsImmersive: Bool
  ) -> Bool {
    !backgroundMode && !ritualIsImmersive
  }

  static func shouldIgnorePresentationRequest(
    appIsHidden: Bool,
    windowIsVisible: Bool,
    windowIsImmersive: Bool
  ) -> Bool {
    !appIsHidden && windowIsVisible && windowIsImmersive
  }

  static func shouldPresentRitualOnReopen(backgroundMode: Bool) -> Bool {
    backgroundMode
  }

  private var screenObserver: NSObjectProtocol?
  private var workspaceObservers: [NSObjectProtocol] = []
  private var hotKey: GlobalHotKey?
  private let hotKeyPreferenceStore = GlobalHotKeyPreferenceStore()
  private var selectedHotKey = GlobalHotKeyPreferenceStore().load()
  private lazy var statusItemController = StatusItemController(
    selectedHotKey: selectedHotKey,
    onLock: { [weak self] in
      self?.presentRitual()
    },
    onSelectHotKey: { [weak self] preset in
      self?.registerGlobalHotKey(preset) ?? false
    }
  )

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
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        WindowPresentation.refreshScreenCovers()
        self?.statusItemController.refreshAppearance()
      }
    }

    let workspaceCenter = NSWorkspace.shared.notificationCenter
    for name in Self.coverageRefreshNotifications {
      workspaceObservers.append(
        workspaceCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
          Task { @MainActor [weak self] in
            WindowPresentation.refreshScreenCovers()
            self?.statusItemController.refreshAppearance()
          }
        })
    }

    if AppConfiguration.backgroundMode {
      NSApp.setActivationPolicy(.accessory)
      for window in NSApp.windows {
        window.orderOut(nil)
      }
      NSApp.hide(nil)
      statusItemController.install()
    }

    _ = registerGlobalHotKey(selectedHotKey)

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

  /// The configured shortcut (or the status menu): show the ritual and take over the screen.
  func presentRitual() {
    guard let window = WindowPresentation.mainRitualWindow() else { return }
    guard
      !Self.shouldIgnorePresentationRequest(
        appIsHidden: NSApp.isHidden,
        windowIsVisible: window.occlusionState.contains(.visible),
        windowIsImmersive: WindowPresentation.isImmersive(window)
      )
    else { return }

    NSApp.unhide(nil)
    WindowPresentation.enterImmersive(window)
  }

  func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    guard Self.shouldPresentRitualOnReopen(backgroundMode: AppConfiguration.backgroundMode)
    else { return true }

    presentRitual()
    return false
  }

  func applicationDidBecomeActive(_ notification: Notification) {
    WindowPresentation.reassertKiosk()
    statusItemController.refreshAppearance()
  }

  func applicationDidResignActive(_ notification: Notification) {
    statusItemController.refreshAppearance()
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(250))
      WindowPresentation.reassertKiosk()
    }
  }

  func applicationWillTerminate(_ notification: Notification) {
    IdleSuppression.end()
    hotKey?.unregister()
    statusItemController.cancelPendingRefresh()
    if let screenObserver {
      NotificationCenter.default.removeObserver(screenObserver)
    }
    let workspaceCenter = NSWorkspace.shared.notificationCenter
    for observer in workspaceObservers {
      workspaceCenter.removeObserver(observer)
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    let ritualIsImmersive =
      WindowPresentation.mainRitualWindow()
      .map(WindowPresentation.isImmersive) ?? false
    return Self.shouldTerminateAfterLastWindowClosed(
      backgroundMode: AppConfiguration.backgroundMode,
      ritualIsImmersive: ritualIsImmersive
    )
  }

  /// In background mode the window is only hidden, never closed, so the shortcut can
  /// always bring the same ritual back.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard AppConfiguration.backgroundMode else { return true }
    sender.orderOut(nil)
    return false
  }

  @discardableResult
  private func registerGlobalHotKey(_ preset: GlobalHotKeyPreset) -> Bool {
    if preset == selectedHotKey, hotKey != nil {
      return true
    }

    let candidate = GlobalHotKey(preset: preset) { [weak self] in
      self?.presentRitual()
    }
    guard candidate.register() else {
      FileHandle.standardError.write(
        Data(
          "\(ProductMetadata.displayName): could not register \(preset.title) (already taken?)\n"
            .utf8
        )
      )
      return false
    }

    hotKey?.unregister()
    hotKey = candidate
    selectedHotKey = preset
    hotKeyPreferenceStore.save(preset)
    return true
  }

}
