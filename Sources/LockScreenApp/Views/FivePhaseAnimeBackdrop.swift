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

private struct ElementalAnimeScene: View {
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

  private func drawWood(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    for treeIndex in 0..<14 {
      let seed = Double(treeIndex + 1)
      let base = CGPoint(
        x: size.width * (0.025 + CGFloat(treeIndex) / 13 * 0.95)
          + sin(time * 0.045 + seed) * size.width * 0.008,
        y: size.height * (0.78 + CGFloat(treeIndex % 4) * 0.055)
      )
      let treeHeight = size.height * (0.16 + CGFloat(treeIndex % 5) * 0.028)
      let crownCenter = CGPoint(
        x: base.x + sin(time * 0.17 + seed * 0.7) * treeHeight * 0.025,
        y: base.y - treeHeight
      )
      let trunkWidth = size.width * (0.005 + CGFloat(treeIndex % 3) * 0.002)
      var trunk = Path()
      trunk.move(to: CGPoint(x: base.x - trunkWidth, y: base.y))
      trunk.addCurve(
        to: CGPoint(x: crownCenter.x - trunkWidth * 0.28, y: crownCenter.y + treeHeight * 0.2),
        control1: CGPoint(x: base.x - trunkWidth * 0.7, y: base.y - treeHeight * 0.38),
        control2: CGPoint(x: crownCenter.x - trunkWidth * 0.8, y: crownCenter.y + treeHeight * 0.42)
      )
      trunk.addLine(
        to: CGPoint(x: crownCenter.x + trunkWidth * 0.28, y: crownCenter.y + treeHeight * 0.2)
      )
      trunk.addCurve(
        to: CGPoint(x: base.x + trunkWidth, y: base.y),
        control1: CGPoint(
          x: crownCenter.x + trunkWidth * 0.8, y: crownCenter.y + treeHeight * 0.42),
        control2: CGPoint(x: base.x + trunkWidth * 0.7, y: base.y - treeHeight * 0.38)
      )
      trunk.closeSubpath()
      context.fill(
        trunk,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.3, green: 0.14, blue: 0.045).opacity(0.24 * power),
            Color(red: 0.06, green: 0.12, blue: 0.045).opacity(0.45 * power),
          ]),
          startPoint: CGPoint(x: base.x - trunkWidth, y: base.y),
          endPoint: crownCenter
        )
      )

      var branches = Path()
      for branch in 0..<5 {
        let branchY = base.y - treeHeight * (0.34 + CGFloat(branch) * 0.11)
        let direction: CGFloat = branch.isMultiple(of: 2) ? -1 : 1
        branches.move(to: CGPoint(x: base.x, y: branchY))
        branches.addCurve(
          to: CGPoint(
            x: crownCenter.x + direction * treeHeight * (0.12 + CGFloat(branch % 3) * 0.035),
            y: branchY - treeHeight * (0.13 + CGFloat(branch % 2) * 0.04)
          ),
          control1: CGPoint(
            x: base.x + direction * treeHeight * 0.04, y: branchY - treeHeight * 0.04),
          control2: CGPoint(
            x: crownCenter.x + direction * treeHeight * 0.08,
            y: branchY - treeHeight * 0.1
          )
        )
      }
      context.stroke(
        branches,
        with: .color(Color(red: 0.18, green: 0.22, blue: 0.07).opacity(0.27 * power)),
        style: StrokeStyle(lineWidth: 1.2 + CGFloat(treeIndex % 3) * 0.45, lineCap: .round)
      )

      for crown in 0..<6 {
        let crownAngle = Double(crown) * 2 * .pi / 6 + seed
        let crownRadius = treeHeight * (0.1 + CGFloat(crown % 3) * 0.018)
        let clusterCenter = CGPoint(
          x: crownCenter.x + cos(crownAngle) * treeHeight * 0.105,
          y: crownCenter.y + sin(crownAngle) * treeHeight * 0.07
        )
        var canopyGlow = context
        canopyGlow.addFilter(.blur(radius: 8 + CGFloat(treeIndex % 4) * 2))
        canopyGlow.fill(
          Path(
            ellipseIn: CGRect(
              x: clusterCenter.x - crownRadius,
              y: clusterCenter.y - crownRadius * 0.72,
              width: crownRadius * 2,
              height: crownRadius * 1.44
            )
          ),
          with: .color(
            Color(red: 0.08, green: 0.38, blue: 0.085)
              .opacity((0.08 + Double(crown % 3) * 0.018) * power)
          )
        )
      }
    }

    for layer in 0..<3 {
      let baseline = size.height * (0.62 + CGFloat(layer) * 0.1)
      let parallax =
        sin(time * (0.055 + Double(layer) * 0.025) + Double(layer) * 1.8)
        * size.width * (0.008 + CGFloat(layer) * 0.004)
      var forest = Path()
      forest.move(to: CGPoint(x: 0, y: size.height))
      forest.addLine(to: CGPoint(x: -size.width * 0.04, y: baseline))

      for tree in 0...22 {
        let fraction = CGFloat(tree) / 22
        let x = size.width * fraction + parallax
        let hash = abs(sin(Double(tree * 13 + layer * 19) * 0.71))
        let height = size.height * CGFloat(0.08 + hash * (0.13 - Double(layer) * 0.018))
        let crown = size.width * (0.012 + CGFloat(tree % 3) * 0.004)
        forest.addLine(to: CGPoint(x: x - crown, y: baseline))
        forest.addLine(to: CGPoint(x: x - crown * 0.36, y: baseline - height * 0.42))
        forest.addLine(to: CGPoint(x: x - crown * 0.72, y: baseline - height * 0.4))
        forest.addLine(to: CGPoint(x: x, y: baseline - height))
        forest.addLine(to: CGPoint(x: x + crown * 0.72, y: baseline - height * 0.4))
        forest.addLine(to: CGPoint(x: x + crown * 0.36, y: baseline - height * 0.42))
        forest.addLine(to: CGPoint(x: x + crown, y: baseline))
      }

      forest.addLine(to: CGPoint(x: size.width, y: size.height))
      forest.closeSubpath()
      var forestLayer = context
      forestLayer.addFilter(.blur(radius: 10 + CGFloat(2 - layer) * 6))
      forestLayer.fill(
        forest,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.11, green: 0.35, blue: 0.08).opacity(
              (0.08 + Double(2 - layer) * 0.025) * power),
            Color(red: 0.025, green: 0.09, blue: 0.035).opacity(
              0.22 + Double(layer) * 0.055),
          ]),
          startPoint: CGPoint(x: size.width / 2, y: baseline - size.height * 0.18),
          endPoint: CGPoint(x: size.width / 2, y: size.height)
        )
      )
    }

    for bladeIndex in 0..<120 {
      let seed = Double(bladeIndex + 1)
      let x = size.width * CGFloat(bladeIndex) / 119
      let baseline = size.height * (0.79 + CGFloat(bladeIndex % 7) * 0.036)
      let bladeHeight = size.height * (0.025 + CGFloat(bladeIndex % 6) * 0.008)
      let sway = sin(time * (0.8 + seed.truncatingRemainder(dividingBy: 5) * 0.07) + seed)
      var grass = Path()
      grass.move(to: CGPoint(x: x, y: baseline))
      grass.addCurve(
        to: CGPoint(x: x + sway * bladeHeight * 0.32, y: baseline - bladeHeight),
        control1: CGPoint(x: x, y: baseline - bladeHeight * 0.36),
        control2: CGPoint(
          x: x + sway * bladeHeight * 0.2,
          y: baseline - bladeHeight * 0.72
        )
      )
      context.stroke(
        grass,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.05, green: 0.19, blue: 0.05).opacity(0.22 * power),
            Color(red: 0.38, green: 0.82, blue: 0.2).opacity(
              (0.2 + Double(bladeIndex % 4) * 0.035) * power),
          ]),
          startPoint: CGPoint(x: x, y: baseline),
          endPoint: CGPoint(x: x, y: baseline - bladeHeight)
        ),
        style: StrokeStyle(
          lineWidth: 0.55 + CGFloat(bladeIndex % 3) * 0.28,
          lineCap: .round
        )
      )
    }

    for index in 0..<11 {
      let fraction = CGFloat(index) / 10
      let start = CGPoint(x: size.width * (0.12 + fraction * 0.76), y: size.height * 1.04)
      let crownX = size.width * (0.5 + sin(Double(index) * 1.7 + time * 0.22) * 0.42)
      let crownY = size.height * (0.1 + CGFloat(index % 4) * 0.07)
      var vine = Path()
      vine.move(to: start)
      vine.addCurve(
        to: CGPoint(x: crownX, y: crownY),
        control1: CGPoint(
          x: start.x + sin(time * 0.42 + Double(index)) * size.width * 0.12,
          y: size.height * 0.76
        ),
        control2: CGPoint(
          x: crownX - cos(time * 0.35 + Double(index)) * size.width * 0.16,
          y: size.height * 0.35
        )
      )

      var glow = context
      glow.addFilter(.blur(radius: 8))
      glow.stroke(
        vine,
        with: .color(element.color.opacity((0.06 + Double(index % 3) * 0.025) * power)),
        style: StrokeStyle(lineWidth: 7 + CGFloat(index % 4) * 2, lineCap: .round)
      )
      context.stroke(
        vine,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.12, green: 0.045, blue: 0.014).opacity(0.86 * power),
            Color(red: 0.28, green: 0.14, blue: 0.045).opacity(0.74 * power),
            Color(red: 0.075, green: 0.26, blue: 0.065).opacity(0.72 * power),
          ]),
          startPoint: start,
          endPoint: CGPoint(x: crownX, y: crownY)
        ),
        style: StrokeStyle(
          lineWidth: 2.8 + CGFloat(index.isMultiple(of: 3) ? 2.4 : 1.1),
          lineCap: .round
        )
      )
      context.stroke(
        vine,
        with: .color(
          Color(red: 0.42, green: 0.9, blue: 0.26)
            .opacity((0.2 + Double(index % 3) * 0.05) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.7 + CGFloat(index.isMultiple(of: 3) ? 1.4 : 0.45),
          lineCap: .round
        )
      )

      for node in 1...3 {
        let nodeFraction = CGFloat(node) / 4
        let x =
          start.x + (crownX - start.x) * nodeFraction
          + sin(time * 0.7 + Double(index * node)) * 12
        let y = start.y + (crownY - start.y) * nodeFraction
        let radius = CGFloat(1.4 + Double((index + node) % 3))
        context.fill(
          Path(
            ellipseIn: CGRect(
              x: x - radius,
              y: y - radius,
              width: radius * 2,
              height: radius * 2
            )),
          with: .color(Color.white.opacity(0.18 * power))
        )

        let leafLength = CGFloat(10 + (index + node) % 4 * 3)
        let leaf = leafPath(
          center: CGPoint(x: x + (node.isMultiple(of: 2) ? -5 : 5), y: y - 2),
          length: leafLength,
          angle: Double(index * 3 + node) * 0.62 + sin(time * 0.5) * 0.18
        )
        context.fill(
          leaf,
          with: .linearGradient(
            Gradient(colors: [
              Color(red: 0.72, green: 0.96, blue: 0.42).opacity(0.78),
              Color(red: 0.17, green: 0.62, blue: 0.19),
              Color(red: 0.025, green: 0.19, blue: 0.065),
            ]),
            startPoint: CGPoint(x: x, y: y - leafLength / 2),
            endPoint: CGPoint(x: x, y: y + leafLength / 2)
          )
        )
        context.stroke(
          leaf,
          with: .color(Color(red: 0.025, green: 0.24, blue: 0.1).opacity(0.72 * power)),
          lineWidth: 0.55
        )
        context.stroke(
          leafVeinPath(
            center: CGPoint(x: x + (node.isMultiple(of: 2) ? -5 : 5), y: y - 2),
            length: leafLength,
            angle: Double(index * 3 + node) * 0.62 + sin(time * 0.5) * 0.18
          ),
          with: .color(Color.white.opacity(0.24 * power)),
          lineWidth: 0.42
        )

        let curlRadius = leafLength * (0.48 + CGFloat(node % 2) * 0.16)
        var curl = Path()
        curl.addArc(
          center: CGPoint(x: x, y: y),
          radius: curlRadius,
          startAngle: .radians(Double(index + node) * 0.72 + time * 0.2),
          endAngle: .radians(Double(index + node) * 0.72 + time * 0.2 + 4.2),
          clockwise: false
        )
        context.stroke(
          curl,
          with: .color(Color(red: 0.43, green: 0.84, blue: 0.2).opacity(0.34 * power)),
          style: StrokeStyle(lineWidth: 0.7, lineCap: .round)
        )
      }
    }
  }

  private func drawFire(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let sealCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.53)
    let sealRadius = min(size.width, size.height) * 0.3
    let fierceSunCenter = CGPoint(
      x: size.width * 0.79 + sin(time * 0.055) * size.width * 0.012,
      y: size.height * 0.2 + cos(time * 0.07) * size.height * 0.009
    )
    let fierceSunPulse = 0.88 + CGFloat(0.5 + 0.5 * sin(time * 1.7)) * 0.12
    let fierceSunRadius = min(size.width, size.height) * 0.105 * fierceSunPulse

    var fierceAura = context
    fierceAura.addFilter(.blur(radius: 34))
    fierceAura.fill(
      Path(
        ellipseIn: CGRect(
          x: fierceSunCenter.x - fierceSunRadius * 2.9,
          y: fierceSunCenter.y - fierceSunRadius * 2.9,
          width: fierceSunRadius * 5.8,
          height: fierceSunRadius * 5.8
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.22 * power),
          Color.yellow.opacity(0.25 * power),
          Color.orange.opacity(0.13 * power),
          Color.red.opacity(0.045 * power),
          .clear,
        ]),
        center: fierceSunCenter,
        startRadius: 0,
        endRadius: fierceSunRadius * 2.9
      )
    )

    for rayIndex in 0..<44 {
      let angle = Double(rayIndex) * 2 * .pi / 44 + time * 0.025
      let rayPulse = 0.5 + 0.5 * sin(time * (1.25 + Double(rayIndex % 5) * 0.06) + Double(rayIndex))
      let innerRadius = fierceSunRadius * 1.02
      let outerRadius = fierceSunRadius * CGFloat(1.3 + rayPulse * 0.66)
      var ray = Path()
      ray.move(
        to: CGPoint(
          x: fierceSunCenter.x + cos(angle) * innerRadius,
          y: fierceSunCenter.y + sin(angle) * innerRadius
        )
      )
      ray.addLine(
        to: CGPoint(
          x: fierceSunCenter.x + cos(angle) * outerRadius,
          y: fierceSunCenter.y + sin(angle) * outerRadius
        )
      )
      context.stroke(
        ray,
        with: .color(
          (rayIndex.isMultiple(of: 4) ? Color.yellow : Color.orange)
            .opacity((0.12 + rayPulse * 0.22) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.6 + CGFloat(rayIndex % 4) * 0.42,
          lineCap: .round
        )
      )
    }

    context.fill(
      Path(
        ellipseIn: CGRect(
          x: fierceSunCenter.x - fierceSunRadius,
          y: fierceSunCenter.y - fierceSunRadius,
          width: fierceSunRadius * 2,
          height: fierceSunRadius * 2
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.72 * power),
          Color.yellow.opacity(0.66 * power),
          Color.orange.opacity(0.44 * power),
          Color.red.opacity(0.17 * power),
        ]),
        center: CGPoint(
          x: fierceSunCenter.x - fierceSunRadius * 0.24,
          y: fierceSunCenter.y - fierceSunRadius * 0.26
        ),
        startRadius: 0,
        endRadius: fierceSunRadius
      )
    )

    for coronaIndex in 0..<7 {
      let start = Double(coronaIndex) * 0.91 + time * (coronaIndex.isMultiple(of: 2) ? 0.08 : -0.06)
      var corona = Path()
      corona.addArc(
        center: fierceSunCenter,
        radius: fierceSunRadius * (1.06 + CGFloat(coronaIndex % 3) * 0.1),
        startAngle: .radians(start),
        endAngle: .radians(start + 0.42 + Double(coronaIndex % 3) * 0.12),
        clockwise: false
      )
      context.stroke(
        corona,
        with: .color(Color.yellow.opacity((0.22 + Double(coronaIndex % 3) * 0.06) * power)),
        style: StrokeStyle(
          lineWidth: 1 + CGFloat(coronaIndex % 3) * 0.65,
          lineCap: .round
        )
      )
    }

    for ring in 0..<3 {
      let radius = sealRadius * (0.74 + CGFloat(ring) * 0.13)
      let ringRect = CGRect(
        x: sealCenter.x - radius,
        y: sealCenter.y - radius,
        width: radius * 2,
        height: radius * 2
      )
      var ringGlow = context
      ringGlow.addFilter(.blur(radius: 5 + CGFloat(ring) * 2))
      ringGlow.stroke(
        Path(ellipseIn: ringRect),
        with: .color(Color.red.opacity((0.08 + Double(ring) * 0.025) * power)),
        lineWidth: 7 - CGFloat(ring)
      )
      context.stroke(
        Path(ellipseIn: ringRect),
        with: .color(
          (ring == 1 ? Color.orange : element.color)
            .opacity((0.2 + Double(2 - ring) * 0.07) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.9 + CGFloat(2 - ring) * 0.45,
          dash: ring == 2 ? [12, 7, 3, 7] : []
        )
      )
    }

    for index in 0..<24 {
      let angle = Double(index) * 2 * .pi / 24 - time * 0.08
      let innerRadius = sealRadius * (index.isMultiple(of: 3) ? 0.84 : 0.9)
      let outerRadius = sealRadius * (index.isMultiple(of: 4) ? 1.02 : 0.97)
      var rune = Path()
      rune.move(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * innerRadius,
          y: sealCenter.y + sin(angle) * innerRadius
        )
      )
      rune.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle + 0.025) * outerRadius,
          y: sealCenter.y + sin(angle + 0.025) * outerRadius
        )
      )
      context.stroke(
        rune,
        with: .color(
          (index.isMultiple(of: 6) ? Color.white : Color.orange)
            .opacity((0.19 + Double(index % 4) * 0.035) * power)
        ),
        style: StrokeStyle(lineWidth: index.isMultiple(of: 4) ? 2.1 : 0.8, lineCap: .round)
      )
    }

    let solarRadius = sealRadius * 0.25
    let auraRect = CGRect(
      x: sealCenter.x - solarRadius * 2.8,
      y: sealCenter.y - solarRadius * 2.8,
      width: solarRadius * 5.6,
      height: solarRadius * 5.6
    )
    var solarAura = context
    solarAura.addFilter(.blur(radius: 24))
    solarAura.fill(
      Path(ellipseIn: auraRect),
      with: .radialGradient(
        Gradient(colors: [
          Color.yellow.opacity(0.35 * power),
          Color.orange.opacity(0.22 * power),
          Color.red.opacity(0.08 * power),
          .clear,
        ]),
        center: sealCenter,
        startRadius: 0,
        endRadius: solarRadius * 2.75
      )
    )

    for index in 0..<28 {
      let seed = Double(index + 1)
      let angle = seed * 2 * Double.pi / 28 + time * 0.045
      let innerRadius = solarRadius * 0.9
      let variation = seed.truncatingRemainder(dividingBy: 6) * 0.07
      let pulse = sin(time * 1.45 + seed * 1.7) * 0.065
      let outerRadius = solarRadius * CGFloat(1.38 + variation + pulse)
      let halfWidth: Double = Double.pi / 72
      var ray = Path()
      ray.move(
        to: CGPoint(
          x: sealCenter.x + cos(angle - halfWidth) * innerRadius,
          y: sealCenter.y + sin(angle - halfWidth) * innerRadius
        )
      )
      ray.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * outerRadius,
          y: sealCenter.y + sin(angle) * outerRadius
        )
      )
      ray.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle + halfWidth) * innerRadius,
          y: sealCenter.y + sin(angle + halfWidth) * innerRadius
        )
      )
      ray.closeSubpath()
      context.fill(
        ray,
        with: .color(
          (index.isMultiple(of: 4) ? Color.yellow : Color.orange)
            .opacity((0.22 + Double(index % 3) * 0.055) * power)
        )
      )
    }

    let sunRect = CGRect(
      x: sealCenter.x - solarRadius,
      y: sealCenter.y - solarRadius,
      width: solarRadius * 2,
      height: solarRadius * 2
    )
    context.fill(
      Path(ellipseIn: sunRect),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.56 * power),
          Color.yellow.opacity(0.5 * power),
          Color.orange.opacity(0.34 * power),
          Color.red.opacity(0.16 * power),
        ]),
        center: CGPoint(x: sealCenter.x - solarRadius * 0.22, y: sealCenter.y - solarRadius * 0.2),
        startRadius: 0,
        endRadius: solarRadius
      )
    )

    for index in 0..<5 {
      let startAngle = Double(index) * 1.18 + time * (index.isMultiple(of: 2) ? 0.07 : -0.055)
      var prominence = Path()
      prominence.addArc(
        center: sealCenter,
        radius: solarRadius * (1.08 + CGFloat(index) * 0.075),
        startAngle: .radians(startAngle),
        endAngle: .radians(startAngle + 0.56 + Double(index % 3) * 0.11),
        clockwise: false
      )
      var prominenceGlow = context
      prominenceGlow.addFilter(.blur(radius: 7))
      prominenceGlow.stroke(
        prominence,
        with: .color(Color.orange.opacity(0.3 * power)),
        style: StrokeStyle(lineWidth: 7, lineCap: .round)
      )
      context.stroke(
        prominence,
        with: .color(Color.yellow.opacity(0.48 * power)),
        style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
      )
    }

    for index in 0..<7 {
      let seed = Double(index + 1)
      let base = CGPoint(
        x: sealCenter.x + CGFloat(index - 3) * sealRadius * 0.16,
        y: sealCenter.y + sealRadius * (0.43 + CGFloat(abs(index - 3)) * 0.018)
      )
      let flame = fireBackdropFlamePath(
        base: base,
        width: sealRadius * CGFloat(0.27 + seed.truncatingRemainder(dividingBy: 3) * 0.045),
        height: sealRadius * CGFloat(0.42 + seed.truncatingRemainder(dividingBy: 4) * 0.07),
        phase: time * (1.3 + seed * 0.03) + seed
      )
      var flameGlow = context
      flameGlow.addFilter(.blur(radius: 10))
      flameGlow.fill(flame, with: .color(Color.orange.opacity(0.22 * power)))
      context.fill(
        flame,
        with: .linearGradient(
          Gradient(colors: [
            Color.yellow.opacity(0.5 * power),
            Color.orange.opacity(0.44 * power),
            Color.red.opacity(0.16 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: base.x, y: base.y - sealRadius * 0.5),
          endPoint: base
        )
      )
    }

    for index in 0..<9 {
      let x = size.width * (0.08 + CGFloat(index) * 0.105)
      let height = size.height * (0.18 + CGFloat(index % 4) * 0.045)
      let flame = fireBackdropFlamePath(
        base: CGPoint(x: x, y: size.height * 1.04),
        width: 76 + CGFloat(index % 3) * 18,
        height: height,
        phase: time * (1.18 + Double(index % 4) * 0.08) + Double(index) * 0.73
      )

      var aura = context
      aura.addFilter(.blur(radius: 14))
      aura.fill(
        flame,
        with: .color(Color.orange.opacity((0.045 + Double(index % 3) * 0.018) * power))
      )
      context.fill(
        flame,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.52, green: 0.008, blue: 0.003).opacity(0.16 * power),
            Color.orange.opacity((0.18 + Double(index % 3) * 0.035) * power),
            Color.yellow.opacity(0.1 * power),
          ]),
          startPoint: CGPoint(x: x, y: size.height),
          endPoint: CGPoint(x: x, y: size.height - height)
        )
      )
      let innerFlame = fireBackdropFlamePath(
        base: CGPoint(x: x + CGFloat(index % 2 == 0 ? -4 : 5), y: size.height * 1.04),
        width: 34 + CGFloat(index % 3) * 8,
        height: height * 0.64,
        phase: time * (1.45 + Double(index % 3) * 0.09) + Double(index) * 1.13
      )
      context.fill(
        innerFlame,
        with: .linearGradient(
          Gradient(colors: [
            Color.orange.opacity(0.22 * power),
            Color.yellow.opacity(0.28 * power),
            Color.white.opacity(0.07 * power),
          ]),
          startPoint: CGPoint(x: x, y: size.height),
          endPoint: CGPoint(x: x, y: size.height - height * 0.62)
        )
      )
    }

    for index in 0..<14 {
      let onLeft = index.isMultiple(of: 2)
      let row = index / 2
      let base = CGPoint(
        x: size.width * (onLeft ? 0.025 : 0.975),
        y: size.height * (0.28 + CGFloat(row) * 0.105)
      )
      let height = size.height * (0.16 + CGFloat(index % 4) * 0.028)
      let flame = fireBackdropFlamePath(
        base: base,
        width: size.width * (0.075 + CGFloat(index % 3) * 0.014),
        height: height,
        phase: time * (1.05 + Double(index % 5) * 0.09) + Double(index) * 0.67
      )
      var edgeGlow = context
      edgeGlow.addFilter(.blur(radius: 18 + CGFloat(index % 3) * 4))
      edgeGlow.fill(
        flame,
        with: .color(Color.orange.opacity((0.055 + Double(index % 3) * 0.018) * power))
      )
      context.fill(
        flame,
        with: .linearGradient(
          Gradient(colors: [
            Color.yellow.opacity(0.16 * power),
            Color.orange.opacity(0.2 * power),
            Color.red.opacity(0.08 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: base.x, y: base.y - height),
          endPoint: base
        )
      )
    }

    for index in 0..<34 {
      let seed = Double(index + 1)
      let x = size.width * CGFloat(abs(sin(seed * 18.31)).truncatingRemainder(dividingBy: 1))
      let travel = (time * (22 + seed.truncatingRemainder(dividingBy: 18)) + seed * 31)
        .truncatingRemainder(dividingBy: Double(size.height))
      let y = size.height - travel
      let radius = CGFloat(0.7 + seed.truncatingRemainder(dividingBy: 3) * 0.5)
      context.fill(
        Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
        with: .color(Color.orange.opacity((0.12 + Double(index % 4) * 0.04) * power))
      )
    }
  }

  private func drawEarth(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let epicenter = CGPoint(x: size.width / 2, y: size.height * 0.7)
    let sealCenter = CGPoint(x: size.width / 2, y: size.height * 0.54)
    let sealRadius = min(size.width, size.height) * 0.31

    for orbit in 0..<3 {
      let orbitRect = CGRect(
        x: sealCenter.x - sealRadius * (1.25 + CGFloat(orbit) * 0.38),
        y: sealCenter.y - sealRadius * (0.58 + CGFloat(orbit) * 0.18),
        width: sealRadius * (2.5 + CGFloat(orbit) * 0.76),
        height: sealRadius * (1.16 + CGFloat(orbit) * 0.36)
      )
      context.stroke(
        Path(ellipseIn: orbitRect),
        with: .color(
          element.color.opacity((0.045 + Double(orbit) * 0.018) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.55 + CGFloat(orbit) * 0.28,
          dash: orbit == 1 ? [8, 7, 2, 7] : []
        )
      )
    }

    for planet in 0..<7 {
      let direction = planet.isMultiple(of: 2) ? 1.0 : -1.0
      let angle = Double(planet) * 2 * .pi / 7 + time * (0.035 + Double(planet) * 0.006) * direction
      let orbitX = sealRadius * (1.32 + CGFloat(planet % 3) * 0.34)
      let orbitY = sealRadius * (0.64 + CGFloat(planet % 3) * 0.16)
      let planetCenter = CGPoint(
        x: sealCenter.x + cos(angle) * orbitX,
        y: sealCenter.y + sin(angle) * orbitY
      )
      let planetRadius = CGFloat(3.8 + Double(planet % 4) * 2)
      let planetRect = CGRect(
        x: planetCenter.x - planetRadius,
        y: planetCenter.y - planetRadius,
        width: planetRadius * 2,
        height: planetRadius * 2
      )
      if planet.isMultiple(of: 3) {
        context.stroke(
          Path(
            ellipseIn: planetRect.insetBy(
              dx: -planetRadius * 0.72,
              dy: planetRadius * 0.5
            )
          ),
          with: .color(Color(red: 0.92, green: 0.66, blue: 0.36).opacity(0.3 * power)),
          lineWidth: 0.65
        )
      }
      context.fill(
        Path(ellipseIn: planetRect),
        with: .radialGradient(
          Gradient(colors: [
            Color(red: 0.96, green: 0.72, blue: 0.42).opacity(0.74 * power),
            element.color.opacity(0.62 * power),
            Color(red: 0.12, green: 0.045, blue: 0.015).opacity(0.86),
          ]),
          center: CGPoint(
            x: planetCenter.x - planetRadius * 0.28,
            y: planetCenter.y - planetRadius * 0.32
          ),
          startRadius: 0,
          endRadius: planetRadius
        )
      )
    }

    let saturnCenter = CGPoint(
      x: size.width * 0.82 + sin(time * 0.075) * size.width * 0.012,
      y: size.height * 0.22 + cos(time * 0.09) * size.height * 0.009
    )
    let saturnRadius = sealRadius * 0.115
    let saturnRect = CGRect(
      x: saturnCenter.x - saturnRadius,
      y: saturnCenter.y - saturnRadius,
      width: saturnRadius * 2,
      height: saturnRadius * 2
    )
    var saturnAura = context
    saturnAura.addFilter(.blur(radius: 16))
    saturnAura.fill(
      Path(ellipseIn: saturnRect.insetBy(dx: -saturnRadius, dy: -saturnRadius)),
      with: .color(Color.orange.opacity(0.055 * power))
    )
    context.stroke(
      Path(
        ellipseIn: CGRect(
          x: saturnCenter.x - saturnRadius * 2.25,
          y: saturnCenter.y - saturnRadius * 0.48,
          width: saturnRadius * 4.5,
          height: saturnRadius * 0.96
        )
      ),
      with: .linearGradient(
        Gradient(colors: [
          .clear,
          Color(red: 0.95, green: 0.73, blue: 0.45).opacity(0.42 * power),
          element.color.opacity(0.26 * power),
          .clear,
        ]),
        startPoint: CGPoint(x: saturnCenter.x - saturnRadius * 2.2, y: saturnCenter.y),
        endPoint: CGPoint(x: saturnCenter.x + saturnRadius * 2.2, y: saturnCenter.y)
      ),
      style: StrokeStyle(lineWidth: saturnRadius * 0.2, lineCap: .round)
    )
    context.fill(
      Path(ellipseIn: saturnRect),
      with: .radialGradient(
        Gradient(colors: [
          Color(red: 0.98, green: 0.76, blue: 0.46).opacity(0.78 * power),
          Color(red: 0.55, green: 0.28, blue: 0.09).opacity(0.7 * power),
          Color(red: 0.12, green: 0.045, blue: 0.015).opacity(0.9),
        ]),
        center: CGPoint(
          x: saturnCenter.x - saturnRadius * 0.3,
          y: saturnCenter.y - saturnRadius * 0.32
        ),
        startRadius: 0,
        endRadius: saturnRadius
      )
    )

    let brokenCenter = CGPoint(
      x: size.width * 0.16 + cos(time * 0.065) * size.width * 0.01,
      y: size.height * 0.28 + sin(time * 0.085) * size.height * 0.008
    )
    let brokenRadius = sealRadius * 0.13
    context.fill(
      Path(
        ellipseIn: CGRect(
          x: brokenCenter.x - brokenRadius,
          y: brokenCenter.y - brokenRadius,
          width: brokenRadius * 2,
          height: brokenRadius * 2
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color(red: 0.84, green: 0.54, blue: 0.27).opacity(0.58 * power),
          Color(red: 0.28, green: 0.12, blue: 0.04).opacity(0.78 * power),
          Color.black.opacity(0.84),
        ]),
        center: CGPoint(
          x: brokenCenter.x - brokenRadius * 0.25,
          y: brokenCenter.y - brokenRadius * 0.3
        ),
        startRadius: 0,
        endRadius: brokenRadius
      )
    )
    for crackIndex in 0..<7 {
      let angle = Double(crackIndex) * 2 * .pi / 7 + 0.34
      var planetCrack = Path()
      planetCrack.move(to: brokenCenter)
      planetCrack.addLine(
        to: CGPoint(
          x: brokenCenter.x + cos(angle) * brokenRadius * 0.45,
          y: brokenCenter.y + sin(angle) * brokenRadius * 0.45
        )
      )
      planetCrack.addLine(
        to: CGPoint(
          x: brokenCenter.x + cos(angle + 0.15) * brokenRadius * 0.94,
          y: brokenCenter.y + sin(angle + 0.15) * brokenRadius * 0.94
        )
      )
      context.stroke(
        planetCrack,
        with: .color(Color.orange.opacity((0.22 + Double(crackIndex % 3) * 0.06) * power)),
        lineWidth: 0.65 + CGFloat(crackIndex % 2) * 0.55
      )
    }
    for fragment in 0..<9 {
      let angle = Double(fragment) * 2 * .pi / 9 - time * 0.08
      let distance = brokenRadius * (1.35 + CGFloat(fragment % 3) * 0.34)
      let fragmentCenter = CGPoint(
        x: brokenCenter.x + cos(angle) * distance,
        y: brokenCenter.y + sin(angle) * distance * 0.68
      )
      let fragmentSize = brokenRadius * (0.13 + CGFloat(fragment % 3) * 0.045)
      var shard = Path()
      shard.move(to: CGPoint(x: fragmentCenter.x, y: fragmentCenter.y - fragmentSize))
      shard.addLine(
        to: CGPoint(x: fragmentCenter.x + fragmentSize * 0.72, y: fragmentCenter.y)
      )
      shard.addLine(
        to: CGPoint(x: fragmentCenter.x - fragmentSize * 0.42, y: fragmentCenter.y + fragmentSize)
      )
      shard.closeSubpath()
      context.fill(
        shard,
        with: .color(
          Color(red: 0.68, green: 0.38, blue: 0.17)
            .opacity((0.25 + Double(fragment % 3) * 0.06) * power)
        )
      )
    }

    for comet in 0..<5 {
      let seed = Double(comet + 1)
      let progress =
        (time * (0.028 + seed * 0.003) + seed * 0.19)
        .truncatingRemainder(dividingBy: 1.35) - 0.18
      let head = CGPoint(
        x: size.width * CGFloat(progress),
        y: size.height * CGFloat(0.08 + seed * 0.065 + progress * 0.24)
      )
      let tail = CGPoint(
        x: head.x - size.width * (0.1 + CGFloat(comet % 3) * 0.035),
        y: head.y - size.height * (0.055 + CGFloat(comet % 2) * 0.025)
      )
      var cometTrail = Path()
      cometTrail.move(to: tail)
      cometTrail.addLine(to: head)
      var cometGlow = context
      cometGlow.addFilter(.blur(radius: 7))
      cometGlow.stroke(
        cometTrail,
        with: .color(Color.orange.opacity(0.13 * power)),
        style: StrokeStyle(lineWidth: 7 + CGFloat(comet % 3) * 2, lineCap: .round)
      )
      context.stroke(
        cometTrail,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            element.color.opacity(0.28 * power),
            Color.white.opacity(0.62 * power),
          ]),
          startPoint: tail,
          endPoint: head
        ),
        style: StrokeStyle(lineWidth: 0.75 + CGFloat(comet % 3) * 0.4, lineCap: .round)
      )
      context.fill(
        Path(ellipseIn: CGRect(x: head.x - 2.4, y: head.y - 2.4, width: 4.8, height: 4.8)),
        with: .color(Color.white.opacity(0.72 * power))
      )
    }

    for ridge in 0..<4 {
      let horizontalShift =
        sin(time * (0.065 + Double(ridge) * 0.018) + Double(ridge) * 1.7)
        * size.width * (0.012 + CGFloat(ridge) * 0.004)
      let verticalShift =
        cos(time * (0.11 + Double(ridge) * 0.02) + Double(ridge))
        * size.height * (0.004 + CGFloat(ridge) * 0.0015)
      let baseline = size.height * (0.46 + CGFloat(ridge) * 0.085) + verticalShift
      var distantRange = Path()
      distantRange.move(to: CGPoint(x: 0, y: size.height))
      distantRange.addLine(to: CGPoint(x: 0, y: baseline))
      for peak in 0...9 {
        let fraction = CGFloat(peak) / 9
        let heightHash = abs(sin(Double(peak * 7 + ridge * 13) * 0.79))
        let height = size.height * CGFloat(0.09 + heightHash * (0.13 - Double(ridge) * 0.014))
        distantRange.addLine(
          to: CGPoint(x: size.width * fraction + horizontalShift, y: baseline - height)
        )
      }
      distantRange.addLine(to: CGPoint(x: size.width, y: size.height))
      distantRange.closeSubpath()

      var distantEarth = context
      distantEarth.addFilter(.blur(radius: 22 + CGFloat(ridge) * 9))
      distantEarth.fill(
        distantRange,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.68, green: 0.43, blue: 0.22).opacity(
              (0.09 - Double(ridge) * 0.015) * power),
            Color(red: 0.16, green: 0.07, blue: 0.025).opacity(
              0.2 + Double(ridge) * 0.04),
          ]),
          startPoint: CGPoint(x: size.width / 2, y: baseline - size.height * 0.18),
          endPoint: CGPoint(x: size.width / 2, y: size.height)
        )
      )
    }

    var earthMist = context
    earthMist.addFilter(.blur(radius: 38))
    for index in 0..<6 {
      let seed = Double(index + 1)
      let mistCenter = CGPoint(
        x: size.width * CGFloat(0.08 + seed.truncatingRemainder(dividingBy: 5) * 0.205)
          + sin(time * 0.1 + seed) * size.width * 0.035,
        y: size.height * CGFloat(0.38 + seed.truncatingRemainder(dividingBy: 3) * 0.14)
          + cos(time * 0.14 + seed) * size.height * 0.012
      )
      let mistWidth = size.width * CGFloat(0.18 + seed.truncatingRemainder(dividingBy: 3) * 0.06)
      let mistHeight = size.height * CGFloat(0.08 + seed.truncatingRemainder(dividingBy: 2) * 0.035)
      earthMist.fill(
        Path(
          ellipseIn: CGRect(
            x: mistCenter.x - mistWidth / 2,
            y: mistCenter.y - mistHeight / 2,
            width: mistWidth,
            height: mistHeight
          )
        ),
        with: .color(
          Color(red: 0.72, green: 0.48, blue: 0.29).opacity(
            (0.035 + Double(index % 3) * 0.012) * power)
        )
      )
    }

    let earthSeal = Path(
      ellipseIn: CGRect(
        x: sealCenter.x - sealRadius,
        y: sealCenter.y - sealRadius,
        width: sealRadius * 2,
        height: sealRadius * 2
      )
    )
    var sealedEarth = context
    sealedEarth.clip(to: earthSeal)

    for ring in 0..<3 {
      let radius = sealRadius * (0.72 + CGFloat(ring) * 0.14)
      context.stroke(
        Path(
          ellipseIn: CGRect(
            x: sealCenter.x - radius,
            y: sealCenter.y - radius,
            width: radius * 2,
            height: radius * 2
          )
        ),
        with: .color(
          element.color.opacity((0.11 + Double(2 - ring) * 0.035) * power)
        ),
        style: StrokeStyle(
          lineWidth: 0.65 + CGFloat(2 - ring) * 0.35,
          dash: ring == 2 ? [10, 7, 2, 7] : []
        )
      )
    }

    for index in 0..<12 {
      let angle = Double(index) * 2 * .pi / 12 - .pi / 2
      var meridian = Path()
      meridian.move(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * sealRadius * 0.22,
          y: sealCenter.y + sin(angle) * sealRadius * 0.22
        )
      )
      meridian.addLine(
        to: CGPoint(
          x: sealCenter.x + cos(angle) * sealRadius,
          y: sealCenter.y + sin(angle) * sealRadius
        )
      )
      context.stroke(
        meridian,
        with: .color(element.color.opacity((0.08 + Double(index % 3) * 0.025) * power)),
        style: StrokeStyle(
          lineWidth: index.isMultiple(of: 3) ? 1.15 : 0.48,
          dash: index.isMultiple(of: 3) ? [] : [5, 7]
        )
      )
    }

    let ground = CGRect(
      x: 0,
      y: size.height * 0.66,
      width: size.width,
      height: size.height * 0.34
    )
    context.fill(
      Path(ground),
      with: .linearGradient(
        Gradient(colors: [
          Color(red: 0.42, green: 0.24, blue: 0.11).opacity(0.11 * power),
          Color(red: 0.12, green: 0.055, blue: 0.025).opacity(0.34),
        ]),
        startPoint: CGPoint(x: ground.midX, y: ground.minY),
        endPoint: CGPoint(x: ground.midX, y: ground.maxY)
      )
    )

    for ridge in 0..<4 {
      let parallax =
        sin(time * (0.085 + Double(ridge) * 0.023) + Double(ridge) * 1.3)
        * size.width * (0.008 + CGFloat(ridge) * 0.003)
      let lift =
        cos(time * (0.16 + Double(ridge) * 0.025) + Double(ridge) * 0.9)
        * size.height * (0.004 + CGFloat(ridge) * 0.0015)
      let y = size.height * (0.48 + CGFloat(ridge) * 0.1) + lift
      var mountains = Path()
      mountains.move(to: CGPoint(x: 0, y: size.height))
      mountains.addLine(to: CGPoint(x: 0, y: y))
      let pointCount = 14
      for peak in 0...pointCount {
        let fraction = CGFloat(peak) / CGFloat(pointCount)
        let xJitter =
          peak == 0 || peak == pointCount
          ? 0
          : sin(Double(peak * 11 + ridge * 17)) * Double(size.width) * 0.012
        let x = size.width * fraction + CGFloat(xJitter) + parallax
        let hash = abs(sin(Double((peak + 3) * (ridge + 5)) * 1.913))
        let accent = (peak + ridge * 2) % 6 == 0 ? 0.11 : 0
        let prominence = 0.025 + hash * (0.08 + Double(3 - ridge) * 0.022) + accent
        let peakY = y - size.height * CGFloat(prominence)
        mountains.addLine(to: CGPoint(x: x, y: peakY))
      }
      mountains.addLine(to: CGPoint(x: size.width, y: size.height))
      mountains.closeSubpath()
      sealedEarth.fill(
        mountains,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.72, green: 0.46, blue: 0.25).opacity(
              (0.1 + Double(3 - ridge) * 0.036) * power),
            Color(red: 0.18, green: 0.085, blue: 0.036).opacity(
              0.18 + Double(ridge) * 0.075),
          ]),
          startPoint: CGPoint(x: size.width / 2, y: y - size.height * 0.12),
          endPoint: CGPoint(x: size.width / 2, y: size.height)
        )
      )
      sealedEarth.stroke(
        mountains,
        with: .color(
          Color(red: 0.9, green: 0.65, blue: 0.36).opacity(
            (0.1 + Double(3 - ridge) * 0.035) * power)),
        style: StrokeStyle(lineWidth: 0.8 + CGFloat(ridge) * 0.42, lineJoin: .round)
      )
    }

    for ridge in 0..<3 {
      let baseline = size.height * (0.72 + CGFloat(ridge) * 0.085)
      let amplitude = size.height * (0.022 + CGFloat(ridge) * 0.006)
      var contour = Path()
      for point in 0...80 {
        let fraction = CGFloat(point) / 80
        let hash = abs(sin(Double(point + ridge * 11) * 0.73))
        let accent = (point + ridge) % 17 == 0 ? 0.7 : 0
        let y = baseline - amplitude * CGFloat(0.18 + hash * 0.58 + accent)
        let contourPoint = CGPoint(x: size.width * fraction, y: y)
        point == 0 ? contour.move(to: contourPoint) : contour.addLine(to: contourPoint)
      }
      context.stroke(
        contour,
        with: .color(element.color.opacity((0.055 + Double(ridge) * 0.018) * power)),
        style: StrokeStyle(lineWidth: 0.7 + CGFloat(ridge) * 0.28, lineJoin: .round)
      )
    }

    for index in 0..<16 {
      let angle = -.pi * 0.96 + Double(index) / 15 * .pi * 0.92
      var crack = Path()
      crack.move(to: epicenter)
      var current = epicenter
      for step in 1...6 {
        let length = CGFloat(step) * size.height * 0.055
        current = CGPoint(
          x: epicenter.x + cos(angle) * length + sin(Double(step * index) * 2.1) * 11,
          y: epicenter.y - sin(angle) * length
        )
        crack.addLine(to: current)
      }
      var glow = context
      glow.addFilter(.blur(radius: 5))
      glow.stroke(
        crack,
        with: .color(element.color.opacity(0.1 * power)),
        lineWidth: 5
      )
      context.stroke(
        crack,
        with: .color(element.color.opacity((0.2 + Double(index % 3) * 0.07) * power)),
        lineWidth: 0.7 + CGFloat(index % 3) * 0.5
      )
    }
  }

  private func drawMetal(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    let reach = min(size.width, size.height) * 0.46
    let unit = min(size.width, size.height)

    var alloyAura = context
    alloyAura.addFilter(.blur(radius: 42))
    alloyAura.fill(
      Path(
        ellipseIn: CGRect(
          x: center.x - unit * 0.42,
          y: center.y - unit * 0.42,
          width: unit * 0.84,
          height: unit * 0.84
        )
      ),
      with: .radialGradient(
        Gradient(colors: [
          Color.white.opacity(0.08 * power),
          Color(red: 0.24, green: 0.72, blue: 0.56).opacity(0.09 * power),
          Color(red: 0.015, green: 0.2, blue: 0.13).opacity(0.04 * power),
          .clear,
        ]),
        center: center,
        startRadius: 0,
        endRadius: unit * 0.42
      )
    )

    for relicIndex in 0..<18 {
      let relicKind = relicIndex % 6
      let angle = Double(relicIndex) * 2 * .pi / 18 - time * 0.025
      let orbitX = reach * (1.22 + CGFloat(relicIndex % 3) * 0.09)
      let orbitY = reach * (0.88 + CGFloat(relicIndex % 4) * 0.055)
      let relicCenter = CGPoint(
        x: center.x + cos(angle) * orbitX,
        y: center.y + sin(angle) * orbitY
          + sin(time * (0.42 + Double(relicKind) * 0.04) + Double(relicIndex)) * 5
      )
      let relicScale = unit * (0.052 + CGFloat(relicIndex % 4) * 0.008)
      let relicAngle =
        relicKind < 2
        ? angle + .pi / 2 + sin(time * 0.3 + Double(relicIndex)) * 0.09
        : sin(time * 0.38 + Double(relicIndex)) * 0.12
      let relic = bronzeRelicPath(
        center: relicCenter,
        scale: relicScale,
        angle: relicAngle,
        kind: relicKind
      )
      let relicFlash =
        0.42 + 0.58
        * (0.5 + 0.5 * sin(time * (1.25 + Double(relicKind) * 0.11) + Double(relicIndex)))
      var relicGlow = context
      relicGlow.addFilter(.blur(radius: 8 + CGFloat(relicIndex % 4) * 2))
      relicGlow.stroke(
        relic,
        with: .color(
          (relicKind >= 4 ? Color.orange : element.color)
            .opacity((0.055 + relicFlash * 0.055) * power)
        ),
        style: StrokeStyle(lineWidth: 7 + CGFloat(relicIndex % 3) * 2, lineCap: .round)
      )
      context.stroke(
        relic,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.78, green: 0.48, blue: 0.2).opacity(
              (0.24 + relicFlash * 0.2) * power),
            Color.white.opacity((0.2 + relicFlash * 0.3) * power),
            element.color.opacity((0.24 + relicFlash * 0.24) * power),
          ]),
          startPoint: CGPoint(x: relicCenter.x - relicScale, y: relicCenter.y - relicScale),
          endPoint: CGPoint(x: relicCenter.x + relicScale, y: relicCenter.y + relicScale)
        ),
        style: StrokeStyle(
          lineWidth: 0.7 + CGFloat(relicFlash) * 0.85,
          lineCap: .round,
          lineJoin: .round
        )
      )
    }

    for swordIndex in 0..<15 {
      let fraction = CGFloat(swordIndex) / 14
      let sideBias = abs(fraction - 0.5) * 2
      let swordCenter = CGPoint(
        x: size.width * (0.035 + fraction * 0.93),
        y: size.height * (0.83 + CGFloat(swordIndex % 3) * 0.045)
          + sin(time * 0.35 + Double(swordIndex)) * 3
      )
      let length = unit * (0.18 + sideBias * 0.11 + CGFloat(swordIndex % 3) * 0.025)
      let angle = sin(Double(swordIndex) * 1.7) * 0.17
      let plantedSword = spiritSwordPath(
        center: swordCenter,
        length: length,
        width: length * 0.12,
        angle: angle
      )
      var plantedGlow = context
      plantedGlow.addFilter(.blur(radius: 9 + CGFloat(swordIndex % 4) * 2))
      plantedGlow.fill(
        plantedSword,
        with: .color(element.color.opacity((0.035 + Double(swordIndex % 3) * 0.015) * power))
      )
      context.fill(
        plantedSword,
        with: .linearGradient(
          Gradient(colors: [
            Color.white.opacity(0.16 * power),
            element.color.opacity(0.14 * power),
            Color(red: 0.015, green: 0.08, blue: 0.055).opacity(0.52),
          ]),
          startPoint: CGPoint(x: swordCenter.x, y: swordCenter.y - length * 0.5),
          endPoint: CGPoint(x: swordCenter.x, y: swordCenter.y + length * 0.5)
        )
      )
      context.stroke(
        spiritSwordDetailPath(
          center: swordCenter,
          length: length,
          width: length * 0.12,
          angle: angle
        ),
        with: .color(Color.white.opacity((0.08 + Double(swordIndex % 3) * 0.025) * power)),
        lineWidth: 0.5
      )
    }

    for shardIndex in 0..<22 {
      let seed = Double(shardIndex + 1)
      let progress =
        (time * (0.035 + seed.truncatingRemainder(dividingBy: 5) * 0.006) + seed * 0.083)
        .truncatingRemainder(dividingBy: 1.28) - 0.14
      let head = CGPoint(
        x: size.width * CGFloat(1.08 - progress),
        y: size.height
          * CGFloat(
            0.06 + abs(sin(seed * 2.4)) * 0.62 + progress * 0.18
          )
      )
      let tail = CGPoint(
        x: head.x + size.width * (0.035 + CGFloat(shardIndex % 4) * 0.012),
        y: head.y - size.height * (0.02 + CGFloat(shardIndex % 3) * 0.008)
      )
      var shardTrail = Path()
      shardTrail.move(to: tail)
      shardTrail.addLine(to: head)
      context.stroke(
        shardTrail,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            element.color.opacity(0.2 * power),
            Color.white.opacity(0.48 * power),
          ]),
          startPoint: tail,
          endPoint: head
        ),
        style: StrokeStyle(lineWidth: 0.55 + CGFloat(shardIndex % 3) * 0.35, lineCap: .round)
      )

      let shardSize = 2.2 + CGFloat(shardIndex % 4)
      var shard = Path()
      shard.move(to: CGPoint(x: head.x, y: head.y - shardSize))
      shard.addLine(to: CGPoint(x: head.x + shardSize * 0.55, y: head.y))
      shard.addLine(to: CGPoint(x: head.x, y: head.y + shardSize * 1.3))
      shard.addLine(to: CGPoint(x: head.x - shardSize * 0.55, y: head.y))
      shard.closeSubpath()
      context.fill(
        shard,
        with: .color(Color.white.opacity((0.22 + Double(shardIndex % 4) * 0.05) * power))
      )
    }

    for index in 0..<10 {
      let angle = Double(index) * 2 * Double.pi / 10 + time * 0.04
      let orbit = reach * (0.84 + CGFloat(index % 3) * 0.07)
      let ghostCenter = CGPoint(
        x: center.x + cos(angle) * orbit,
        y: center.y + sin(angle) * orbit
      )
      let ghostLength = unit * (0.28 + CGFloat(index % 4) * 0.026)
      let ghostWidth = ghostLength * 0.16
      let ghost = spiritSwordPath(
        center: ghostCenter,
        length: ghostLength,
        width: ghostWidth,
        angle: angle + Double.pi / 2
      )
      var ghostLayer = context
      ghostLayer.addFilter(.blur(radius: 15 + CGFloat(index % 3) * 5))
      ghostLayer.fill(
        ghost,
        with: .color(
          (index.isMultiple(of: 3) ? Color.white : element.color)
            .opacity((0.045 + Double(index % 3) * 0.014) * power)
        )
      )
    }

    for index in 0..<8 {
      let angle = Double(index) * Double.pi / 4 - time * 0.025
      var beam = Path()
      beam.move(to: center)
      beam.addLine(
        to: CGPoint(
          x: center.x + cos(angle) * reach * 1.55,
          y: center.y + sin(angle) * reach * 1.55
        )
      )
      var beamGlow = context
      beamGlow.addFilter(.blur(radius: 16))
      beamGlow.stroke(
        beam,
        with: .color(
          Color(red: 0.5, green: 0.92, blue: 0.78).opacity(
            (0.035 + Double(index % 2) * 0.018) * power)
        ),
        style: StrokeStyle(lineWidth: 18 + CGFloat(index % 3) * 5, lineCap: .round)
      )
    }

    for ring in 0..<2 {
      let count = ring == 0 ? 10 : 6
      let direction = ring == 0 ? 1.0 : -1.0
      let rotation = time * (ring == 0 ? 0.17 : -0.27)

      for index in 0..<count {
        let angle = Double(index) * 2 * .pi / Double(count) + rotation
        let bob = sin(time * 1.45 + Double(index) * 1.31 + Double(ring))
        let orbit = reach * (ring == 0 ? 0.72 : 0.4) + bob * reach * 0.035
        let swordCenter = CGPoint(
          x: center.x + cos(angle) * orbit,
          y: center.y + sin(angle) * orbit
        )
        let length = min(size.width, size.height) * (ring == 0 ? 0.2 : 0.14)
        let width = length * 0.115
        let bank = sin(time * 1.1 + Double(index) * 0.77) * 0.11
        let swordAngle = angle + .pi / 2 + bank
        let sword = spiritSwordPath(
          center: swordCenter,
          length: length,
          width: width,
          angle: swordAngle
        )

        let trailAngle = angle - direction * .pi / 2
        var trail = Path()
        trail.move(to: swordCenter)
        trail.addCurve(
          to: CGPoint(
            x: swordCenter.x + cos(trailAngle) * length * 0.72,
            y: swordCenter.y + sin(trailAngle) * length * 0.72
          ),
          control1: CGPoint(
            x: swordCenter.x + cos(trailAngle) * length * 0.24,
            y: swordCenter.y + sin(trailAngle) * length * 0.24
          ),
          control2: CGPoint(
            x: swordCenter.x + cos(trailAngle + direction * 0.22) * length * 0.52,
            y: swordCenter.y + sin(trailAngle + direction * 0.22) * length * 0.52
          )
        )
        var trailGlow = context
        trailGlow.addFilter(.blur(radius: 5))
        trailGlow.stroke(
          trail,
          with: .color(element.color.opacity(0.13 * power)),
          style: StrokeStyle(lineWidth: ring == 0 ? 5 : 3, lineCap: .round)
        )

        var glow = context
        glow.addFilter(.blur(radius: 7))
        glow.fill(sword, with: .color(element.color.opacity(0.15 * power)))
        context.fill(
          sword,
          with: .linearGradient(
            Gradient(colors: [
              Color.white.opacity(0.9 * power),
              element.color.opacity(0.72 * power),
              Color(red: 0.02, green: 0.2, blue: 0.13).opacity(0.82 * power),
            ]),
            startPoint: rotatedPoint(
              x: -width * 0.8, y: 0, around: swordCenter, angle: swordAngle),
            endPoint: rotatedPoint(
              x: width * 0.8, y: 0, around: swordCenter, angle: swordAngle)
          )
        )
        context.stroke(
          sword,
          with: .color(Color.white.opacity((0.3 + Double(index % 3) * 0.08) * power)),
          lineWidth: ring == 0 ? 0.85 : 0.6
        )
        context.stroke(
          spiritSwordDetailPath(
            center: swordCenter,
            length: length,
            width: width,
            angle: swordAngle
          ),
          with: .color(Color(red: 0.02, green: 0.3, blue: 0.18).opacity(0.86 * power)),
          style: StrokeStyle(lineWidth: 0.5, lineCap: .round)
        )
      }
    }
  }

  private func drawWater(
    in context: inout GraphicsContext,
    size: CGSize,
    power: Double
  ) {
    for oceanBand in 0..<5 {
      let baseline = size.height * (0.5 + CGFloat(oceanBand) * 0.095)
      let amplitude = size.height * (0.02 + CGFloat(oceanBand) * 0.006)
      var crest = Path()
      for pointIndex in 0...120 {
        let fraction = CGFloat(pointIndex) / 120
        let phase =
          Double(fraction) * .pi * (2.15 + Double(oceanBand) * 0.33)
          - time * (0.34 + Double(oceanBand) * 0.1)
        let swell = sin(phase)
        let detail = sin(phase * 2.7 + Double(oceanBand) * 0.8) * 0.24
        let point = CGPoint(
          x: size.width * fraction,
          y: baseline + CGFloat(swell + detail) * amplitude
        )
        pointIndex == 0 ? crest.move(to: point) : crest.addLine(to: point)
      }

      var oceanBody = crest
      oceanBody.addLine(to: CGPoint(x: size.width, y: size.height))
      oceanBody.addLine(to: CGPoint(x: 0, y: size.height))
      oceanBody.closeSubpath()
      context.fill(
        oceanBody,
        with: .linearGradient(
          Gradient(colors: [
            Color(red: 0.14, green: 0.54, blue: 0.92).opacity(
              (0.055 + Double(4 - oceanBand) * 0.012) * power),
            element.color.opacity((0.075 + Double(oceanBand) * 0.018) * power),
            Color(red: 0.008, green: 0.035, blue: 0.105).opacity(
              0.28 + Double(oceanBand) * 0.035),
          ]),
          startPoint: CGPoint(x: size.width / 2, y: baseline - amplitude),
          endPoint: CGPoint(x: size.width / 2, y: size.height)
        )
      )
      var oceanGlow = context
      oceanGlow.addFilter(.blur(radius: 6 + CGFloat(oceanBand) * 2))
      oceanGlow.stroke(
        crest,
        with: .color(element.color.opacity((0.07 + Double(oceanBand) * 0.015) * power)),
        style: StrokeStyle(lineWidth: 7 + CGFloat(oceanBand) * 2, lineCap: .round)
      )
      context.stroke(
        crest,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            Color.white.opacity((0.22 + Double(oceanBand % 2) * 0.08) * power),
            element.color.opacity(0.18 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: 0, y: baseline),
          endPoint: CGPoint(x: size.width, y: baseline)
        ),
        style: StrokeStyle(
          lineWidth: 0.75 + CGFloat(oceanBand % 3) * 0.48,
          lineCap: .round,
          lineJoin: .round
        )
      )
    }

    for index in 0..<110 {
      let seed = Double(index + 1)
      let xHash = abs(sin(seed * 17.731) * 4_375.3).truncatingRemainder(dividingBy: 1)
      let x = size.width * CGFloat(xHash)
      let speed = 230 + seed.truncatingRemainder(dividingBy: 7) * 31
      let travel = (time * speed + seed * 43).truncatingRemainder(
        dividingBy: Double(size.height * 1.18))
      let y = -size.height * 0.12 + CGFloat(travel)
      let length = CGFloat(11 + seed.truncatingRemainder(dividingBy: 8) * 4.2)
      let slant = length * 0.19
      var rain = Path()
      rain.move(to: CGPoint(x: x, y: y))
      rain.addLine(to: CGPoint(x: x - slant, y: y + length))

      if index.isMultiple(of: 9) {
        var rainGlow = context
        rainGlow.addFilter(.blur(radius: 3))
        rainGlow.stroke(
          rain,
          with: .color(element.color.opacity(0.2 * power)),
          style: StrokeStyle(lineWidth: 3.2, lineCap: .round)
        )
      }
      context.stroke(
        rain,
        with: .linearGradient(
          Gradient(colors: [
            Color.white.opacity(0),
            Color.white.opacity((0.24 + Double(index % 5) * 0.08) * power),
            element.color.opacity(0.12 * power),
          ]),
          startPoint: CGPoint(x: x, y: y),
          endPoint: CGPoint(x: x - slant, y: y + length)
        ),
        style: StrokeStyle(
          lineWidth: index.isMultiple(of: 7) ? 1.25 : 0.62,
          lineCap: .round
        )
      )
    }

    for index in 0..<34 {
      let seed = Double(index + 1)
      let x =
        size.width
        * CGFloat(
          abs(sin(seed * 11.93) * 6_217).truncatingRemainder(dividingBy: 1))
      let travel = (time * (17 + seed.truncatingRemainder(dividingBy: 9)) + seed * 29)
        .truncatingRemainder(dividingBy: Double(size.height * 1.12))
      let center = CGPoint(
        x: x + sin(time * 0.55 + seed) * 16,
        y: -size.height * 0.08 + CGFloat(travel)
      )
      let radius = CGFloat(2.6 + seed.truncatingRemainder(dividingBy: 4) * 1.2)
      let flake = snowCrystalPath(center: center, radius: radius, rotation: time * 0.36 + seed)
      var flakeGlow = context
      flakeGlow.addFilter(.blur(radius: 2.5))
      flakeGlow.stroke(
        flake,
        with: .color(element.color.opacity(0.2 * power)),
        style: StrokeStyle(lineWidth: 2.8, lineCap: .round)
      )
      context.stroke(
        flake,
        with: .color(Color.white.opacity((0.34 + Double(index % 4) * 0.065) * power)),
        style: StrokeStyle(lineWidth: 0.72, lineCap: .round)
      )
    }

    let tideCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.55)
    let tideRadius = min(size.width, size.height) * 0.31

    for current in 0..<6 {
      let radiusX = tideRadius * (1.08 + CGFloat(current) * 0.18)
      let radiusY = tideRadius * (0.52 + CGFloat(current) * 0.08)
      let phase = time * (current.isMultiple(of: 2) ? 0.19 : -0.14) + Double(current) * 0.84
      var currentPath = Path()
      for point in 0...48 {
        let progress = Double(point) / 48
        let angle = phase + progress * (1.5 + Double(current % 3) * 0.24)
        let currentPoint = CGPoint(
          x: tideCenter.x + cos(angle) * radiusX,
          y: tideCenter.y + sin(angle) * radiusY
        )
        point == 0 ? currentPath.move(to: currentPoint) : currentPath.addLine(to: currentPoint)
      }
      var currentGlow = context
      currentGlow.addFilter(.blur(radius: 5 + CGFloat(current)))
      currentGlow.stroke(
        currentPath,
        with: .color(element.color.opacity((0.08 + Double(current % 3) * 0.025) * power)),
        style: StrokeStyle(lineWidth: 5 + CGFloat(current), lineCap: .round)
      )
      context.stroke(
        currentPath,
        with: .linearGradient(
          Gradient(colors: [
            .clear,
            Color.white.opacity(0.34 * power),
            element.color.opacity(0.32 * power),
            .clear,
          ]),
          startPoint: CGPoint(x: tideCenter.x - radiusX, y: tideCenter.y),
          endPoint: CGPoint(x: tideCenter.x + radiusX, y: tideCenter.y)
        ),
        style: StrokeStyle(
          lineWidth: 0.8 + CGFloat(current % 3) * 0.45,
          lineCap: .round
        )
      )
    }

    let tideRect = CGRect(
      x: tideCenter.x - tideRadius,
      y: tideCenter.y - tideRadius,
      width: tideRadius * 2,
      height: tideRadius * 2
    )
    let tideSeal = Path(ellipseIn: tideRect)
    var sealedTide = context
    sealedTide.clip(to: tideSeal)

    for band in 0..<4 {
      let baseline = tideCenter.y - tideRadius * 0.1 + CGFloat(band) * tideRadius * 0.2
      let amplitude = tideRadius * (0.1 + CGFloat(band) * 0.016)
      var wave = Path()
      var foam = Path()
      var drawingFoam = false

      for point in 0...90 {
        let fraction = CGFloat(point) / 90
        let x = tideRect.minX + tideRect.width * fraction
        let phase =
          Double(fraction) * .pi * Double(2.35 + CGFloat(band) * 0.34)
          - time * (1.05 + Double(band) * 0.16)
        let primary = sin(phase)
        let chop = sin(phase * 2.3 + Double(band)) * 0.23
        let crest = max(0, primary) * 0.38
        let y = baseline + CGFloat(primary + chop - crest) * amplitude
        point == 0
          ? wave.move(to: CGPoint(x: x, y: y))
          : wave.addLine(to: CGPoint(x: x, y: y))
        if primary > 0.46 {
          drawingFoam
            ? foam.addLine(to: CGPoint(x: x, y: y))
            : foam.move(to: CGPoint(x: x, y: y))
          drawingFoam = true
        } else {
          drawingFoam = false
        }
      }

      var body = wave
      body.addLine(to: CGPoint(x: tideRect.maxX, y: tideRect.maxY))
      body.addLine(to: CGPoint(x: tideRect.minX, y: tideRect.maxY))
      body.closeSubpath()
      sealedTide.fill(
        body,
        with: .linearGradient(
          Gradient(colors: [
            Color.white.opacity((0.055 - Double(band) * 0.008) * power),
            element.color.opacity((0.11 + Double(band) * 0.028) * power),
            Color(red: 0.015, green: 0.08, blue: 0.19).opacity(0.38),
          ]),
          startPoint: CGPoint(x: tideCenter.x, y: baseline - amplitude),
          endPoint: CGPoint(x: tideCenter.x, y: tideRect.maxY)
        )
      )

      var glow = sealedTide
      glow.addFilter(.blur(radius: 5 + CGFloat(band) * 1.4))
      glow.stroke(
        wave,
        with: .color(element.color.opacity((0.1 + Double(band) * 0.02) * power)),
        lineWidth: 7 + CGFloat(band) * 1.8
      )
      sealedTide.stroke(
        wave,
        with: .color(Color.white.opacity((0.32 - Double(band) * 0.04) * power)),
        style: StrokeStyle(
          lineWidth: 1.45 - CGFloat(band) * 0.16,
          lineCap: .round,
          lineJoin: .round
        )
      )
      var foamGlow = sealedTide
      foamGlow.addFilter(.blur(radius: 4 + CGFloat(band)))
      foamGlow.stroke(
        foam,
        with: .color(Color.white.opacity((0.16 + Double(band) * 0.018) * power)),
        style: StrokeStyle(lineWidth: 6 + CGFloat(band), lineCap: .round)
      )
      sealedTide.stroke(
        foam,
        with: .color(Color.white.opacity((0.48 - Double(band) * 0.05) * power)),
        style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round)
      )
    }

    for band in 0..<3 {
      let baseline = size.height * (0.76 + CGFloat(band) * 0.075)
      let amplitude = size.height * (0.014 + CGFloat(band) * 0.004)
      var ambientWave = Path()
      for point in 0...100 {
        let fraction = CGFloat(point) / 100
        let phase =
          Double(fraction) * .pi * (2.2 + Double(band) * 0.34)
          - time * (0.62 + Double(band) * 0.11)
        let y = baseline + CGFloat(sin(phase)) * amplitude
        let point = CGPoint(x: size.width * fraction, y: y)
        point.x == 0 ? ambientWave.move(to: point) : ambientWave.addLine(to: point)
      }
      context.stroke(
        ambientWave,
        with: .color(element.color.opacity((0.07 + Double(band) * 0.02) * power)),
        style: StrokeStyle(lineWidth: 0.75 + CGFloat(band) * 0.3, lineCap: .round)
      )
    }

    context.stroke(
      tideSeal,
      with: .color(element.color.opacity(0.25 * power)),
      style: StrokeStyle(lineWidth: 1.25, dash: [11, 6, 2, 6])
    )
    context.stroke(
      Path(ellipseIn: tideRect.insetBy(dx: tideRadius * 0.11, dy: tideRadius * 0.11)),
      with: .color(Color.white.opacity(0.1 * power)),
      lineWidth: 0.65
    )

    for index in 0..<10 {
      let angle = Double(index) * 2 * .pi / 10 - .pi / 2
      var connector = Path()
      connector.move(
        to: CGPoint(
          x: tideCenter.x + cos(angle) * tideRadius * 0.3,
          y: tideCenter.y + sin(angle) * tideRadius * 0.3
        )
      )
      connector.addLine(
        to: CGPoint(
          x: tideCenter.x + cos(angle) * tideRadius,
          y: tideCenter.y + sin(angle) * tideRadius
        )
      )
      context.stroke(
        connector,
        with: .color(element.color.opacity((0.08 + Double(index % 3) * 0.025) * power)),
        style: StrokeStyle(lineWidth: index.isMultiple(of: 2) ? 0.9 : 0.45, dash: [5, 7])
      )
    }

    for index in 0..<18 {
      let seed = Double(index + 1)
      let x =
        tideRect.minX + tideRect.width
        * CGFloat(
          abs(sin(seed * 27.17)).truncatingRemainder(dividingBy: 1)
        )
      let y =
        tideCenter.y + tideRadius
        * CGFloat(
          0.16 + seed.truncatingRemainder(dividingBy: 5) * 0.105
        )
      let ripplePhase =
        (time * (0.7 + seed.truncatingRemainder(dividingBy: 3) * 0.12)
        + seed * 0.23).truncatingRemainder(dividingBy: 1)
      let radius = CGFloat(5 + ripplePhase * (24 + seed.truncatingRemainder(dividingBy: 17)))
      let rippleRect = CGRect(
        x: x - radius,
        y: y - radius * 0.18,
        width: radius * 2,
        height: radius * 0.36
      )
      context.stroke(
        Path(ellipseIn: rippleRect),
        with: .color(element.color.opacity((1 - ripplePhase) * 0.34 * power)),
        lineWidth: 0.75
      )
    }
  }

  private func leafPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
    let halfLength = length / 2
    let halfWidth = length * 0.24
    let top = rotatedPoint(x: 0, y: -halfLength, around: center, angle: angle)
    let bottom = rotatedPoint(x: 0, y: halfLength, around: center, angle: angle)
    let right = rotatedPoint(x: halfWidth, y: 0, around: center, angle: angle)
    let left = rotatedPoint(x: -halfWidth, y: 0, around: center, angle: angle)

    return Path { path in
      path.move(to: top)
      path.addQuadCurve(to: bottom, control: right)
      path.addQuadCurve(to: top, control: left)
      path.move(to: top)
      path.addLine(to: bottom)
    }
  }

  private func fireBackdropFlamePath(
    base: CGPoint,
    width: CGFloat,
    height: CGFloat,
    phase: Double
  ) -> Path {
    let drift = CGFloat(sin(phase)) * width * 0.34
    let shoulder = CGFloat(cos(phase * 0.71)) * width * 0.14
    return Path { path in
      path.move(to: CGPoint(x: base.x - width / 2, y: base.y))
      path.addCurve(
        to: CGPoint(x: base.x - width * 0.18 + shoulder, y: base.y - height * 0.46),
        control1: CGPoint(x: base.x - width * 0.64, y: base.y - height * 0.16),
        control2: CGPoint(x: base.x - width * 0.42, y: base.y - height * 0.38)
      )
      path.addCurve(
        to: CGPoint(x: base.x + drift, y: base.y - height),
        control1: CGPoint(x: base.x - width * 0.06, y: base.y - height * 0.68),
        control2: CGPoint(x: base.x + drift - width * 0.2, y: base.y - height * 0.88)
      )
      path.addCurve(
        to: CGPoint(x: base.x + width * 0.2 - shoulder, y: base.y - height * 0.38),
        control1: CGPoint(x: base.x + drift + width * 0.24, y: base.y - height * 0.82),
        control2: CGPoint(x: base.x + width * 0.36, y: base.y - height * 0.58)
      )
      path.addCurve(
        to: CGPoint(x: base.x + width / 2, y: base.y),
        control1: CGPoint(x: base.x + width * 0.48, y: base.y - height * 0.24),
        control2: CGPoint(x: base.x + width * 0.64, y: base.y - height * 0.12)
      )
      path.closeSubpath()
    }
  }

  private func fireSpiritBackdropPath(
    center: CGPoint,
    scale: CGFloat,
    phase: Double
  ) -> Path {
    let drift = CGFloat(sin(phase)) * scale * 0.012
    return Path { path in
      path.move(to: CGPoint(x: center.x - scale * 0.32, y: center.y + scale * 0.32))
      path.addCurve(
        to: CGPoint(x: center.x - scale * 0.27, y: center.y - scale * 0.08),
        control1: CGPoint(x: center.x - scale * 0.5, y: center.y + scale * 0.22),
        control2: CGPoint(x: center.x - scale * 0.48, y: center.y - scale * 0.18)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.12 + drift, y: center.y + scale * 0.08),
        control1: CGPoint(x: center.x - scale * 0.08, y: center.y - scale * 0.32),
        control2: CGPoint(x: center.x + scale * 0.36, y: center.y - scale * 0.2)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.04, y: center.y - scale * 0.23),
        control1: CGPoint(x: center.x - scale * 0.06, y: center.y + scale * 0.26),
        control2: CGPoint(x: center.x + scale * 0.38, y: center.y + scale * 0.05)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.23 + drift, y: center.y - scale * 0.26),
        control1: CGPoint(x: center.x - scale * 0.04, y: center.y - scale * 0.39),
        control2: CGPoint(x: center.x + scale * 0.14, y: center.y - scale * 0.4)
      )
    }
  }

  private func fireSpiritBackdropSpines(
    center: CGPoint,
    scale: CGFloat,
    phase: Double
  ) -> Path {
    let flicker = CGFloat(sin(phase * 1.7)) * scale * 0.01
    let fins = [
      (-0.36, 0.24, -0.08, -0.08),
      (-0.39, 0.08, -0.08, -0.06),
      (-0.29, -0.11, -0.03, -0.1),
      (-0.12, -0.18, 0.01, -0.11),
      (0.1, -0.1, 0.08, -0.07),
      (0.16, 0.02, 0.09, -0.045),
      (0.03, -0.26, -0.01, -0.11),
    ]
    return Path { path in
      for fin in fins {
        path.move(
          to: CGPoint(
            x: center.x + scale * fin.0,
            y: center.y + scale * fin.1
          )
        )
        path.addLine(
          to: CGPoint(
            x: center.x + scale * (fin.0 + fin.2) + flicker,
            y: center.y + scale * (fin.1 + fin.3)
          )
        )
      }

      path.move(to: CGPoint(x: center.x - scale * 0.32, y: center.y + scale * 0.32))
      path.addCurve(
        to: CGPoint(x: center.x - scale * 0.5, y: center.y + scale * 0.42),
        control1: CGPoint(x: center.x - scale * 0.39, y: center.y + scale * 0.28),
        control2: CGPoint(x: center.x - scale * 0.47, y: center.y + scale * 0.34)
      )
      path.move(to: CGPoint(x: center.x - scale * 0.31, y: center.y + scale * 0.32))
      path.addCurve(
        to: CGPoint(x: center.x - scale * 0.4, y: center.y + scale * 0.5),
        control1: CGPoint(x: center.x - scale * 0.28, y: center.y + scale * 0.39),
        control2: CGPoint(x: center.x - scale * 0.34, y: center.y + scale * 0.46)
      )
    }
  }

  private func fireSpiritBackdropHead(center: CGPoint, scale: CGFloat) -> Path {
    let points = [
      CGPoint(x: -0.52, y: 0.18),
      CGPoint(x: -0.25, y: -0.05),
      CGPoint(x: 0.0, y: -0.14),
      CGPoint(x: 0.3, y: -0.12),
      CGPoint(x: 0.54, y: 0.0),
      CGPoint(x: 0.4, y: 0.1),
      CGPoint(x: 0.58, y: 0.24),
      CGPoint(x: 0.18, y: 0.18),
      CGPoint(x: 0.02, y: 0.42),
      CGPoint(x: -0.16, y: 0.2),
    ].map { point in
      CGPoint(x: center.x + point.x * scale, y: center.y + point.y * scale)
    }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() {
        path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func fireSpiritBackdropHeadDetails(center: CGPoint, scale: CGFloat) -> Path {
    Path { path in
      path.move(
        to: CGPoint(x: center.x - scale * 0.04, y: center.y - scale * 0.05)
      )
      path.addLine(
        to: CGPoint(x: center.x + scale * 0.22, y: center.y - scale * 0.02)
      )
      path.addLine(
        to: CGPoint(x: center.x + scale * 0.1, y: center.y + scale * 0.07)
      )

      path.move(
        to: CGPoint(x: center.x + scale * 0.18, y: center.y + scale * 0.2)
      )
      path.addCurve(
        to: CGPoint(x: center.x + scale * 0.58, y: center.y + scale * 0.14),
        control1: CGPoint(x: center.x + scale * 0.34, y: center.y + scale * 0.25),
        control2: CGPoint(x: center.x + scale * 0.47, y: center.y + scale * 0.15)
      )

      path.move(
        to: CGPoint(x: center.x - scale * 0.22, y: center.y - scale * 0.08)
      )
      path.addLine(
        to: CGPoint(x: center.x - scale * 0.34, y: center.y - scale * 0.46)
      )
      path.move(
        to: CGPoint(x: center.x + scale * 0.02, y: center.y - scale * 0.1)
      )
      path.addLine(
        to: CGPoint(x: center.x + scale * 0.14, y: center.y - scale * 0.5)
      )
    }
  }

  private func snowCrystalPath(
    center: CGPoint,
    radius: CGFloat,
    rotation: Double
  ) -> Path {
    Path { path in
      for arm in 0..<3 {
        let angle = rotation + Double(arm) * .pi / 3
        path.move(
          to: CGPoint(x: center.x - cos(angle) * radius, y: center.y - sin(angle) * radius)
        )
        path.addLine(
          to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        )
      }
    }
  }

  private func leafVeinPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
    Path { path in
      let top = rotatedPoint(x: 0, y: -length * 0.38, around: center, angle: angle)
      let bottom = rotatedPoint(x: 0, y: length * 0.4, around: center, angle: angle)
      path.move(to: top)
      path.addLine(to: bottom)

      for index in 0..<3 {
        let y = -length * 0.18 + CGFloat(index) * length * 0.19
        let reach = length * (0.18 - CGFloat(index) * 0.025)
        let node = rotatedPoint(x: 0, y: y, around: center, angle: angle)
        path.move(to: node)
        path.addLine(
          to: rotatedPoint(x: -reach, y: y - length * 0.1, around: center, angle: angle)
        )
        path.move(to: node)
        path.addLine(
          to: rotatedPoint(x: reach, y: y - length * 0.07, around: center, angle: angle)
        )
      }
    }
  }

  private func bronzeRelicPath(
    center: CGPoint,
    scale: CGFloat,
    angle: Double,
    kind: Int
  ) -> Path {
    let point: (CGFloat, CGFloat) -> CGPoint = { x, y in
      rotatedPoint(x: x * scale, y: y * scale, around: center, angle: angle)
    }

    return Path { path in
      switch kind {
      case 0:  // Long spear with a diamond blade and tassel.
        path.move(to: point(0, 0.92))
        path.addLine(to: point(0, -0.55))
        path.move(to: point(0, -1.02))
        path.addLine(to: point(0.18, -0.69))
        path.addLine(to: point(0, -0.48))
        path.addLine(to: point(-0.18, -0.69))
        path.closeSubpath()
        path.move(to: point(-0.05, -0.49))
        path.addCurve(
          to: point(-0.28, -0.17),
          control1: point(-0.22, -0.39),
          control2: point(-0.31, -0.29)
        )
        path.move(to: point(0.05, -0.49))
        path.addCurve(
          to: point(0.28, -0.17),
          control1: point(0.22, -0.39),
          control2: point(0.31, -0.29)
        )

      case 1:  // Crescent halberd.
        path.move(to: point(0, 0.94))
        path.addLine(to: point(0, -0.88))
        path.move(to: point(0, -1.05))
        path.addLine(to: point(0.13, -0.79))
        path.addLine(to: point(0, -0.6))
        path.addLine(to: point(-0.13, -0.79))
        path.closeSubpath()
        path.move(to: point(0.01, -0.63))
        path.addCurve(
          to: point(0.5, -0.31),
          control1: point(0.35, -0.64),
          control2: point(0.51, -0.53)
        )
        path.addCurve(
          to: point(0.08, -0.39),
          control1: point(0.34, -0.32),
          control2: point(0.2, -0.34)
        )

      case 2:  // Layered shield with a raised boss.
        let outline = [
          point(0, -0.92), point(0.61, -0.58), point(0.54, 0.3),
          point(0, 0.92), point(-0.54, 0.3), point(-0.61, -0.58),
        ]
        path.move(to: outline[0])
        for outlinePoint in outline.dropFirst() { path.addLine(to: outlinePoint) }
        path.closeSubpath()
        path.move(to: point(0, -0.62))
        path.addLine(to: point(0.35, -0.34))
        path.addLine(to: point(0.27, 0.2))
        path.addLine(to: point(0, 0.55))
        path.addLine(to: point(-0.27, 0.2))
        path.addLine(to: point(-0.35, -0.34))
        path.closeSubpath()
        path.move(to: point(-0.16, 0))
        path.addLine(to: point(0.16, 0))
        path.move(to: point(0, -0.16))
        path.addLine(to: point(0, 0.16))

      case 3:  // Ceremonial lamellar armor.
        path.move(to: point(-0.26, -0.86))
        path.addLine(to: point(-0.69, -0.55))
        path.addLine(to: point(-0.49, -0.2))
        path.addLine(to: point(-0.36, -0.31))
        path.addLine(to: point(-0.31, 0.42))
        path.addLine(to: point(-0.52, 0.86))
        path.addLine(to: point(0, 0.7))
        path.addLine(to: point(0.52, 0.86))
        path.addLine(to: point(0.31, 0.42))
        path.addLine(to: point(0.36, -0.31))
        path.addLine(to: point(0.49, -0.2))
        path.addLine(to: point(0.69, -0.55))
        path.addLine(to: point(0.26, -0.86))
        path.addCurve(
          to: point(-0.26, -0.86),
          control1: point(0.13, -0.64),
          control2: point(-0.13, -0.64)
        )
        path.move(to: point(-0.31, -0.3))
        path.addLine(to: point(0.31, -0.3))
        path.move(to: point(-0.3, 0.02))
        path.addLine(to: point(0.3, 0.02))
        path.move(to: point(-0.3, 0.34))
        path.addLine(to: point(0.3, 0.34))
        path.move(to: point(0, -0.61))
        path.addLine(to: point(0, 0.65))

      case 4:  // Three-legged bronze ding with handles and a taotie motif.
        path.move(to: point(-0.62, -0.45))
        path.addLine(to: point(0.62, -0.45))
        path.addLine(to: point(0.45, 0.35))
        path.addCurve(
          to: point(-0.45, 0.35),
          control1: point(0.24, 0.58),
          control2: point(-0.24, 0.58)
        )
        path.closeSubpath()
        path.move(to: point(-0.42, -0.46))
        path.addCurve(
          to: point(-0.72, -0.25),
          control1: point(-0.76, -0.65),
          control2: point(-0.82, -0.35)
        )
        path.move(to: point(0.42, -0.46))
        path.addCurve(
          to: point(0.72, -0.25),
          control1: point(0.76, -0.65),
          control2: point(0.82, -0.35)
        )
        path.move(to: point(-0.28, 0.34))
        path.addLine(to: point(-0.4, 0.91))
        path.move(to: point(0, 0.41))
        path.addLine(to: point(0, 0.96))
        path.move(to: point(0.28, 0.34))
        path.addLine(to: point(0.4, 0.91))
        path.move(to: point(-0.32, -0.05))
        path.addLine(to: point(-0.14, -0.19))
        path.addLine(to: point(0, -0.04))
        path.addLine(to: point(0.14, -0.19))
        path.addLine(to: point(0.32, -0.05))
        path.move(to: point(-0.24, 0.13))
        path.addLine(to: point(0.24, 0.13))

      default:  // Ritual bronze bell.
        path.move(to: point(-0.18, -0.92))
        path.addCurve(
          to: point(0.18, -0.92),
          control1: point(-0.17, -1.17),
          control2: point(0.17, -1.17)
        )
        path.move(to: point(-0.18, -0.91))
        path.addLine(to: point(-0.42, 0.58))
        path.addLine(to: point(-0.61, 0.8))
        path.addLine(to: point(0.61, 0.8))
        path.addLine(to: point(0.42, 0.58))
        path.addLine(to: point(0.18, -0.91))
        path.closeSubpath()
        path.move(to: point(-0.31, -0.35))
        path.addLine(to: point(0.31, -0.35))
        path.move(to: point(-0.38, 0.1))
        path.addLine(to: point(0.38, 0.1))
        path.move(to: point(-0.44, 0.52))
        path.addLine(to: point(0.44, 0.52))
        path.move(to: point(0, 0.8))
        path.addLine(to: point(0, 1.02))
      }
    }
  }

  private func spiritSwordPath(
    center: CGPoint,
    length: CGFloat,
    width: CGFloat,
    angle: Double
  ) -> Path {
    let points = [
      CGPoint(x: 0, y: -length * 0.5),
      CGPoint(x: width * 0.34, y: length * 0.14),
      CGPoint(x: width * 0.17, y: length * 0.25),
      CGPoint(x: width * 0.82, y: length * 0.28),
      CGPoint(x: width * 0.19, y: length * 0.34),
      CGPoint(x: width * 0.13, y: length * 0.47),
      CGPoint(x: 0, y: length * 0.5),
      CGPoint(x: -width * 0.13, y: length * 0.47),
      CGPoint(x: -width * 0.19, y: length * 0.34),
      CGPoint(x: -width * 0.82, y: length * 0.28),
      CGPoint(x: -width * 0.17, y: length * 0.25),
      CGPoint(x: -width * 0.34, y: length * 0.14),
    ].map { point in
      rotatedPoint(x: point.x, y: point.y, around: center, angle: angle)
    }

    return Path { path in
      guard let first = points.first else { return }
      path.move(to: first)
      for point in points.dropFirst() {
        path.addLine(to: point)
      }
      path.closeSubpath()
    }
  }

  private func spiritSwordDetailPath(
    center: CGPoint,
    length: CGFloat,
    width: CGFloat,
    angle: Double
  ) -> Path {
    Path { path in
      path.move(
        to: rotatedPoint(x: 0, y: -length * 0.45, around: center, angle: angle)
      )
      path.addLine(
        to: rotatedPoint(x: 0, y: length * 0.24, around: center, angle: angle)
      )
      path.move(
        to: rotatedPoint(x: -width * 0.56, y: length * 0.29, around: center, angle: angle)
      )
      path.addLine(
        to: rotatedPoint(x: width * 0.56, y: length * 0.29, around: center, angle: angle)
      )
      path.move(
        to: rotatedPoint(x: 0, y: length * 0.35, around: center, angle: angle)
      )
      path.addLine(
        to: rotatedPoint(x: 0, y: length * 0.46, around: center, angle: angle)
      )
    }
  }

  private func rotatedPoint(
    x: CGFloat,
    y: CGFloat,
    around center: CGPoint,
    angle: Double
  ) -> CGPoint {
    CGPoint(
      x: center.x + x * cos(angle) - y * sin(angle),
      y: center.y + x * sin(angle) + y * cos(angle)
    )
  }
}
