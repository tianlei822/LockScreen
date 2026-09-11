import ImageIO
import XCTest

@testable import LockScreenApp

final class SolarPlanetTextureTests: XCTestCase {
  @MainActor
  func testSunSurfaceAdvancesEveryFrameWithoutQuantizationStalls() throws {
    var previous: CFData?
    // Cross the old 1.5-degree cache boundary at the production angular speed.
    for frame in 0..<24 {
      let spin = (0.45 + Double(frame) / 60) * 0.045
      let image = try XCTUnwrap(
        SolarPlanetTextureRenderer.image(name: "Sun", spin: spin, light: SIMD3(0, 0, 1)))
      let pixels = try XCTUnwrap(image.dataProvider?.data)
      if let previous {
        XCTAssertFalse(previous == pixels, "Sun stalled at frame \(frame)")
      }
      previous = pixels
    }
  }

  func testSphereProjectionRejectsPixelsOutsideDisc() {
    XCTAssertNil(SolarSphereProjection.sample(x: 0.9, y: 0.9))
  }

  func testSphereProjectsEquatorAndNorthPoleOntoTexture() throws {
    let center = try XCTUnwrap(SolarSphereProjection.sample(x: 0, y: 0))
    let north = try XCTUnwrap(SolarSphereProjection.sample(x: 0, y: -1))
    XCTAssertEqual(center.u, 0.5, accuracy: 0.0001)
    XCTAssertEqual(center.v, 0.5, accuracy: 0.0001)
    XCTAssertEqual(north.v, 0, accuracy: 0.0001)
    XCTAssertEqual(center.normal.z, 1, accuracy: 0.0001)
  }

  func testSunFacingHemisphereIsBrighterAndLightingReverses() throws {
    let left = try XCTUnwrap(SolarSphereProjection.sample(x: -0.8, y: 0))
    let right = try XCTUnwrap(SolarSphereProjection.sample(x: 0.8, y: 0))
    let towardLeft = SIMD3<Double>(-1, 0, 0)
    let towardRight = SIMD3<Double>(1, 0, 0)
    XCTAssertGreaterThan(
      left.illumination(light: towardLeft), right.illumination(light: towardLeft))
    XCTAssertGreaterThan(
      right.illumination(light: towardRight), left.illumination(light: towardRight))
  }

  @MainActor
  func testEveryBundledPlanetMapRendersWithTransparentCorners() throws {
    for name in [
      "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Sun",
    ] {
      let image = try XCTUnwrap(
        SolarPlanetTextureRenderer.image(name: name, spin: 0, light: SIMD3(1, 0, 0.4)), name
      )
      let data = try XCTUnwrap(image.dataProvider?.data)
      let pixels = try XCTUnwrap(CFDataGetBytePtr(data))
      XCTAssertEqual(pixels[3], 0, name)
      let middle = (image.height / 2 * image.width + image.width / 2) * 4
      XCTAssertEqual(pixels[middle + 3], 255, name)

      // Opt-in artifacts for visual QA; normal test runs do not write images.
      if let directory = ProcessInfo.processInfo.environment["THRESHOLD_ARTWORK_PREVIEW"] {
        let folder = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = try XCTUnwrap(
          CGImageDestinationCreateWithURL(
            folder.appendingPathComponent("\(name).png") as CFURL, "public.png" as CFString, 1, nil
          ))
        CGImageDestinationAddImage(destination, image, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
      }
    }
  }

  @MainActor
  func testFullRotationReturnsToSameSurfaceAndHalfTurnChangesIt() throws {
    let light = SIMD3<Double>(0, 0, 1)
    let first = try XCTUnwrap(
      SolarPlanetTextureRenderer.image(name: "Earth", spin: 0, light: light))
    let full = try XCTUnwrap(
      SolarPlanetTextureRenderer.image(name: "Earth", spin: 2 * .pi, light: light))
    let half = try XCTUnwrap(
      SolarPlanetTextureRenderer.image(name: "Earth", spin: .pi, light: light))
    XCTAssertEqual(first.dataProvider?.data, full.dataProvider?.data)
    XCTAssertNotEqual(first.dataProvider?.data, half.dataProvider?.data)
  }
}
