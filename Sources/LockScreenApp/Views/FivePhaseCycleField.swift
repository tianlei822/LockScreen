import LockScreenCore
import SwiftUI

/// Plays one elemental discipline at a time, cross-fading into the next phase.
struct FivePhaseCycleField: View, Equatable {
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  nonisolated private static let frameRate = 15.0

  nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
    floor(lhs.time * frameRate) == floor(rhs.time * frameRate)
      && lhs.diameter == rhs.diameter
      && lhs.energy == rhs.energy
      && lhs.isActivated == rhs.isActivated
  }

  var body: some View {
    let cycle = FivePhaseCycleState(time: time)

    FivePhaseAttributeStage(
      element: cycle.current,
      diameter: diameter,
      time: time,
      energy: energy,
      isActivated: isActivated
    )
    .opacity(cycle.stageOpacity)
    .scaleEffect(0.9 + cycle.stageOpacity * 0.1)
    .frame(width: diameter, height: diameter)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      L10n.format("Five Phases cycle, %@ active", cycle.current.accessibilityName)
    )
  }
}

private struct FivePhaseAttributeStage: View {
  let element: FivePhaseElement
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    let pulse =
      1 + sin(time * (isActivated ? 4.2 : 1.65) + Double(element.rawValue))
      * (0.018 + energy * 0.022)
    let strokeBreath = CGFloat(
      0.84 + (0.5 + 0.5 * sin(time * 1.35 + Double(element.rawValue) * 0.8)) * 0.3
    )

    ZStack {
      RadialGradient(
        colors: [element.color.opacity(0.2 + energy * 0.2), .clear],
        center: .center,
        startRadius: 0,
        endRadius: diameter * 0.38
      )
      .frame(width: diameter * 0.78, height: diameter * 0.78)
      .blendMode(.plusLighter)

      FivePhaseOuterOrbitField(
        element: element,
        diameter: diameter,
        time: time,
        energy: energy
      )

      FormationConstellation(
        element: element,
        diameter: diameter,
        time: time,
        energy: energy
      )

      pattern

      FivePhaseMaterialDetailLayer(
        element: element,
        time: time,
        energy: energy
      )

      ForEach(0..<3, id: \.self) { index in
        ResonantRing(
          phase: time * (1.1 + Double(index) * 0.28),
          lobes: 4 + element.rawValue + index * 2,
          amplitude: 0.012 + CGFloat(index) * 0.008 + energy * 0.006
        )
        .stroke(
          element.color.opacity(0.12 + Double(index) * 0.08 + energy * 0.18),
          lineWidth: (0.55 + CGFloat(index) * 0.45 + energy * 0.7) * strokeBreath
        )
        .frame(
          width: diameter * (0.46 + CGFloat(index) * 0.115),
          height: diameter * (0.46 + CGFloat(index) * 0.115)
        )
        .rotationEffect(
          .degrees(time * Double(index.isMultiple(of: 2) ? 12 : -10))
        )
      }

      FivePhaseSigil(
        element: element,
        size: diameter * (element == .fire ? 0.17 : 0.24),
        energy: energy,
        time: time
      )
      .opacity(element == .fire ? 0.68 : 1)
      .shadow(color: element.color, radius: 12 + energy * 16)

      FivePhaseElementCore(
        element: element,
        diameter: diameter,
        time: time,
        energy: energy
      )

      ForEach(0..<6, id: \.self) { index in
        Circle()
          .fill(index.isMultiple(of: 2) ? Color.white : element.color)
          .frame(width: 3 + energy * 3, height: 3 + energy * 3)
          .shadow(color: element.color, radius: 5 + energy * 6)
          .offset(y: -diameter * (0.16 + CGFloat(index.isMultiple(of: 2) ? 0.05 : 0.09)))
          .rotationEffect(.degrees(Double(index) * 60 + time * 18))
      }
    }
    .frame(width: diameter, height: diameter)
    .scaleEffect(pulse)
    .blendMode(element == .earth ? .normal : .plusLighter)
  }

  @ViewBuilder
  private var pattern: some View {
    switch element {
    case .wood:
      woodPattern
    case .fire:
      firePattern
    case .earth:
      earthPattern
    case .metal:
      metalPattern
    case .water:
      waterPattern
    }
  }

  private var woodPattern: some View {
    ZStack {
      ForEach(0..<6, id: \.self) { index in
        ZStack {
          BranchFormationShape(phase: time * 0.9 + Double(index))
            .stroke(
              Color(red: 0.18, green: 0.075, blue: 0.025).opacity(0.72),
              style: StrokeStyle(
                lineWidth: 4.2 + CGFloat(index.isMultiple(of: 2) ? 1.5 : 0.4),
                lineCap: .round,
                lineJoin: .round
              )
            )

          BranchFormationShape(phase: time * 0.9 + Double(index))
            .stroke(
              LinearGradient(
                colors: [
                  Color(red: 0.2, green: 0.48, blue: 0.11),
                  element.color.opacity(0.9),
                  Color(red: 0.08, green: 0.3, blue: 0.1),
                ],
                startPoint: .bottom,
                endPoint: .top
              ),
              style: StrokeStyle(
                lineWidth: 0.9 + CGFloat(index.isMultiple(of: 2) ? 1.4 : 0.5) + energy,
                lineCap: .round,
                lineJoin: .round
              )
            )
        }
        .frame(width: diameter * 0.23, height: diameter * 0.42)
        .offset(y: -diameter * 0.18)
        .rotationEffect(.degrees(Double(index) * 60 + time * 4))
      }

      ForEach(0..<6, id: \.self) { index in
        CurlingVineShape(phase: time * 1.05 + Double(index) * 0.8)
          .stroke(
            LinearGradient(
              colors: [
                Color(red: 0.12, green: 0.34, blue: 0.075),
                element.color.opacity(0.86),
              ],
              startPoint: .bottom,
              endPoint: .top
            ),
            style: StrokeStyle(
              lineWidth: 1.15 + CGFloat(index % 2) * 0.7 + energy * 0.6,
              lineCap: .round,
              lineJoin: .round
            )
          )
          .frame(width: diameter * 0.17, height: diameter * 0.26)
          .offset(y: -diameter * 0.27)
          .rotationEffect(.degrees(Double(index) * 60 - time * 5.5))
          .shadow(color: element.color.opacity(0.42), radius: 3 + energy * 3)
      }

      ForEach(0..<12, id: \.self) { index in
        LeafFormationShape()
          .fill(
            LinearGradient(
              colors: [Color.white.opacity(0.76), element.color, Color.green.opacity(0.34)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(
            width: diameter * (index.isMultiple(of: 3) ? 0.034 : 0.026),
            height: diameter * (index.isMultiple(of: 3) ? 0.072 : 0.056)
          )
          .overlay {
            LeafVeinFormationShape()
              .stroke(
                Color(red: 0.08, green: 0.34, blue: 0.16).opacity(0.76),
                style: StrokeStyle(lineWidth: 0.65, lineCap: .round)
              )
          }
          .offset(
            x: sin(Double(index) * 2.4 + time * 0.35) * diameter * 0.17,
            y: -diameter * (0.1 + CGFloat(index % 4) * 0.07)
          )
          .rotationEffect(.degrees(Double(index) * 47 + sin(time + Double(index)) * 12))
          .shadow(color: element.color.opacity(0.72), radius: 4 + energy * 4)
      }
    }
  }

  private var firePattern: some View {
    ZStack {
      SolarFireDragonFormation(diameter: diameter * 0.72, time: time, energy: energy)

      ForEach(0..<3, id: \.self) { index in
        Circle()
          .trim(
            from: 0.06 + Double(index) * 0.085,
            to: 0.71 + Double(index) * 0.065
          )
          .stroke(
            index == 1 ? Color.orange : element.color,
            style: StrokeStyle(
              lineWidth: 0.75 + CGFloat(2 - index) * 0.45 + energy,
              lineCap: .round,
              dash: [diameter * 0.018, diameter * 0.012]
            )
          )
          .frame(width: diameter * (0.36 + CGFloat(index) * 0.1))
          .opacity(0.52 - Double(index) * 0.08 + energy * 0.18)
          .rotationEffect(
            .degrees(time * Double(index.isMultiple(of: 2) ? 13 : -9) + Double(index) * 47)
          )
      }
    }
  }

  private var earthPattern: some View {
    ZStack {
      EarthSealFormation(
        diameter: diameter * 0.68,
        time: time,
        energy: energy,
        color: element.color
      )
      .offset(y: diameter * 0.035)

      ForEach(0..<5, id: \.self) { index in
        EarthPlanetNode(
          size: diameter * (index.isMultiple(of: 2) ? 0.054 : 0.038),
          time: time,
          index: index,
          energy: energy,
          color: element.color
        )
        .offset(y: -diameter * (0.38 + CGFloat(index % 2) * 0.055))
        .rotationEffect(
          .degrees(Double(index) * 72 + time * Double(index.isMultiple(of: 2) ? 7 : -5))
        )
      }

      ForEach(0..<2, id: \.self) { index in
        Rectangle()
          .stroke(
            element.color.opacity(0.17 + Double(1 - index) * 0.12 + energy * 0.16),
            lineWidth: 0.7 + CGFloat(index) * 0.5 + energy * 0.6
          )
          .frame(
            width: diameter * (0.32 + CGFloat(index) * 0.17),
            height: diameter * (0.32 + CGFloat(index) * 0.17)
          )
          .rotationEffect(
            .degrees(45 + Double(index) * 18 + time * Double(index == 0 ? -2.5 : 1.8))
          )
          .scaleEffect(1 + sin(time * 1.1 - Double(index) * 0.7) * 0.022)
      }
    }
  }

  private var metalPattern: some View {
    ZStack {
      swordRing(count: 10, orbit: 0.23, speed: -11, scale: 1, phase: 0)
      swordRing(count: 6, orbit: 0.135, speed: 17, scale: 0.72, phase: 1.7)
      swordRing(count: 18, orbit: 0.335, speed: -23, scale: 0.38, phase: 3.4)
    }
  }

  private func swordRing(
    count: Int,
    orbit: CGFloat,
    speed: Double,
    scale: CGFloat,
    phase: Double
  ) -> some View {
    ForEach(0..<count, id: \.self) { index in
      let bob = sin(time * 1.55 + Double(index) * 1.37 + phase)
      let bank = sin(time * 1.1 + Double(index) * 0.83 + phase) * 7

      ZStack {
        Capsule()
          .fill(
            LinearGradient(
              colors: [
                .clear,
                element.color.opacity(0.08),
                element.color.opacity(0.5 + energy * 0.18),
                Color.white.opacity(0.72),
                .clear,
              ],
              startPoint: .bottom,
              endPoint: .top
            )
          )
          .frame(width: diameter * 0.014 * scale, height: diameter * 0.42 * scale)
          .blur(radius: 2.5 + energy * 2)
          .scaleEffect(y: 0.84 + abs(bob) * 0.28)

        SpiritSwordGlyph(color: element.color, energy: energy)
          .frame(width: diameter * 0.044 * scale, height: diameter * 0.3 * scale)
      }
      .scaleEffect(1 + bob * 0.045)
      .offset(y: -diameter * orbit + bob * diameter * 0.014)
      .rotationEffect(
        .degrees(Double(index) * 360 / Double(count) + time * speed + bank)
      )
      .shadow(color: element.color.opacity(0.82), radius: 5 + energy * 8)
    }
  }

  private var waterPattern: some View {
    ZStack {
      WaterTideFormation(
        diameter: diameter * 0.72,
        time: time,
        energy: energy,
        color: element.color
      )

      ForEach(0..<3, id: \.self) { index in
        WaterCurrentSpiral(phase: time * (1.2 + Double(index) * 0.16) + Double(index))
          .trim(from: 0.05 + Double(index) * 0.08, to: 0.84 - Double(index) * 0.04)
          .stroke(
            LinearGradient(
              colors: [
                Color.white.opacity(0.68),
                element.color.opacity(0.72),
                Color(red: 0.025, green: 0.18, blue: 0.48).opacity(0.34),
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            style: StrokeStyle(
              lineWidth: 1.15 + CGFloat(index) * 0.58 + energy * 0.7,
              lineCap: .round,
              lineJoin: .round
            )
          )
          .frame(
            width: diameter * (0.34 + CGFloat(index) * 0.12),
            height: diameter * (0.25 + CGFloat(index) * 0.09)
          )
          .rotationEffect(.degrees(Double(index) * 52 - time * Double(7 + index * 2)))
          .shadow(color: element.color.opacity(0.48), radius: 4 + energy * 4)
      }

      ForEach(0..<10, id: \.self) { index in
        WaterDropletShape()
          .fill(
            LinearGradient(
              colors: [.white.opacity(0.82), element.color, Color.blue.opacity(0.4)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(
            width: diameter * (index.isMultiple(of: 3) ? 0.018 : 0.012),
            height: diameter * (index.isMultiple(of: 3) ? 0.03 : 0.022)
          )
          .offset(
            y: -diameter
              * (0.29 + CGFloat(index % 3) * 0.037 + sin(time * 1.4 + Double(index)) * 0.012)
          )
          .rotationEffect(.degrees(Double(index) * 36 + time * 11))
          .shadow(color: element.color, radius: 3 + energy * 4)
      }

      ForEach(0..<2, id: \.self) { index in
        ResonantRing(
          phase: -time * (1.5 + Double(index) * 0.18),
          lobes: 5 + index * 2,
          amplitude: 0.018 + CGFloat(index) * 0.006
        )
        .trim(from: 0.08 + Double(index) * 0.04, to: 0.9 - Double(index) * 0.025)
        .stroke(
          element.color.opacity(0.2 + Double(1 - index) * 0.1 + energy * 0.14),
          style: StrokeStyle(
            lineWidth: 0.7 + CGFloat(index) * 0.5 + energy * 0.7,
            lineCap: .round
          )
        )
        .frame(
          width: diameter * (0.46 + CGFloat(index) * 0.16),
          height: diameter * (0.46 + CGFloat(index) * 0.16)
        )
        .rotationEffect(.degrees(time * Double(index.isMultiple(of: 2) ? 6 : -5)))
      }
    }
  }
}
