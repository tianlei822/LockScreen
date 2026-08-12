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

  @MainActor
  func testRestoringWindowOpacityPreparesItForTheNextPresentation() {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 240),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.alphaValue = 0

    WindowPresentation.restoreWindowOpacity(window)

    XCTAssertEqual(window.alphaValue, 1)
  }
}
