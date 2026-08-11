import AppKit
import XCTest
@testable import LockScreenApp

final class WindowPresentationTests: XCTestCase {
  @MainActor
  func testOverlayWindowsJoinAllSpacesAndApplications() {
    let behavior = WindowPresentation.overlayCollectionBehavior

    XCTAssertTrue(behavior.contains(.canJoinAllSpaces))
    XCTAssertTrue(behavior.contains(.canJoinAllApplications))
  }

  @MainActor
  func testCoverageRefreshesWhenTheActiveSpaceChanges() {
    XCTAssertTrue(
      AppDelegate.coverageRefreshNotifications.contains(
        NSWorkspace.activeSpaceDidChangeNotification
      ))
  }
}
