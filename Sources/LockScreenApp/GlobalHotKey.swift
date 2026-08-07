import AppKit
import Carbon.HIToolbox
import OSLog

/// Registers a system-wide hot key via Carbon HIToolbox. Unlike an event
/// monitor this needs no accessibility permission, and the key is delivered
/// to us even while another app is frontmost.
@MainActor
final class GlobalHotKey {
  private static let logger = Logger(subsystem: "com.tianlei.threshold", category: "HotKey")

  private let keyCode: UInt32
  private let modifiers: UInt32
  private let action: () -> Void

  private var hotKeyRef: EventHotKeyRef?
  private var handlerRef: EventHandlerRef?

  init(
    keyCode: UInt32 = UInt32(kVK_ANSI_L), modifiers: UInt32 = UInt32(cmdKey),
    action: @escaping () -> Void
  ) {
    self.keyCode = keyCode
    self.modifiers = modifiers
    self.action = action
  }

  @discardableResult
  func register() -> Bool {
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
        "Could not register Command-L (status: \(registerStatus, privacy: .public))"
      )
      if let handlerRef {
        RemoveEventHandler(handlerRef)
        self.handlerRef = nil
      }
      return false
    }
    Self.logger.info("Registered Command-L global hot key")
    return true
  }

  func unregister() {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
      self.hotKeyRef = nil
    }
    if let handlerRef {
      RemoveEventHandler(handlerRef)
      self.handlerRef = nil
    }
  }
}
