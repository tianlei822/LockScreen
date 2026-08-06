import Foundation

public enum FormationTrajectory: String, CaseIterable, Identifiable, Sendable {
  case circle
  case infinity
  case triangle

  public var id: Self { self }

  public var title: String {
    switch self {
    case .circle:
      "Circle"
    case .infinity:
      "Infinity"
    case .triangle:
      "Triangle"
    }
  }

  public var symbol: String {
    switch self {
    case .circle:
      "○"
    case .infinity:
      "∞"
    case .triangle:
      "△"
    }
  }
}

public struct NormalizedPoint: Equatable, Sendable {
  public let x: Double
  public let y: Double

  public init(x: Double, y: Double) {
    self.x = x
    self.y = y
  }
}

public enum FormationTrajectoryMatcher {
  public static func template(
    for trajectory: FormationTrajectory,
    sampleCount: Int = 96
  ) -> [NormalizedPoint] {
    let count = max(16, sampleCount)

    switch trajectory {
    case .circle:
      return (0..<count).map { index in
        let angle = Double(index) / Double(count) * 2 * Double.pi
        return NormalizedPoint(
          x: 0.5 + cos(angle) * 0.42,
          y: 0.5 + sin(angle) * 0.42
        )
      }
    case .infinity:
      return (0..<count).map { index in
        let angle = Double(index) / Double(count) * 2 * Double.pi
        return NormalizedPoint(
          x: 0.5 + sin(angle) * 0.43,
          y: 0.5 + sin(angle * 2) * 0.28
        )
      }
    case .triangle:
      let vertices = [
        NormalizedPoint(x: 0.5, y: 0.08),
        NormalizedPoint(x: 0.92, y: 0.86),
        NormalizedPoint(x: 0.08, y: 0.86),
      ]
      return (0..<count).map { index in
        let progress = Double(index) / Double(count) * 3
        let segment = min(2, Int(progress))
        let fraction = progress - Double(segment)
        let start = vertices[segment]
        let end = vertices[(segment + 1) % vertices.count]
        return NormalizedPoint(
          x: start.x + (end.x - start.x) * fraction,
          y: start.y + (end.y - start.y) * fraction
        )
      }
    }
  }

  public static func score(
    _ points: [NormalizedPoint],
    for trajectory: FormationTrajectory
  ) -> Double {
    guard points.count >= 8,
      let normalizedInput = normalize(points),
      let normalizedTemplate = normalize(template(for: trajectory))
    else {
      return 0
    }

    let input = resample(normalizedInput, count: 64)
    let target = resample(normalizedTemplate, count: 64)
    let forwardDistance = bestCircularDistance(input, target)
    let reverseDistance = bestCircularDistance(input, Array(target.reversed()))
    let distance = min(forwardDistance, reverseDistance)

    return max(0, min(1, 1 - distance / 0.3))
  }

  private static func normalize(_ points: [NormalizedPoint]) -> [NormalizedPoint]? {
    guard let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
      let minY = points.map(\.y).min(), let maxY = points.map(\.y).max()
    else {
      return nil
    }

    let width = maxX - minX
    let height = maxY - minY
    guard width > 0.04, height > 0.04 else { return nil }

    return points.map {
      NormalizedPoint(x: ($0.x - minX) / width, y: ($0.y - minY) / height)
    }
  }

  private static func resample(
    _ points: [NormalizedPoint],
    count: Int
  ) -> [NormalizedPoint] {
    guard points.count > 1 else { return points }

    var cumulative = [0.0]
    for index in 1..<points.count {
      cumulative.append(cumulative[index - 1] + distance(points[index - 1], points[index]))
    }

    guard let totalLength = cumulative.last, totalLength > 0 else { return points }
    var result: [NormalizedPoint] = []
    var segment = 1

    for index in 0..<count {
      let targetDistance = totalLength * Double(index) / Double(count - 1)
      while segment < cumulative.count - 1 && cumulative[segment] < targetDistance {
        segment += 1
      }

      let startDistance = cumulative[segment - 1]
      let segmentLength = cumulative[segment] - startDistance
      let fraction = segmentLength > 0 ? (targetDistance - startDistance) / segmentLength : 0
      let start = points[segment - 1]
      let end = points[segment]
      result.append(
        NormalizedPoint(
          x: start.x + (end.x - start.x) * fraction,
          y: start.y + (end.y - start.y) * fraction
        ))
    }

    return result
  }

  private static func bestCircularDistance(
    _ input: [NormalizedPoint],
    _ target: [NormalizedPoint]
  ) -> Double {
    guard input.count == target.count, !input.isEmpty else { return 1 }
    var best = Double.greatestFiniteMagnitude

    for shift in 0..<target.count {
      var total = 0.0
      for index in 0..<input.count {
        total += distance(input[index], target[(index + shift) % target.count])
      }
      best = min(best, total / Double(input.count))
    }

    return best
  }

  private static func distance(_ lhs: NormalizedPoint, _ rhs: NormalizedPoint) -> Double {
    hypot(lhs.x - rhs.x, lhs.y - rhs.y)
  }
}
