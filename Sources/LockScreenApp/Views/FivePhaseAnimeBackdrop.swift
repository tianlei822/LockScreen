import LockScreenCore
import SwiftUI

/// Full-door anime-style phenomena synchronized with the currently active phase.
struct FivePhaseAnimeBackdrop: View, Equatable {
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  nonisolated private static let frameRate = 12.0

  nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
    floor(lhs.time * frameRate) == floor(rhs.time * frameRate)
      && lhs.energy == rhs.energy
      && lhs.isActivated == rhs.isActivated
  }

  var body: some View {
    let cycle = FivePhaseCycleState(time: time)

    GeometryReader { proxy in
      ElementalAnimeScene(
        element: cycle.current,
        size: proxy.size,
        time: time,
        energy: energy,
        isActivated: isActivated
      )
      .opacity(cycle.stageOpacity)
      .frame(width: proxy.size.width, height: proxy.size.height)
      .clipped()
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
  }
}

struct ElementalAnimeScene: View {
  let element: FivePhaseElement
  let size: CGSize
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    let power = (isActivated ? 1.3 : 0.72 + energy * 0.38)

    ZStack {
      RadialGradient(
        colors: [
          element.color.opacity(0.1 * power),
          element.color.opacity(0.025 * power),
          .clear,
        ],
        center: sceneCenter,
        startRadius: 0,
        endRadius: max(size.width, size.height) * 0.7
      )

      Canvas(rendersAsynchronously: true) { context, canvasSize in
        switch element {
        case .wood:
          drawWood(in: &context, size: canvasSize, power: power)
        case .fire:
          drawFire(in: &context, size: canvasSize, power: power)
        case .earth:
          drawEarth(in: &context, size: canvasSize, power: power)
        case .metal:
          drawMetal(in: &context, size: canvasSize, power: power)
        case .water:
          drawWater(in: &context, size: canvasSize, power: power)
        }
      }
    }
    .blendMode(element == .earth ? .normal : .plusLighter)
  }

  private var sceneCenter: UnitPoint {
    switch element {
    case .wood: UnitPoint(x: 0.5, y: 0.72)
    case .fire: UnitPoint(x: 0.5, y: 0.78)
    case .earth: UnitPoint(x: 0.5, y: 0.68)
    case .metal: .center
    case .water: UnitPoint(x: 0.5, y: 0.56)
    }
  }
}
