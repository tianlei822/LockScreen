import Foundation
import XCTest

@testable import LockScreenApp

final class LocalizationTests: XCTestCase {
  func testPackagedResourcesLoadFromTheStandardAppResourcesDirectory() throws {
    let temporaryRoot = FileManager.default.temporaryDirectory
      .appendingPathComponent("LocalizationTests.\(UUID().uuidString)")
    let appURL = temporaryRoot.appendingPathComponent("Threshold.app")
    let contentsURL = appURL.appendingPathComponent("Contents")
    let resourcesURL = contentsURL.appendingPathComponent("Resources")
    let resourceBundleURL = resourcesURL.appendingPathComponent(
      "LockScreen_LockScreenApp.bundle"
    )
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }

    try FileManager.default.createDirectory(
      at: resourceBundleURL,
      withIntermediateDirectories: true
    )
    try writeBundleInfo(
      identifier: "com.tianlei.threshold.localization-test",
      packageType: "APPL",
      to: contentsURL.appendingPathComponent("Info.plist")
    )
    try writeBundleInfo(
      identifier: "com.tianlei.threshold.localization-test.resources",
      packageType: "BNDL",
      to: resourceBundleURL.appendingPathComponent("Info.plist")
    )

    let appBundle = try XCTUnwrap(Bundle(url: appURL))
    let resources = try XCTUnwrap(L10n.packagedResourceBundle(in: appBundle))

    XCTAssertEqual(resources.bundleURL.standardizedFileURL, resourceBundleURL.standardizedFileURL)
  }

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

  private func writeBundleInfo(
    identifier: String,
    packageType: String,
    to url: URL
  ) throws {
    let data = try PropertyListSerialization.data(
      fromPropertyList: [
        "CFBundleIdentifier": identifier,
        "CFBundlePackageType": packageType,
      ],
      format: .xml,
      options: 0
    )
    try data.write(to: url)
  }
}
