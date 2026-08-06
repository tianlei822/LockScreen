import LockScreenCore
import SwiftUI

struct VaultPasscodeView: View {
  let onSubmit: (String) -> VaultPasscodeResult

  @State private var passcode = ""
  @State private var status = "ENTER ACCESS CODE"
  @State private var isRejected = false
  @State private var isShaking = false
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
      VStack(spacing: 14) {
        HStack(spacing: 9) {
          Image(systemName: "lock.square.stack.fill")
            .font(.system(size: 17, weight: .medium))
          VStack(alignment: .leading, spacing: 2) {
            Text("CIPHER SAFE")
              .font(.system(size: 12, weight: .bold, design: .monospaced))
              .tracking(2.4)
            Text("LOCAL RITUAL ACCESS")
              .font(.system(size: 8, weight: .medium, design: .monospaced))
              .tracking(1.5)
              .foregroundStyle(Color.white.opacity(0.42))
          }
          Spacer()
          Circle()
            .fill(isRejected ? Color.red : amber)
            .frame(width: 7, height: 7)
            .shadow(color: isRejected ? .red : amber, radius: 6)
        }

        SecureField("Passcode", text: $passcode)
          .textFieldStyle(.plain)
          .font(.system(size: 24, weight: .medium, design: .monospaced))
          .multilineTextAlignment(.center)
          .padding(.horizontal, 14)
          .frame(height: 48)
          .background(Color.black.opacity(0.62))
          .overlay {
            RoundedRectangle(cornerRadius: 4)
              .stroke(isRejected ? Color.red.opacity(0.74) : amber.opacity(0.38), lineWidth: 1)
          }
          .focused($isFocused)
          .onSubmit(submit)
          .onChange(of: passcode) { _, value in
            let digits = value.filter(\.isNumber)
            passcode = String(digits.prefix(8))
            if isRejected, !passcode.isEmpty {
              isRejected = false
              status = "ENTER ACCESS CODE"
            }
          }
          .accessibilityLabel("Vault passcode")
          .accessibilityHint("Enter the configured 4 to 8 digit code, then press Return")

        LazyVGrid(
          columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8
        ) {
          ForEach(rows.flatMap { $0 }, id: \.self) { key in
            keypadButton(key)
          }
        }

        Text(status)
          .font(.system(size: 9, weight: .semibold, design: .monospaced))
          .tracking(2.2)
          .foregroundStyle(isRejected ? Color.red.opacity(0.9) : amber.opacity(0.76))
          .frame(height: 13)
          .accessibilityLabel(status.lowercased())
      }
      .padding(20)
      .frame(width: 318)
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
      .onAppear {
        isFocused = true
      }
    }
  }

  private func keypadButton(_ key: String) -> some View {
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
      .font(.system(size: 15, weight: .semibold, design: .monospaced))
      .frame(maxWidth: .infinity)
      .frame(height: 38)
      .background(key == "submit" ? amber.opacity(0.82) : Color.white.opacity(0.055))
      .overlay {
        RoundedRectangle(cornerRadius: 3)
          .stroke(Color.white.opacity(key == "submit" ? 0.22 : 0.09), lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .foregroundStyle(key == "submit" ? Color.black.opacity(0.84) : Color.white.opacity(0.8))
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
      reject(message: "CODE REQUIRED")
      return
    }

    switch onSubmit(passcode) {
    case .completed:
      status = "ACCESS GRANTED"
      isRejected = false
    case .incorrect:
      passcode.removeAll()
      reject(message: "ACCESS DENIED")
    case .ignored:
      break
    }
  }

  private func reject(message: String) {
    status = message
    isRejected = true
    withAnimation(.spring(response: 0.14, dampingFraction: 0.25)) {
      isShaking = true
    }

    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(180))
      withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) {
        isShaking = false
      }
    }
  }

  private func keypadAccessibilityLabel(_ key: String) -> String {
    switch key {
    case "delete":
      "Delete last digit"
    case "submit":
      "Unlock vault"
    default:
      "Digit (key)"
    }
  }
}
