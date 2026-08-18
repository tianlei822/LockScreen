import LockScreenCore
import SwiftUI

/// The school-specific layer that makes each tracing option feel like a distinct formation.
struct FormationDisciplineLayer: View {
  let trajectory: FormationTrajectory
  let diameter: CGFloat
  let time: TimeInterval
  let energy: Double
  let isActivated: Bool

  var body: some View {
    switch trajectory {
    case .circle:
      fivePhaseFormation
    case .infinity:
      baguaFormation
    case .triangle:
      thunderFormation
    }
  }

  private var fivePhaseFormation: some View {
    FivePhaseCycleField(
      diameter: diameter,
      time: time,
      energy: energy,
      isActivated: isActivated
    )
    .equatable()
  }

  private var baguaFormation: some View {
    let rotation = time * (isActivated ? -20 : -5)
    let style = trajectory.visualStyle

    return ZStack {
      BaguaPeripheralField(
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )
      .frame(width: diameter * 1.28, height: diameter * 1.28)

      OrbitingSubformationField(
        discipline: .bagua,
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )
      .frame(width: diameter * 1.18, height: diameter * 1.18)

      BaguaFormationCanvas(
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )

      Text("☯")
        .font(.system(size: diameter * 0.14, weight: .light))
        .foregroundStyle(
          LinearGradient(
            colors: [style.flare, style.primary, style.secondary],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .rotationEffect(.degrees(rotation))
        .shadow(color: style.primary.opacity(0.72), radius: 12 + energy * 12)

      ForEach(0..<2, id: \.self) { index in
        Circle()
          .fill(index == 0 ? Color.white : style.secondary)
          .frame(width: 5 + energy * 4, height: 5 + energy * 4)
          .shadow(color: style.primary, radius: 8)
          .offset(y: -diameter * 0.19)
          .rotationEffect(.degrees(Double(index) * 180 - rotation * 2))
      }
    }
    .frame(width: diameter, height: diameter)
  }

  private var thunderFormation: some View {
    let style = trajectory.visualStyle
    let flash = pow(max(0, sin(time * 5.7)), 14)
    let boltBeat = 0.5 + 0.5 * sin(time * 5.2)
    let boltBounce = abs(sin(time * 3.4))

    return ZStack {
      OrbitingSubformationField(
        discipline: .thunder,
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )
      .frame(width: diameter * 1.18, height: diameter * 1.18)

      ThunderFormationCanvas(
        time: time,
        energy: energy,
        isActivated: isActivated,
        style: style
      )

      LightningStormField(
        style: style,
        time: time,
        energy: energy,
        isActivated: isActivated,
        seedOffset: 8_111,
        presentation: .core
      )
      .frame(width: diameter * 0.74, height: diameter * 0.74)

      ZStack {
        Circle()
          .fill(style.primary.opacity(0.2 + energy * 0.32 + flash * 0.28))
          .blur(radius: 10 + energy * 10)

        Circle()
          .stroke(Color.white.opacity(0.58 + flash * 0.4), lineWidth: 1 + energy * 1.5)

        Image(systemName: "bolt.fill")
          .font(.system(size: diameter * 0.057, weight: .black))
          .foregroundStyle(
            LinearGradient(
              colors: [.white, style.flare, style.primary],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .shadow(color: style.primary.opacity(0.88), radius: 5 + energy * 8)
          .scaleEffect(0.9 + boltBeat * 0.2 + flash * 0.16)
          .offset(y: -diameter * 0.009 * boltBounce)
          .rotationEffect(.degrees(sin(time * 2.3) * 3.5))
      }
      .frame(width: diameter * 0.105, height: diameter * 0.105)
      .shadow(color: style.primary, radius: 12 + energy * 15)
      .scaleEffect(1 + flash * 0.14 + sin(time * 4.4) * 0.025)
    }
    .frame(width: diameter, height: diameter)
    .blendMode(.plusLighter)
  }

}
