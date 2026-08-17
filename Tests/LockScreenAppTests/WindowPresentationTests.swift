import AppKit
import XCTest

@testable import LockScreenApp

final class WindowPresentationTests: XCTestCase {
  @MainActor
  func testAppStaysAliveWhileAnImmersiveRitualReplacesTheSceneWindow() {
    XCTAssertFalse(
      AppDelegate.shouldTerminateAfterLastWindowClosed(
        backgroundMode: false,
        ritualIsImmersive: true
      ))
    XCTAssertTrue(
      AppDelegate.shouldTerminateAfterLastWindowClosed(
        backgroundMode: false,
        ritualIsImmersive: false
      ))
  }

  @MainActor
  func testRitualOverlayUsesANonactivatingPanel() {
    let panel = WindowPresentation.makeRitualPanel(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 240)
    )
    defer { panel.close() }

    XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
    XCTAssertTrue(panel.canBecomeKey)
    XCTAssertTrue(panel.isFloatingPanel)
    XCTAssertFalse(panel.hidesOnDeactivate)
    XCTAssertEqual(panel.level, .screenSaver)
    XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
    XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllApplications))
  }

  @MainActor
  func testRitualPanelRestoresOverlayBehaviorAfterWindowedMode() {
    let panel = WindowPresentation.makeRitualPanel(
      contentRect: NSRect(x: 0, y: 0, width: 320, height: 240)
    )
    defer { panel.close() }
    panel.styleMask = [.borderless]
    panel.isFloatingPanel = false
    panel.hidesOnDeactivate = true
    panel.level = .normal
    panel.collectionBehavior = [.fullScreenPrimary]

    WindowPresentation.configureForImmersivePresentation(panel)

    XCTAssertTrue(panel.styleMask.contains(.nonactivatingPanel))
    XCTAssertTrue(panel.isFloatingPanel)
    XCTAssertFalse(panel.hidesOnDeactivate)
    XCTAssertEqual(panel.level, .screenSaver)
    XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllSpaces))
    XCTAssertTrue(panel.collectionBehavior.contains(.canJoinAllApplications))
  }

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
  func testStatusItemAppearanceRefreshPreservesAppKitCell() throws {
    let button = NSStatusBarButton(
      frame: NSRect(x: 0, y: 0, width: 24, height: 24)
    )
    let cell = try XCTUnwrap(button.cell as? NSButtonCell)
    let originalCell = button.cell
    button.isTransparent = false
    button.isBordered = true
    cell.highlightsBy = [.changeBackgroundCellMask]
    cell.showsStateBy = [.changeBackgroundCellMask]
    cell.isHighlighted = true
    button.state = .on

    AppDelegate.configureTransparentStatusItemAppearance(button)

    XCTAssertTrue(button.cell === originalCell)
    XCTAssertTrue(button.isTransparent)
    XCTAssertFalse(button.isBordered)
    XCTAssertTrue(cell.highlightsBy.isEmpty)
    XCTAssertTrue(cell.showsStateBy.isEmpty)
    XCTAssertFalse(cell.isHighlighted)
    XCTAssertEqual(button.state, .off)
  }

  @MainActor
  func testStatusItemAppearanceRefreshContinuesAfterTheNextRunLoop() {
    XCTAssertGreaterThan(AppDelegate.statusItemAppearanceRefreshDelays.count, 1)
    XCTAssertTrue(
      AppDelegate.statusItemAppearanceRefreshDelays.contains { $0 >= .seconds(1) }
    )
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
