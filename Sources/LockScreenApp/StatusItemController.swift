import AppKit

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
  struct DetachedMenuPresentation {
    let location: NSPoint
    let view: NSView?
  }

  /// Login can reconfigure the menu bar for several run-loop turns after this
  /// LaunchAgent starts, so keep restoring transparency while it settles.
  static let appearanceRefreshDelays: [Duration] = [
    .milliseconds(100), .milliseconds(400), .seconds(1), .seconds(2),
  ]

  private let onLock: () -> Void
  private let onSelectHotKey: (GlobalHotKeyPreset) -> Bool
  private var selectedHotKey: GlobalHotKeyPreset
  private var statusItem: NSStatusItem?
  private var appearanceRefreshTask: Task<Void, Never>?
  private var statusMenu: NSMenu?

  init(
    selectedHotKey: GlobalHotKeyPreset,
    onLock: @escaping () -> Void,
    onSelectHotKey: @escaping (GlobalHotKeyPreset) -> Bool
  ) {
    self.selectedHotKey = selectedHotKey
    self.onLock = onLock
    self.onSelectHotKey = onSelectHotKey
  }

  func install() {
    guard statusItem == nil else { return }

    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let button = item.button {
      let image = NSImage(
        systemSymbolName: "lock",
        accessibilityDescription: ProductMetadata.displayName
      )?.withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
      image?.isTemplate = true

      let imageView = NSImageView(image: image ?? NSImage())
      imageView.imageScaling = .scaleProportionallyDown
      imageView.contentTintColor = .labelColor
      imageView.translatesAutoresizingMaskIntoConstraints = false

      // Keep the button fully transparent and render the template symbol in a
      // child view so AppKit cannot reintroduce its dark tracking highlight.
      button.image = nil
      button.title = ""
      button.addSubview(imageView)
      button.target = self
      button.action = #selector(showStatusMenu(_:))
      button.setAccessibilityLabel(ProductMetadata.displayName)
      applyTransparentAppearance(to: button)

      NSLayoutConstraint.activate([
        imageView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        imageView.widthAnchor.constraint(equalToConstant: 15),
        imageView.heightAnchor.constraint(equalToConstant: 15),
      ])
    }

    let menu = NSMenu()
    let lockItem = NSMenuItem(
      title: L10n.text("Lock Now"), action: #selector(lockNow), keyEquivalent: "")
    lockItem.target = self
    menu.addItem(lockItem)

    let shortcutItem = NSMenuItem(
      title: L10n.text("Global Shortcut"),
      action: nil,
      keyEquivalent: ""
    )
    let shortcutMenu = NSMenu()
    for preset in GlobalHotKeyPreset.allCases {
      let item = NSMenuItem(
        title: preset.title,
        action: #selector(selectHotKey(_:)),
        keyEquivalent: ""
      )
      item.target = self
      item.representedObject = preset.rawValue
      item.state = preset == selectedHotKey ? .on : .off
      shortcutMenu.addItem(item)
    }
    shortcutItem.submenu = shortcutMenu
    menu.addItem(shortcutItem)
    menu.addItem(.separator())

    let quitItem = NSMenuItem(
      title: L10n.format("Quit %@", ProductMetadata.displayName),
      action: #selector(quit),
      keyEquivalent: ""
    )
    quitItem.target = self
    menu.addItem(quitItem)

    menu.delegate = self
    // Do not assign this menu to `item.menu`: AppKit's attached-menu tracking
    // restores the dark status-item backing that this controller suppresses.
    statusMenu = menu
    statusItem = item
    scheduleAppearanceRefresh()
  }

  func refreshAppearance() {
    guard statusItem != nil else { return }
    applyTransparentAppearance()
    scheduleAppearanceRefresh()
  }

  func cancelPendingRefresh() {
    appearanceRefreshTask?.cancel()
    appearanceRefreshTask = nil
  }

  static func configureTransparentAppearance(_ button: NSStatusBarButton) {
    button.isBordered = false
    button.isTransparent = true
    if let buttonCell = button.cell as? NSButtonCell {
      buttonCell.highlightsBy = []
      buttonCell.showsStateBy = []
      buttonCell.isHighlighted = false
    }
    button.state = .off
    button.highlight(false)
    button.needsDisplay = true
  }

  static func detachedMenuPresentation(
    from button: NSStatusBarButton
  ) -> DetachedMenuPresentation? {
    guard let window = button.window else { return nil }
    let anchorInButton = NSPoint(
      x: button.bounds.minX,
      y: button.isFlipped ? button.bounds.maxY : button.bounds.minY
    )
    let originInWindow = button.convert(anchorInButton, to: nil)
    return DetachedMenuPresentation(
      location: window.convertPoint(toScreen: originInWindow),
      view: nil
    )
  }

  func menuWillOpen(_ menu: NSMenu) {
    applyTransparentAppearance()
  }

  func menuDidClose(_ menu: NSMenu) {
    applyTransparentAppearance()
  }

  @objc private func showStatusMenu(_ sender: NSStatusBarButton) {
    guard let statusMenu,
      let presentation = Self.detachedMenuPresentation(from: sender)
    else { return }

    applyTransparentAppearance(to: sender)
    Task { @MainActor [weak self, weak sender, weak statusMenu] in
      await Task.yield()
      guard let self, let sender, let statusMenu else { return }

      self.applyTransparentAppearance(to: sender)
      statusMenu.popUp(
        positioning: nil,
        at: presentation.location,
        in: presentation.view
      )
      self.applyTransparentAppearance(to: sender)
    }
  }

  @objc private func lockNow() {
    onLock()
  }

  @objc private func selectHotKey(_ sender: NSMenuItem) {
    guard let rawValue = sender.representedObject as? String,
      let preset = GlobalHotKeyPreset(rawValue: rawValue),
      onSelectHotKey(preset)
    else { return }

    selectedHotKey = preset
    guard let items = sender.menu?.items else { return }
    for item in items {
      item.state = item === sender ? .on : .off
    }
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }

  private func applyTransparentAppearance(to button: NSStatusBarButton? = nil) {
    guard let button = button ?? statusItem?.button else { return }
    Self.configureTransparentAppearance(button)
  }

  private func scheduleAppearanceRefresh() {
    appearanceRefreshTask?.cancel()
    appearanceRefreshTask = Task { @MainActor [weak self] in
      for delay in Self.appearanceRefreshDelays {
        do {
          try await Task.sleep(for: delay)
        } catch {
          return
        }
        self?.applyTransparentAppearance()
      }
    }
  }
}
