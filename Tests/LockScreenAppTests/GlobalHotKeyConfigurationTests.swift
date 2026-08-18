import Carbon.HIToolbox
import Foundation
import XCTest

@testable import LockScreenApp

final class GlobalHotKeyConfigurationTests: XCTestCase {
  func testDefaultPresetKeepsCommandLBehavior() {
    XCTAssertEqual(GlobalHotKeyPreset.defaultValue.keyCode, UInt32(kVK_ANSI_L))
    XCTAssertEqual(GlobalHotKeyPreset.defaultValue.modifiers, UInt32(cmdKey))
  }

  func testPresetStorePersistsASelectedShortcut() {
    let suiteName = "GlobalHotKeyConfigurationTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = GlobalHotKeyPreferenceStore(defaults: defaults)

    XCTAssertEqual(store.load(), .defaultValue)
    store.save(.commandShiftL)
    XCTAssertEqual(GlobalHotKeyPreferenceStore(defaults: defaults).load(), .commandShiftL)
  }
}
