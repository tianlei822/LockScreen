import Carbon.HIToolbox
import XCTest

@testable import LockScreenApp

final class GlobalHotKeyTests: XCTestCase {
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
}
