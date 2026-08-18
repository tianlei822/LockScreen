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

  func testImperfectSingleLoopActivatesFivePhases() {
    let points = (0..<48).map { index in
      let angle = Double(index) / 48 * 2 * Double.pi
      let handVariation = 1 + sin(angle * 3) * 0.28 + cos(angle * 5) * 0.12
      return NormalizedPoint(
        x: 0.5 + cos(angle) * 0.38 * handVariation,
        y: 0.5 + sin(angle) * 0.4 * handVariation
      )
    }

    let score = FormationTrajectoryMatcher.score(points, for: .circle)

    XCTAssertGreaterThanOrEqual(score, FormationTrajectoryMatcher.activationThreshold)
  }

  func testOpenZigzagDoesNotActivateFivePhases() {
    let points = (0..<16).map { index in
      NormalizedPoint(
        x: 0.08 + Double(index) * 0.055,
        y: index.isMultiple(of: 2) ? 0.18 : 0.82
      )
    }

    let score = FormationTrajectoryMatcher.score(points, for: .circle)

    XCTAssertLessThan(score, FormationTrajectoryMatcher.activationThreshold)
  }

  func testTraceCompletionTracksHowMuchOfTheFormationWasDrawn() {
    let template = FormationTrajectoryMatcher.template(for: .circle, sampleCount: 96)

    let halfCharge = FormationTrajectoryMatcher.completion(
      Array(template.prefix(template.count / 2)), for: .circle)
    let fullCharge = FormationTrajectoryMatcher.completion(template, for: .circle)

    XCTAssertEqual(halfCharge, 0.5, accuracy: 0.08)
    XCTAssertGreaterThan(fullCharge, 0.95)
  }

  func testTraceAccumulatorIgnoresNearbySamples() {
    var trace = FormationTraceAccumulator(trajectory: .circle)

    XCTAssertTrue(trace.append(NormalizedPoint(x: 0.1, y: 0.1)))
    XCTAssertFalse(trace.append(NormalizedPoint(x: 0.103, y: 0.103)))

    XCTAssertEqual(trace.points, [NormalizedPoint(x: 0.1, y: 0.1)])
    XCTAssertEqual(trace.completion, 0)
  }

  func testTraceAccumulatorBoundsSamplesWithoutLosingTheGesture() {
    var trace = FormationTraceAccumulator(trajectory: .circle)
    let template = FormationTrajectoryMatcher.template(for: .circle, sampleCount: 2_048)

    for point in template {
      trace.append(point)
    }

    XCTAssertLessThanOrEqual(trace.points.count, FormationTraceAccumulator.maximumSampleCount)
    XCTAssertGreaterThan(trace.completion, 0.95)
    XCTAssertGreaterThan(trace.score, 0.95)
  }
}
