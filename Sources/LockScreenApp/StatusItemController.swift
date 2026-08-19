import AppKit

@MainActor
final class StatusItemController: NSObject {
  private let onLock: () -> Void
  private let onSelectHotKey: (GlobalHotKeyPreset) -> Bool
  private var selectedHotKey: GlobalHotKeyPreset
  private var statusItem: NSStatusItem?

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
      let image =
        NSImage(
          systemSymbolName: "lock",
          accessibilityDescription: ProductMetadata.displayName
        )?.withSymbolConfiguration(.init(pointSize: 14, weight: .medium))
        ?? NSImage()
      Self.configureStandardButton(button, image: image)
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

    item.menu = menu
    statusItem = item
  }

  static func configureStandardButton(_ button: NSStatusBarButton, image: NSImage) {
    image.isTemplate = true
    button.image = image
    button.imagePosition = .imageOnly
    button.imageScaling = .scaleProportionallyDown
    button.title = ""
    button.setAccessibilityLabel(ProductMetadata.displayName)
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
}
