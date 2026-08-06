import XCTest

@testable import LockScreenCore

final class FormationTrajectoryTests: XCTestCase {
  func testEachTemplateRecognizesItself() {
    for trajectory in FormationTrajectory.allCases {
      let points = FormationTrajectoryMatcher.template(for: trajectory, sampleCount: 96)

      let score = FormationTrajectoryMatcher.score(points, for: trajectory)

      XCTAssertGreaterThan(score, 0.95, "Expected \(trajectory) to recognize its template")
    }
  }

  func testRecognitionIgnoresDrawingPositionAndScale() {
    let template = FormationTrajectoryMatcher.template(for: .triangle, sampleCount: 96)
    let transformed = template.map {
      NormalizedPoint(x: $0.x * 0.56 + 0.22, y: $0.y * 0.64 + 0.18)
    }

    let score = FormationTrajectoryMatcher.score(transformed, for: .triangle)

    XCTAssertGreaterThan(score, 0.95)
  }

  func testShortStrokeIsRejected() {
    let points = [
      NormalizedPoint(x: 0.1, y: 0.1),
      NormalizedPoint(x: 0.2, y: 0.2),
      NormalizedPoint(x: 0.3, y: 0.3),
    ]

    XCTAssertEqual(FormationTrajectoryMatcher.score(points, for: .circle), 0)
  }
}
