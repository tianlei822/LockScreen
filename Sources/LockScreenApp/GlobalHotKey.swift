import AppKit
import Carbon.HIToolbox
import OSLog

/// Registers a system-wide hot key via Carbon HIToolbox. Unlike an event
/// monitor this needs no accessibility permission, and the key is delivered
/// to us even while another app is frontmost.
@MainActor
final class GlobalHotKey {
  private static let logger = Logger(
    subsystem: ProductMetadata.bundleIdentifier,
    category: "HotKey"
  )

  private let keyCode: UInt32
  private let modifiers: UInt32
  private let action: () -> Void

  private var hotKeyRef: EventHotKeyRef?
  private var handlerRef: EventHandlerRef?
  private var recoveryTask: Task<Void, Never>?

  init(
    keyCode: UInt32 = UInt32(kVK_ANSI_L), modifiers: UInt32 = UInt32(cmdKey),
    action: @escaping () -> Void
  ) {
    self.keyCode = keyCode
    self.modifiers = modifiers
    self.action = action
  }

  convenience init(preset: GlobalHotKeyPreset, action: @escaping () -> Void) {
    self.init(keyCode: preset.keyCode, modifiers: preset.modifiers, action: action)
  }

  var isRegistered: Bool { hotKeyRef != nil }

  /// Retry only a known failure. Healthy registrations are never periodically torn down.
  func retryRegistration(initialDelay: Duration = .seconds(2)) {
    guard !isRegistered, recoveryTask == nil else { return }
    recoveryTask = Task { @MainActor [weak self] in
      var delay = initialDelay
      while !Task.isCancelled {
        do {
          try await Task.sleep(for: delay)
        } catch {
          return
        }
        guard !Task.isCancelled, let self else { return }
        if self.register() {
          self.recoveryTask = nil
          return
        }
        delay = min(delay * 2, .seconds(30))
      }
    }
  }

  @discardableResult
  func register() -> Bool {
    guard !isRegistered else { return true }
    var eventType = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )
    let userData = Unmanaged.passUnretained(self).toOpaque()

    let installStatus = InstallEventHandler(
      GetApplicationEventTarget(),
      { _, _, userData -> OSStatus in
        guard let userData else { return OSStatus(eventNotHandledErr) }
        let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
        Task { @MainActor in
          GlobalHotKey.logger.notice("Received the global hot key")
          hotKey.action()
        }
        return noErr
      },
      1,
      &eventType,
      userData,
      &handlerRef
    )
    guard installStatus == noErr else {
      Self.logger.error(
        "Could not install the global hot-key handler (status: \(installStatus, privacy: .public))"
      )
      return false
    }

    // 'THLK'
    let hotKeyID = EventHotKeyID(signature: OSType(0x5448_4C4B), id: 1)
    let registerStatus = RegisterEventHotKey(
      keyCode,
      modifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      OptionBits(kEventHotKeyExclusive),
      &hotKeyRef
    )
    guard registerStatus == noErr else {
      Self.logger.error(
        "Could not register the global hot key (status: \(registerStatus, privacy: .public))"
      )
      if let handlerRef {
        RemoveEventHandler(handlerRef)
        self.handlerRef = nil
      }
      return false
    }
    Self.logger.notice(
      "Registered global hot key (key: \(self.keyCode), modifiers: \(self.modifiers))"
    )
    return true
  }

  func unregister() {
    recoveryTask?.cancel()
    recoveryTask = nil
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }
    if let handlerRef {
      RemoveEventHandler(handlerRef)
      self.handlerRef = nil
    }
  }

  @discardableResult
  func reregister() -> Bool {
    unregister()
    return register()
  }
}
