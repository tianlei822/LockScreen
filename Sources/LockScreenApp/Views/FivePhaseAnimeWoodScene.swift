import SwiftUI

extension ElementalAnimeScene {
  func drawWood(
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

  func leafPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
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
  func leafVeinPath(center: CGPoint, length: CGFloat, angle: Double) -> Path {
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

  func rotatedPoint(
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
