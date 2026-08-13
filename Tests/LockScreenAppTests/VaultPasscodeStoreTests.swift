import Foundation
import XCTest

@testable import LockScreenApp

final class VaultPasscodeStoreTests: XCTestCase {
  func testStorePersistsAValidVaultPasscode() {
    let suiteName = "VaultPasscodeStoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = VaultPasscodeStore(defaults: defaults)

    XCTAssertEqual(store.load(), "1024")
    XCTAssertTrue(store.save("7531"))
    XCTAssertEqual(VaultPasscodeStore(defaults: defaults).load(), "7531")
  }

  func testStoreRejectsInvalidVaultPasscodes() {
    let suiteName = "VaultPasscodeStoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let store = VaultPasscodeStore(defaults: defaults)

    XCTAssertFalse(store.save("123"))
    XCTAssertFalse(store.save("25A0"))
    XCTAssertEqual(store.load(), "1024")
  }

  func testValidLaunchArgumentOverridesTheStoredPasscodeForThatLaunch() {
    XCTAssertEqual(
      AppConfiguration.resolveVaultPasscode(
        arguments: ["LockScreen", "--passcode=2580"],
        storedPasscode: "7531"
      ),
      "2580"
    )
    XCTAssertEqual(
      AppConfiguration.resolveVaultPasscode(
        arguments: ["LockScreen", "--passcode=invalid"],
        storedPasscode: "7531"
      ),
      "7531"
    )
    XCTAssertEqual(
      AppConfiguration.resolveVaultPasscode(
        arguments: ["LockScreen"],
        storedPasscode: "7531"
      ),
      "7531"
    )
  }
}
