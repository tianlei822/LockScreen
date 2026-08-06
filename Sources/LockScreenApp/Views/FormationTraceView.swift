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

  private enum TraceOutcome {
    case complete
    case partial
    case rejected
  }

  private let jade = Color(red: 0.66, green: 1, blue: 0.74)
  private let amber = Color(red: 1.0, green: 0.62, blue: 0.32)

  @State private var points: [NormalizedPoint] = []
  @State private var feedback = "TRACE THE GLYPH"
  @State private var traceID = 0
  @State private var isDragging = false
  @State private var outcome: TraceOutcome?
  @State private var outcomeTime: TimeInterval?

  var body: some View {
    TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
      GeometryReader { proxy in
        let size = proxy.size
        let time = timeline.date.timeIntervalSinceReferenceDate
        let template = FormationTrajectoryMatcher.template(for: trajectory)
        let breath = 0.5 + 0.5 * sin(time * 1.8)
        let outcomeAge = outcomeTime.map { time - $0 }

        ZStack {
          trajectoryPath(template, in: size)
            .stroke(Color.cyan.opacity(0.10 + breath * 0.05), lineWidth: 18)
            .blur(radius: 9)

          trajectoryPath(template, in: size)
            .stroke(
              Color.cyan.opacity(0.36 + breath * 0.16),
              style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [4, 9])
            )

          trajectoryPath(template, in: size)
            .trim(from: 0, to: min(0.98, CGFloat(energy)))
            .stroke(
              LinearGradient(
                colors: [.cyan, jade],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: .cyan.opacity(0.8), radius: 8)

          guideSpark(template: template, size: size, time: time)

          if !points.isEmpty {
            trajectoryPath(points, in: size)
              .stroke(
                LinearGradient(colors: [.white, .cyan], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
              )
              .shadow(color: .cyan, radius: 8)
          }

          if isDragging, let head = points.last {
            dragHead(point: head, size: size, time: time)
          }

          if let outcome, let outcomeAge, outcomeAge < 1 {
            outcomeFX(outcome: outcome, age: outcomeAge, size: size, template: template)
          }

          VStack {
            Spacer()
            Text(feedback)
              .font(.system(size: 9, weight: .medium, design: .monospaced))
              .tracking(2.6)
              .foregroundStyle(feedbackTint(outcomeAge: outcomeAge))
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
          outcome = nil
          outcomeTime = nil
        }
      }
    }
  }

  /// A spark traveling along the template to show the tracing direction.
  private func guideSpark(template: [NormalizedPoint], size: CGSize, time: TimeInterval)
    -> some View
  {
    let fraction = (time * 0.13).truncatingRemainder(dividingBy: 1)
    let position = point(at: fraction, in: template, size: size)
    let trailPosition = point(
      at: (fraction + 0.985).truncatingRemainder(dividingBy: 1), in: template, size: size)

    return ZStack {
      Circle()
        .fill(Color.cyan.opacity(0.45))
        .frame(width: 11, height: 11)
        .blur(radius: 4)
        .position(trailPosition)

      Circle()
        .fill(Color.white)
        .frame(width: 5.5, height: 5.5)
        .shadow(color: .cyan, radius: 8)
        .position(position)
    }
    .blendMode(.plusLighter)
    .opacity(energy >= 1 ? 0 : 0.9)
    .allowsHitTesting(false)
  }

  /// Glowing comet head following the drag point.
  private func dragHead(point: NormalizedPoint, size: CGSize, time: TimeInterval) -> some View {
    let position = CGPoint(x: point.x * size.width, y: point.y * size.height)

    return ZStack {
      Circle()
        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        .frame(width: 20 + sin(time * 6) * 4, height: 20 + sin(time * 6) * 4)
        .position(position)

      Circle()
        .fill(Color.white)
        .frame(width: 8, height: 8)
        .blur(radius: 1.5)
        .shadow(color: .cyan, radius: 10)
        .position(position)
    }
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

  /// Success ripples or a rejection flicker after the gesture ends.
  private func outcomeFX(
    outcome: TraceOutcome, age: TimeInterval, size: CGSize, template: [NormalizedPoint]
  ) -> some View {
    let maxDimension = max(size.width, size.height)

    return ZStack {
      switch outcome {
      case .complete:
        ForEach(0..<2, id: \.self) { wave in
          let progress = max(0, min(1, (age - Double(wave) * 0.13) / 0.8))
          if progress > 0, progress < 1 {
            Circle()
              .stroke(
                (wave == 0 ? Color.white : jade).opacity(pow(1 - progress, 1.3) * 0.8),
                lineWidth: (1 - progress) * 5 + 1
              )
              .frame(
                width: maxDimension * (0.1 + progress * 1.05),
                height: maxDimension * (0.1 + progress * 1.05)
              )
              .position(x: size.width / 2, y: size.height / 2)
          }
        }

        if age < 0.5 {
          trajectoryPath(template, in: size)
            .stroke(Color.white.opacity((1 - age * 2) * 0.75), lineWidth: 3.5)
            .shadow(color: jade, radius: 14)
        }
      case .partial:
        EmptyView()
      case .rejected:
        if age < 0.5 {
          trajectoryPath(template, in: size)
            .stroke(amber.opacity((1 - age * 2) * 0.55), lineWidth: 2.5)
        }
      }
    }
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

  private func feedbackTint(outcomeAge: TimeInterval?) -> Color {
    guard let outcome, let outcomeAge, outcomeAge < 1.2 else {
      return Color.cyan.opacity(0.72)
    }

    switch outcome {
    case .complete:
      return jade.opacity(0.95)
    case .partial:
      return Color.cyan.opacity(0.72)
    case .rejected:
      return amber.opacity(0.9)
    }
  }

  private func point(at fraction: Double, in template: [NormalizedPoint], size: CGSize) -> CGPoint {
    guard !template.isEmpty else { return .zero }
    let scaled = fraction * Double(template.count)
    let lower = Int(scaled) % template.count
    let upper = (lower + 1) % template.count
    let mix = scaled - floor(scaled)
    let a = template[lower]
    let b = template[upper]

    return CGPoint(
      x: (a.x + (b.x - a.x) * mix) * size.width,
      y: (a.y + (b.y - a.y) * mix) * size.height
    )
  }

  private func traceGesture(in size: CGSize) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        isDragging = true
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
        isDragging = false
        points.append(normalized(value.location, in: size))
        let score = FormationTrajectoryMatcher.score(points, for: trajectory)
        feedback =
          score >= 0.72
          ? "RESONANCE COMPLETE" : score >= 0.35 ? "RESONANCE PARTIAL" : "GLYPH REJECTED"
        outcome = score >= 0.72 ? .complete : score >= 0.35 ? .partial : .rejected
        outcomeTime = Date().timeIntervalSinceReferenceDate
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
