import LockScreenCore
import SwiftUI

struct FormationTraceView: View {
  let trajectory: FormationTrajectory
  let energy: Double
  let showsControls: Bool
  let onSelectTrajectory: (FormationTrajectory) -> Void
  let onTrace: (Double) -> Void

  var body: some View {
    let style = trajectory.visualStyle

    GeometryReader { proxy in
      let canvasWidth = min(620, proxy.size.width * 0.62)
      let canvasHeight = min(440, proxy.size.height * 0.62)
      let meterWidth = min(390, max(260, proxy.size.width - 64))

      ZStack {
        FormationTraceCanvas(
          trajectory: trajectory,
          energy: energy,
          onTrace: onTrace
        )
        .frame(width: canvasWidth, height: canvasHeight)
        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

        VStack(spacing: 14) {
          Spacer()

          VStack(spacing: 14) {
            energyMeter(width: meterWidth)

            HStack(spacing: 6) {
              ForEach(FormationTrajectory.allCases) { option in
                Button {
                  onSelectTrajectory(option)
                } label: {
                  HStack(spacing: 7) {
                    Text(option.symbol)
                      .font(.system(size: 18, weight: .light))
                    Text(option.title)
                      .font(.system(size: 9, weight: .semibold, design: .monospaced))
                      .tracking(1.4)
                  }
                  .padding(.horizontal, 13)
                  .padding(.vertical, 9)
                  .background(option == trajectory ? style.primary.opacity(0.14) : .clear)
                  .overlay(alignment: .bottom) {
                    Rectangle()
                      .fill(option == trajectory ? style.primary.opacity(0.9) : .clear)
                      .frame(height: 1)
                  }
                }
                .buttonStyle(.plain)
                .foregroundStyle(option == trajectory ? Color.white : Color.white.opacity(0.58))
                .accessibilityLabel(L10n.format("Use %@ formation", option.title))
              }

              Divider()
                .frame(height: 24)
                .overlay(style.primary.opacity(0.24))
                .padding(.horizontal, 4)

              Button {
                onTrace(1)
              } label: {
                Label(L10n.text("Channel"), systemImage: "return")
                  .font(.system(size: 9, weight: .semibold, design: .monospaced))
                  .tracking(1.2)
                  .padding(.horizontal, 12)
                  .padding(.vertical, 9)
              }
              .buttonStyle(.plain)
              .foregroundStyle(style.primary.opacity(0.72))
              .keyboardShortcut(.return, modifiers: [])
              .accessibilityLabel(
                L10n.text("Channel the selected formation without dragging")
              )
              .help(L10n.text("Keyboard alternative: press Return"))
            }
          }
          .opacity(showsControls ? 1 : 0)
          .offset(y: showsControls ? 0 : 10)
          .allowsHitTesting(showsControls)
          .animation(.easeInOut(duration: 0.58), value: showsControls)
        }
        .padding(.bottom, 4)
      }
    }
  }

  private func energyMeter(width: CGFloat) -> some View {
    let style = trajectory.visualStyle

    return VStack(spacing: 7) {
      HStack {
        Text(trajectory.invocation)
        Spacer()
        Text(energy >= 1 ? L10n.text("ACTIVATED") : "\(Int(energy * 100))%")
      }
      .font(.system(size: 9, weight: .semibold, design: .monospaced))
      .tracking(1.8)
      .foregroundStyle(style.primary.opacity(0.78))

      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(style.primary.opacity(0.08))
          Capsule()
            .fill(
              LinearGradient(
                colors: [style.primary.opacity(0.52), style.secondary],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .frame(width: proxy.size.width * energy)
            .shadow(color: style.primary.opacity(energy), radius: 8)
        }
      }
      .frame(height: 4)
    }
    .frame(width: width)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(
      L10n.format("%@ charge %lld percent", trajectory.title, Int(energy * 100))
    )
  }
}

private struct FormationTraceCanvas: View {
  let trajectory: FormationTrajectory
  let energy: Double
  let onTrace: (Double) -> Void
  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced

  init(
    trajectory: FormationTrajectory,
    energy: Double,
    onTrace: @escaping (Double) -> Void
  ) {
    self.trajectory = trajectory
    self.energy = energy
    self.onTrace = onTrace
    _trace = State(initialValue: FormationTraceAccumulator(trajectory: trajectory))
  }

  private enum TraceOutcome {
    case complete
    case partial
    case rejected
  }

  private let amber = Color(red: 1.0, green: 0.62, blue: 0.32)

  @State private var trace: FormationTraceAccumulator
  @State private var traceID = 0
  @State private var isDragging = false
  @State private var outcome: TraceOutcome?
  @State private var outcomeTime: TimeInterval?

  var body: some View {
    TimelineView(
      .animation(
        minimumInterval: trajectory == .circle ? 1 / 18 : 1 / 20,
        paused: RitualMotionPolicy.pausesVisualEffects(
          renderingPaused: ritualAnimationsPaused,
          reduceMotion: ritualMotionReduced
        )
      )
    ) { timeline in
      GeometryReader { proxy in
        let size = proxy.size
        let time = timeline.date.timeIntervalSinceReferenceDate
        let template = FormationTrajectoryMatcher.template(for: trajectory)
        let breath = 0.5 + 0.5 * sin(time * 1.8)
        let outcomeAge = outcomeTime.map { time - $0 }
        let style = guideStyle(at: time)
        let displayedCharge = max(energy, trace.completion)

        ZStack {
          chargingHalo(
            charge: displayedCharge,
            isChanneling: isDragging,
            size: size,
            time: time,
            style: style
          )

          trajectoryPath(template, in: size)
            .stroke(
              style.primary.opacity(0.045 + breath * 0.035),
              style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round)
            )
            .blur(radius: 7)

          trajectoryPath(template, in: size)
            .stroke(
              style.primary.opacity(0.15 + breath * 0.1),
              style: StrokeStyle(
                lineWidth: 0.9 + breath * 0.45,
                lineCap: .round,
                lineJoin: .round
              )
            )
            .shadow(color: style.primary.opacity(0.24), radius: 4)

          trajectoryPath(template, in: size)
            .stroke(
              style.secondary.opacity(0.1 + breath * 0.09),
              style: StrokeStyle(lineWidth: 0.6, lineCap: .round, dash: [2, 7, 12, 7])
            )

          trajectoryPath(template, in: size)
            .trim(from: 0, to: min(0.98, CGFloat(displayedCharge)))
            .stroke(
              LinearGradient(
                colors: [style.primary, style.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: style.primary.opacity(0.72), radius: 7)

          guideSpark(template: template, size: size, time: time, style: style)

          if !trace.points.isEmpty {
            trajectoryPath(trace.points, in: size)
              .stroke(
                LinearGradient(
                  colors: [style.secondary, style.primary],
                  startPoint: .leading,
                  endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 3.6, lineCap: .round, lineJoin: .round)
              )
              .shadow(color: style.primary, radius: 8)
          }

          if isDragging, let head = trace.points.last {
            dragHead(point: head, size: size, time: time, style: style)
          }

          if let outcome, let outcomeAge, outcomeAge < 1 {
            outcomeFX(
              outcome: outcome,
              age: outcomeAge,
              size: size,
              template: template,
              style: style
            )
          }

        }
        .contentShape(Rectangle())
        .gesture(traceGesture(in: size))
        .accessibilityLabel(
          L10n.format("Trace the %@ formation path", trajectory.title)
        )
        .accessibilityHint(
          L10n.text("Drag along the glowing guide, or press Return to channel it")
        )
        .onChange(of: trajectory) {
          trace = FormationTraceAccumulator(trajectory: trajectory)
          outcome = nil
          outcomeTime = nil
        }
      }
    }
  }

  /// Formation-wide charge feedback that fills continuously while the pointer follows the guide.
  private func chargingHalo(
    charge: Double,
    isChanneling: Bool,
    size: CGSize,
    time: TimeInterval,
    style: FormationVisualStyle
  ) -> some View {
    let diameter = min(size.width, size.height) * 0.95
    let pulse = 1 + sin(time * (isChanneling ? 5.4 : 1.8)) * (isChanneling ? 0.018 : 0.006)

    return ZStack {
      Circle()
        .stroke(
          style.primary.opacity(isChanneling ? 0.2 : 0.08),
          style: StrokeStyle(lineWidth: 1, dash: [2, 8])
        )
        .rotationEffect(.degrees(time * 12))

      Circle()
        .trim(from: 0, to: max(0.008, charge))
        .stroke(
          LinearGradient(
            colors: [style.primary, style.secondary, style.flare, style.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          style: StrokeStyle(lineWidth: isChanneling ? 5 : 3, lineCap: .round)
        )
        .rotationEffect(.degrees(-90))
        .shadow(color: style.primary.opacity(0.65 + charge * 0.3), radius: 7 + charge * 12)

      ForEach(0..<5, id: \.self) { index in
        let threshold = Double(index + 1) / 5
        Circle()
          .fill(charge >= threshold ? style.flare : style.primary.opacity(0.18))
          .frame(width: charge >= threshold ? 7 : 4, height: charge >= threshold ? 7 : 4)
          .shadow(color: style.primary, radius: charge >= threshold ? 8 : 0)
          .offset(y: -diameter / 2)
          .rotationEffect(.degrees(Double(index) * 72))
      }
    }
    .frame(width: diameter, height: diameter)
    .scaleEffect(pulse)
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

  /// A spark traveling along the template to show the tracing direction.
  private func guideSpark(
    template: [NormalizedPoint],
    size: CGSize,
    time: TimeInterval,
    style: FormationVisualStyle
  ) -> some View {
    let fraction = (time * 0.13).truncatingRemainder(dividingBy: 1)
    let position = point(at: fraction, in: template, size: size)
    let trailPosition = point(
      at: (fraction + 0.985).truncatingRemainder(dividingBy: 1), in: template, size: size)

    return ZStack {
      Circle()
        .fill(style.primary.opacity(0.45))
        .frame(width: 8, height: 8)
        .blur(radius: 4)
        .position(trailPosition)

      Circle()
        .fill(style.secondary)
        .frame(width: 3.8, height: 3.8)
        .shadow(color: style.primary, radius: 6)
        .position(position)
    }
    .blendMode(.plusLighter)
    .opacity(energy >= 1 ? 0 : 0.9)
    .allowsHitTesting(false)
  }

  /// Glowing comet head following the drag point.
  private func dragHead(
    point: NormalizedPoint,
    size: CGSize,
    time: TimeInterval,
    style: FormationVisualStyle
  ) -> some View {
    let position = canvasPoint(point, in: size)

    return ZStack {
      Circle()
        .stroke(style.primary.opacity(0.5), lineWidth: 1)
        .frame(width: 20 + sin(time * 6) * 4, height: 20 + sin(time * 6) * 4)
        .position(position)

      Circle()
        .fill(style.secondary)
        .frame(width: 8, height: 8)
        .blur(radius: 1.5)
        .shadow(color: style.primary, radius: 10)
        .position(position)
    }
    .blendMode(.plusLighter)
    .allowsHitTesting(false)
  }

  /// Success ripples or a rejection flicker after the gesture ends.
  private func outcomeFX(
    outcome: TraceOutcome,
    age: TimeInterval,
    size: CGSize,
    template: [NormalizedPoint],
    style: FormationVisualStyle
  ) -> some View {
    let maxDimension = min(size.width, size.height)

    return ZStack {
      switch outcome {
      case .complete:
        ForEach(0..<2, id: \.self) { wave in
          let progress = max(0, min(1, (age - Double(wave) * 0.13) / 0.8))
          if progress > 0, progress < 1 {
            Circle()
              .stroke(
                (wave == 0 ? Color.white : style.secondary).opacity(
                  pow(1 - progress, 1.3) * 0.8),
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
            .shadow(color: style.secondary, radius: 14)
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

  private func point(at fraction: Double, in template: [NormalizedPoint], size: CGSize) -> CGPoint {
    guard !template.isEmpty else { return .zero }
    let scaled = fraction * Double(template.count)
    let lower = Int(scaled) % template.count
    let upper = (lower + 1) % template.count
    let mix = scaled - floor(scaled)
    let a = template[lower]
    let b = template[upper]

    return canvasPoint(
      NormalizedPoint(
        x: a.x + (b.x - a.x) * mix,
        y: a.y + (b.y - a.y) * mix
      ),
      in: size
    )
  }

  private func traceGesture(in size: CGSize) -> some Gesture {
    DragGesture(minimumDistance: 0)
      .onChanged { value in
        isDragging = true
        let point = normalized(value.location, in: size)
        trace.append(point)
      }
      .onEnded { value in
        isDragging = false
        trace.append(normalized(value.location, in: size))
        let score = trace.score
        let activationThreshold = FormationTrajectoryMatcher.activationThreshold
        outcome = score >= activationThreshold ? .complete : score >= 0.35 ? .partial : .rejected
        outcomeTime = Date().timeIntervalSinceReferenceDate
        onTrace(score)

        traceID += 1
        let currentTraceID = traceID
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(620))
          guard currentTraceID == traceID else { return }
          withAnimation(.easeOut(duration: 0.24)) {
            trace.reset()
          }
        }
      }
  }

  private func normalized(_ point: CGPoint, in size: CGSize) -> NormalizedPoint {
    let bounds = formationBounds(in: size)
    return NormalizedPoint(
      x: max(0, min(1, (point.x - bounds.minX) / bounds.width)),
      y: max(0, min(1, (point.y - bounds.minY) / bounds.height))
    )
  }

  private func trajectoryPath(_ pathPoints: [NormalizedPoint], in size: CGSize) -> Path {
    var path = Path()
    guard let first = pathPoints.first else { return path }

    path.move(to: canvasPoint(first, in: size))
    for point in pathPoints.dropFirst() {
      path.addLine(to: canvasPoint(point, in: size))
    }
    return path
  }

  private func canvasPoint(_ point: NormalizedPoint, in size: CGSize) -> CGPoint {
    let bounds = formationBounds(in: size)
    return CGPoint(
      x: bounds.minX + point.x * bounds.width,
      y: bounds.minY + point.y * bounds.height
    )
  }

  private func formationBounds(in size: CGSize) -> CGRect {
    let dimension = min(size.width, size.height)
    return CGRect(
      x: (size.width - dimension) / 2,
      y: (size.height - dimension) / 2,
      width: dimension,
      height: dimension
    )
  }

  private func guideStyle(at time: TimeInterval) -> FormationVisualStyle {
    guard trajectory == .circle else { return trajectory.visualStyle }

    let cycle = FivePhaseCycleState(time: time)
    let activeElement =
      cycle.opacity(for: cycle.next) > cycle.opacity(for: cycle.current)
      ? cycle.next : cycle.current
    return FormationVisualStyle(
      primary: activeElement.color,
      secondary: activeElement.color.opacity(0.82),
      flare: activeElement.color
    )
  }
}
