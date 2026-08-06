import LockScreenCore
import SwiftUI

struct FormationTraceView: View {
  let trajectory: FormationTrajectory
  let energy: Double
  let onSelectTrajectory: (FormationTrajectory) -> Void
  let onTrace: (Double) -> Void

  var body: some View {
    GeometryReader { proxy in
      let canvasWidth = min(620, proxy.size.width * 0.62)
      let canvasHeight = min(440, proxy.size.height * 0.62)

      ZStack {
        FormationTraceCanvas(
          trajectory: trajectory,
          energy: energy,
          onTrace: onTrace
        )
        .frame(width: canvasWidth, height: canvasHeight)
        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.43)

        VStack(spacing: 14) {
          Spacer()

          energyMeter

          HStack(spacing: 6) {
            ForEach(FormationTrajectory.allCases) { option in
              Button {
                onSelectTrajectory(option)
              } label: {
                HStack(spacing: 7) {
                  Text(option.symbol)
                    .font(.system(size: 18, weight: .light))
                  Text(option.title.uppercased())
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(1.4)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(option == trajectory ? Color.cyan.opacity(0.14) : .clear)
                .overlay(alignment: .bottom) {
                  Rectangle()
                    .fill(option == trajectory ? Color.cyan.opacity(0.9) : .clear)
                    .frame(height: 1)
                }
              }
              .buttonStyle(.plain)
              .foregroundStyle(option == trajectory ? Color.white : Color.white.opacity(0.58))
              .accessibilityLabel("Use (option.title) formation trajectory")
            }

            Divider()
              .frame(height: 24)
              .overlay(Color.cyan.opacity(0.24))
              .padding(.horizontal, 4)

            Button {
              onTrace(1)
            } label: {
              Label("Channel", systemImage: "return")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(1.2)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.cyan.opacity(0.72))
            .keyboardShortcut(.return, modifiers: [])
            .accessibilityLabel("Channel the selected formation without dragging")
            .help("Keyboard alternative: press Return")
          }
        }
        .padding(.bottom, 4)
      }
    }
  }

  private var energyMeter: some View {
    VStack(spacing: 7) {
      HStack {
        Text("AETHER CHARGE")
        Spacer()
        Text(energy >= 1 ? "ACTIVATED" : "\(Int(energy * 100))%")
      }
      .font(.system(size: 9, weight: .semibold, design: .monospaced))
      .tracking(1.8)
      .foregroundStyle(Color.cyan.opacity(0.78))

      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(Color.cyan.opacity(0.08))
          Capsule()
            .fill(
              LinearGradient(
                colors: [Color.cyan.opacity(0.52), Color(red: 0.58, green: 1, blue: 0.74)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: proxy.size.width * energy)
            .shadow(color: Color.cyan.opacity(energy), radius: 8)
        }
      }
      .frame(height: 4)
    }
    .frame(width: 390)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Aether charge (Int(energy * 100)) percent")
  }
}

private struct FormationTraceCanvas: View {
  let trajectory: FormationTrajectory
  let energy: Double
  let onTrace: (Double) -> Void

  @State private var points: [NormalizedPoint] = []
  @State private var feedback = "TRACE THE GLYPH"
  @State private var traceID = 0

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let template = FormationTrajectoryMatcher.template(for: trajectory)

      ZStack {
        trajectoryPath(template, in: size)
          .stroke(Color.cyan.opacity(0.12), lineWidth: 18)
          .blur(radius: 9)

        trajectoryPath(template, in: size)
          .stroke(
            Color.cyan.opacity(0.48),
            style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [4, 9])
          )

        trajectoryPath(template, in: size)
          .trim(from: 0, to: min(0.98, CGFloat(energy)))
          .stroke(
            LinearGradient(
              colors: [.cyan, Color(red: 0.66, green: 1, blue: 0.74)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
          )
          .shadow(color: .cyan.opacity(0.8), radius: 8)

        if !points.isEmpty {
          trajectoryPath(points, in: size)
            .stroke(
              LinearGradient(colors: [.white, .cyan], startPoint: .leading, endPoint: .trailing),
              style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: .cyan, radius: 8)
        }

        VStack {
          Spacer()
          Text(feedback)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(2.6)
            .foregroundStyle(Color.cyan.opacity(0.72))
            .padding(.bottom, 6)
        }
      }
      .contentShape(Rectangle())
      .gesture(traceGesture(in: size))
      .accessibilityLabel("Trace the (trajectory.title) formation path")
      .accessibilityHint("Drag along the glowing guide, or press Return to channel it")
      .onChange(of: trajectory) {
        points.removeAll()
        feedback = "TRACE THE GLYPH"
      }
    }
  }

  private func traceGesture(in size: CGSize) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        let point = normalized(value.location, in: size)
        guard let previous = points.last else {
          points = [point]
          feedback = "CHANNELING"
          return
        }

        guard hypot(point.x - previous.x, point.y - previous.y) > 0.006 else { return }
        points.append(point)
      }
      .onEnded { value in
        points.append(normalized(value.location, in: size))
        let score = FormationTrajectoryMatcher.score(points, for: trajectory)
        feedback =
          score >= 0.72
          ? "RESONANCE COMPLETE" : score >= 0.35 ? "RESONANCE PARTIAL" : "GLYPH REJECTED"
        onTrace(score)

        traceID += 1
        let currentTraceID = traceID
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(620))
          guard currentTraceID == traceID else { return }
          withAnimation(.easeOut(duration: 0.24)) {
            points.removeAll()
          }
        }
      }
  }

  private func normalized(_ point: CGPoint, in size: CGSize) -> NormalizedPoint {
    NormalizedPoint(
      x: max(0, min(1, point.x / size.width)),
      y: max(0, min(1, point.y / size.height))
    )
  }

  private func trajectoryPath(_ pathPoints: [NormalizedPoint], in size: CGSize) -> Path {
    var path = Path()
    guard let first = pathPoints.first else { return path }

    path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
    for point in pathPoints.dropFirst() {
      path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
    }
    return path
  }
}
