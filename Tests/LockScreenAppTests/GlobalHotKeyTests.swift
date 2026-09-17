import Carbon.HIToolbox
import XCTest

@testable import LockScreenApp

final class GlobalHotKeyTests: XCTestCase {
  @MainActor
  func testRepeatedRegistrationDoesNotLeakTheHotKey() {
    let hotKey = GlobalHotKey(keyCode: UInt32(kVK_F15)) {}
    let replacement = GlobalHotKey(keyCode: UInt32(kVK_F15)) {}
    defer {
      hotKey.unregister()
      replacement.unregister()
    }
    XCTAssertTrue(hotKey.register())
    XCTAssertTrue(hotKey.register())
    hotKey.unregister()
    XCTAssertTrue(replacement.register())
  }

  @MainActor
  func testRegistrationRecoversAfterConflictIsReleased() async throws {
    let owner = GlobalHotKey(keyCode: UInt32(kVK_F15)) {}
    let waiting = GlobalHotKey(keyCode: UInt32(kVK_F15)) {}
    XCTAssertTrue(owner.register())
    defer {
      owner.unregister()
      waiting.unregister()
    }
    XCTAssertFalse(waiting.register())
    waiting.retryRegistration(initialDelay: .milliseconds(10))
    try await Task.sleep(for: .milliseconds(30))
    XCTAssertFalse(waiting.isRegistered)

    owner.unregister()
    for _ in 0..<100 where !waiting.isRegistered {
      try await Task.sleep(for: .milliseconds(10))
    }
    XCTAssertTrue(waiting.isRegistered)
  }

  @MainActor
  func testUnregisterCancelsPendingRecovery() async throws {
    let owner = GlobalHotKey(keyCode: UInt32(kVK_F15)) {}
    let waiting = GlobalHotKey(keyCode: UInt32(kVK_F15)) {}
    XCTAssertTrue(owner.register())
    defer {
      owner.unregister()
      waiting.unregister()
    }
    XCTAssertFalse(waiting.register())
    waiting.retryRegistration(initialDelay: .milliseconds(10))
    waiting.unregister()
    owner.unregister()
    try await Task.sleep(for: .milliseconds(50))
    XCTAssertFalse(waiting.isRegistered)
    XCTAssertTrue(owner.register())
  }

  @MainActor
  func testRegisteredHotKeyDispatchesItsAction() async throws {
    let actionInvoked = expectation(description: "Global hot key action invoked")
    let hotKey = GlobalHotKey(
      keyCode: UInt32(kVK_F14),
      modifiers: UInt32(cmdKey | optionKey | shiftKey)
    ) {
      actionInvoked.fulfill()
    }
    XCTAssertTrue(hotKey.register())
    defer { hotKey.unregister() }

    var event: EventRef?
    XCTAssertEqual(
      CreateEvent(
        nil,
        OSType(kEventClassKeyboard),
        UInt32(kEventHotKeyPressed),
        GetCurrentEventTime(),
        EventAttributes(kEventAttributeUserEvent),
        &event
      ),
      noErr
    )
    let hotKeyEvent = try XCTUnwrap(event)

    XCTAssertEqual(SendEventToEventTarget(hotKeyEvent, GetApplicationEventTarget()), noErr)
    await fulfillment(of: [actionInvoked], timeout: 1)
  }

  @MainActor
  func testReregisteredHotKeyDispatchesItsAction() async throws {
    let actionInvoked = expectation(description: "Re-registered global hot key action invoked")
    let hotKey = GlobalHotKey(
      keyCode: UInt32(kVK_F14),
      modifiers: UInt32(cmdKey | optionKey | shiftKey)
    ) {
      actionInvoked.fulfill()
    }
    XCTAssertTrue(hotKey.register())
    XCTAssertTrue(hotKey.reregister())
    defer { hotKey.unregister() }

    var event: EventRef?
    XCTAssertEqual(
      CreateEvent(
        nil,
        OSType(kEventClassKeyboard),
        UInt32(kEventHotKeyPressed),
        GetCurrentEventTime(),
        EventAttributes(kEventAttributeUserEvent),
        &event
      ),
      noErr
    )
    let hotKeyEvent = try XCTUnwrap(event)

    XCTAssertEqual(SendEventToEventTarget(hotKeyEvent, GetApplicationEventTarget()), noErr)
    await fulfillment(of: [actionInvoked], timeout: 1)
  }
}
