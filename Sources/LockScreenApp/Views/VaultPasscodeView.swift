import LockScreenCore
import SwiftUI

struct VaultPasscodeView: View {
  let onSubmit: (String) -> VaultPasscodeResult
  let onUpdatePasscode: (String) -> Bool

  @Environment(\.ritualAnimationsPaused) private var ritualAnimationsPaused
  @Environment(\.ritualMotionReduced) private var ritualMotionReduced
  @State private var passcode = ""
  @State private var status = L10n.text("ENTER ACCESS CODE")
  @State private var isRejected = false
  @State private var isShaking = false
  @State private var rejectionTask: Task<Void, Never>?
  @State private var isShowingPasscodeSettings = false
  @FocusState private var isFocused: Bool

  private let amber = Color(red: 0.94, green: 0.61, blue: 0.18)
  private let rows = [
    ["1", "2", "3"],
    ["4", "5", "6"],
    ["7", "8", "9"],
    ["delete", "0", "submit"],
  ]

  var body: some View {
    GeometryReader { proxy in
      let compact = proxy.size.height < 440

      VStack(spacing: compact ? 12 : 16) {
        HStack(spacing: 9) {
          Image(systemName: "lock.square.stack.fill")
            .font(.system(size: 17, weight: .medium))
          VStack(alignment: .leading, spacing: 2) {
            Text(L10n.text("CIPHER SAFE"))
              .font(.system(size: 12, weight: .bold, design: .monospaced))
              .tracking(2.4)
            Text(L10n.text("LOCAL RITUAL ACCESS"))
              .font(.system(size: 9, weight: .medium, design: .monospaced))
              .tracking(0.8)
              .foregroundStyle(ThemePalette.vault.secondaryText)
          }
          Spacer()
          Button {
            isShowingPasscodeSettings = true
          } label: {
            Image(systemName: "gearshape")
              .font(.system(size: 11, weight: .semibold))
              .frame(width: 32, height: 32)
          }
          .buttonStyle(RitualButtonStyle(palette: .vault))
          .accessibilityLabel(L10n.text("Change Vault ritual code"))
          .help(L10n.text("Change the persistent Vault ritual code"))

          Circle()
            .fill(isRejected ? Color.red : amber)
            .frame(width: 7, height: 7)
            .shadow(color: isRejected ? .red : amber, radius: 6)
        }

        SecureField(L10n.text("Passcode"), text: $passcode)
          .textFieldStyle(.plain)
          .font(.system(size: 24, weight: .medium, design: .monospaced))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 14)
          .frame(height: 48)
          .background(Color.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 6))
          .overlay {
            RoundedRectangle(cornerRadius: 6)
              .stroke(
                isRejected ? Color.red.opacity(0.85) : amber.opacity(isFocused ? 0.8 : 0.3),
                lineWidth: 1
              )
          }
          .focused($isFocused)
          .onSubmit(submit)
          .onChange(of: passcode) { _, value in
            passcode = VaultPasscode.filteredInput(value)
            if isRejected || status == L10n.text("CODE UPDATED"), !passcode.isEmpty {
              isRejected = false
              status = L10n.text("ENTER ACCESS CODE")
            }
          }
          .accessibilityLabel(L10n.text("Vault passcode"))
          .accessibilityHint(
            L10n.text("Enter the configured 4 to 8 digit code, then press Return")
          )

        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8
        ) {
          ForEach(rows.flatMap { $0 }, id: \.self) { key in
            keypadButton(key, height: compact ? 38 : 44)
          }
        }

        Text(status)
          .font(.system(size: 10, weight: .medium, design: .monospaced))
          .tracking(1.6)
          .foregroundStyle(isRejected ? Color(red: 1, green: 0.46, blue: 0.4) : amber)
          .frame(height: 13)
          .accessibilityLabel(status.lowercased())
      }
      .padding(compact ? 20 : 24)
      .frame(width: 344)
      .background(
        LinearGradient(
          colors: [
            Color(red: 0.16, green: 0.18, blue: 0.18), Color(red: 0.055, green: 0.065, blue: 0.07),
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.white.opacity(0.16), lineWidth: 1)
          .padding(5)
      }
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.black.opacity(0.9), lineWidth: 5)
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .shadow(color: .black.opacity(0.9), radius: 24, y: 14)
      .offset(x: isShaking ? -5 : 0)
      .position(x: proxy.size.width / 2, y: proxy.size.height * 0.47)
      .task {
        await Task.yield()
        guard !Task.isCancelled else { return }
        isFocused = !ritualAnimationsPaused
      }
      .onChange(of: ritualAnimationsPaused) { _, _ in
        resetForNextSession()
      }
    }
    .onDisappear {
      rejectionTask?.cancel()
    }
    .sheet(isPresented: $isShowingPasscodeSettings) {
      VaultPasscodeSettingsView(onSave: saveUpdatedPasscode)
    }
    .onChange(of: isShowingPasscodeSettings) { _, isShowing in
      if !isShowing {
        isFocused = !ritualAnimationsPaused
      }
    }
  }

  private func keypadButton(_ key: String, height: CGFloat) -> some View {
    Button {
      handle(key)
    } label: {
      Group {
        switch key {
        case "delete":
          Image(systemName: "delete.left")
        case "submit":
          Image(systemName: "lock.open")
        default:
          Text(key)
        }
      }
      .font(.system(size: 17, weight: .medium, design: .monospaced))
      .frame(maxWidth: .infinity)
      .frame(height: height)
    }
    .buttonStyle(RitualButtonStyle(palette: .vault, isEmphasized: key == "submit"))
    .accessibilityLabel(keypadAccessibilityLabel(key))
  }

  private func handle(_ key: String) {
    switch key {
    case "delete":
      if !passcode.isEmpty {
        passcode.removeLast()
      }
    case "submit":
      submit()
    default:
      guard passcode.count < 8 else { return }
      passcode.append(key)
    }
    isFocused = true
  }

  private func submit() {
    guard !passcode.isEmpty else {
      reject(message: L10n.text("CODE REQUIRED"))
      return
    }

    let result = onSubmit(passcode)
    if result.clearsPasscodeEntry {
      passcode.removeAll()
    }

    switch result {
    case .completed:
      status = L10n.text("ACCESS GRANTED")
      isRejected = false
    case .incorrect:
      reject(message: L10n.text("ACCESS DENIED"))
    case .ignored:
      break
    }
  }

  private func reject(message: String) {
    rejectionTask?.cancel()
    status = message
    isRejected = true
    guard !ritualMotionReduced else {
      isShaking = false
      return
    }

    withAnimation(.spring(response: 0.14, dampingFraction: 0.25)) {
      isShaking = true
    }

    rejectionTask = Task { @MainActor in
      do {
        try await Task.sleep(for: .milliseconds(180))
      } catch {
        return
      }
      withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
        isShaking = false
      }
    }
  }

  private func saveUpdatedPasscode(_ updatedPasscode: String) -> Bool {
    guard onUpdatePasscode(updatedPasscode) else { return false }

    passcode.removeAll()
    status = L10n.text("CODE UPDATED")
    isRejected = false
    return true
  }

  private func resetForNextSession() {
    rejectionTask?.cancel()
    passcode.removeAll()
    status = L10n.text("ENTER ACCESS CODE")
    isRejected = false
    isShaking = false
    isShowingPasscodeSettings = false
    isFocused = !ritualAnimationsPaused
  }

  private func keypadAccessibilityLabel(_ key: String) -> String {
    switch key {
    case "delete":
      L10n.text("Delete last digit")
    case "submit":
      L10n.text("Unlock vault")
    default:
      L10n.format("Digit %@", key)
    }
  }
}
