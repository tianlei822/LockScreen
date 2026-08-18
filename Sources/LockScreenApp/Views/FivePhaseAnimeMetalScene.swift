import SwiftUI

extension ElementalAnimeScene {
  func drawMetal(
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

  func bronzeRelicPath(
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

  func spiritSwordPath(
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

  func spiritSwordDetailPath(
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

}
