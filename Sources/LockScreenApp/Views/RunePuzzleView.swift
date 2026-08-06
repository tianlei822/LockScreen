import LockScreenCore
import SwiftUI

struct RunePuzzleView: View {
  let theme: DoorTheme
  let phase: LockPhase
  let sequence: [Rune]
  let progress: Int
  let lastMove: PuzzleMove?
  let onChooseRune: (Rune) -> Void
  let onReset: () -> Void

  var body: some View {
    let palette = theme.palette

    VStack(spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("TRACE THE SEAL")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(3)
          Text(statusText)
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(statusColor(palette: palette))
            .contentTransition(.numericText())
        }

        Spacer()

        targetSequence(palette: palette)

        Button(action: onReset) {
          Label("Reset", systemImage: "arrow.counterclockwise")
            .labelStyle(.iconOnly)
            .frame(width: 32, height: 28)
        }
        .buttonStyle(.plain)
        .foregroundStyle(palette.secondaryText)
        .keyboardShortcut("r", modifiers: [])
        .accessibilityLabel("Reset the door ritual")
        .help("Reset ritual (R)")
      }

      Rectangle()
        .fill(palette.accent.opacity(0.18))
        .frame(height: 1)

      HStack(spacing: 8) {
        ForEach(Rune.allCases) { rune in
          runeButton(rune, palette: palette)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .background(.black.opacity(0.48))
    .overlay(alignment: .top) {
      Rectangle()
        .fill(palette.accent)
        .frame(height: 1)
    }
    .frame(maxWidth: 900)
    .animation(.easeInOut(duration: 0.25), value: progress)
    .animation(.easeInOut(duration: 0.25), value: phase)
  }

  private func targetSequence(palette: ThemePalette) -> some View {
    HStack(spacing: 5) {
      ForEach(Array(sequence.enumerated()), id: \.offset) { index, rune in
        Text(rune.symbol)
          .font(.system(size: 13, weight: .medium, design: .monospaced))
          .foregroundStyle(index < progress ? palette.backdrop : palette.accent)
          .frame(width: 27, height: 27)
          .background(index < progress ? palette.accent : palette.accent.opacity(0.07))
          .overlay {
            Rectangle()
              .stroke(palette.accent.opacity(index == progress ? 0.9 : 0.28), lineWidth: 1)
          }
          .accessibilityLabel(
            "Step \(index + 1), \(rune.name), \(index < progress ? "complete" : "pending")")
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Required rune sequence")
  }

  private func runeButton(_ rune: Rune, palette: ThemePalette) -> some View {
    Button {
      onChooseRune(rune)
    } label: {
      HStack(spacing: 8) {
        Text(rune.symbol)
          .font(.system(size: 19, weight: .light, design: .monospaced))
        VStack(alignment: .leading, spacing: 1) {
          Text(rune.name.uppercased())
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(1)
          Text("KEY \(rune.keyboardNumber)")
            .font(.system(size: 7, weight: .medium, design: .monospaced))
            .foregroundStyle(palette.secondaryText)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 12)
      .frame(maxWidth: .infinity, minHeight: 44)
      .background(palette.accent.opacity(0.07))
      .overlay {
        Rectangle()
          .stroke(palette.accent.opacity(0.26), lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(palette.primaryText)
    .disabled(phase != .awaitingSequence)
    .opacity(phase == .awaitingSequence ? 1 : 0.45)
    .keyboardShortcut(KeyEquivalent(Character(String(rune.keyboardNumber))), modifiers: [])
    .accessibilityLabel("Choose \(rune.name) rune, key \(rune.keyboardNumber)")
  }

  private var statusText: String {
    switch phase {
    case .unlocking:
      "Seal broken — the threshold is moving"
    case .open:
      "Passage open — returning to the desktop"
    case .returningToDesktop:
      "Returning to the desktop…"
    case .awaitingSequence:
      switch lastMove {
      case .advanced(let current, let total):
        "Resonance stable · \(current) of \(total)"
      case .incorrect:
        "The seal recoiled — begin the sequence again"
      default:
        "Complete the sequence to return to the desktop · keys 1–4"
      }
    }
  }

  private func statusColor(palette: ThemePalette) -> Color {
    if lastMove == .incorrect && phase == .awaitingSequence {
      return Color(red: 0.98, green: 0.44, blue: 0.28)
    }
    return phase == .awaitingSequence ? palette.secondaryText : palette.accent
  }
}
