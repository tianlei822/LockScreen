import Foundation
import XCTest

@testable import LockScreenApp

final class LocalizationTests: XCTestCase {
  func testEnglishControlsUseTheSourceLanguage() {
    XCTAssertEqual(
      L10n.text("Reset ritual", locale: Locale(identifier: "en")),
      "Reset ritual"
    )
  }

  func testSimplifiedChineseControlsResolveFromTheAppResourceBundle() {
    XCTAssertEqual(
      L10n.text("Reset ritual", locale: Locale(identifier: "zh-Hans")),
      "重置仪式"
    )
  }
}
