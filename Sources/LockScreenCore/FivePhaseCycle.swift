import Foundation

public enum FivePhaseElement: Int, CaseIterable, Identifiable, Sendable {
  case metal
  case wood
  case water
  case fire
  case earth

  public var id: Self { self }
}

public struct FivePhaseCycleState: Equatable, Sendable {
  public static let stageDuration = 3.4

  public let current: FivePhaseElement
  public let next: FivePhaseElement
  public let progress: Double

  public init(time: TimeInterval) {
    let stage = Int(floor(time / Self.stageDuration))
    let elements = FivePhaseElement.allCases
    current = elements[Self.positiveModulo(stage, elements.count)]
    next = elements[Self.positiveModulo(stage + 1, elements.count)]
    progress = (time - floor(time / Self.stageDuration) * Self.stageDuration) / Self.stageDuration
  }

  public func opacity(for element: FivePhaseElement) -> Double {
    let transition = smoothstep((progress - 0.76) / 0.24)
    if element == current { return 1 - transition }
    if element == next { return transition }
    return 0
  }

  public var stageOpacity: Double {
    let edge = 0.12
    if progress < edge { return smoothstep(progress / edge) }
    if progress > 1 - edge { return smoothstep((1 - progress) / edge) }
    return 1
  }

  private func smoothstep(_ value: Double) -> Double {
    let clamped = max(0, min(1, value))
    return clamped * clamped * (3 - 2 * clamped)
  }

  private static func positiveModulo(_ value: Int, _ divisor: Int) -> Int {
    let result = value % divisor
    return result >= 0 ? result : result + divisor
  }
}
