import LockScreenCore
import SwiftUI

struct VaultPasscodeSettingsView: View {
  let onSave: (String) -> Bool

  @Environment(\.dismiss) private var dismiss
  @State private var passcode = ""
  @State private var confirmation = ""
  @State private var saveFailed = false
  @FocusState private var focusedField: Field?

  private enum Field: Hashable {
    case passcode
    case confirmation
  }

  private let amber = Color(red: 0.94, green: 0.61, blue: 0.18)

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(spacing: 12) {
        Image(systemName: "key.fill")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(amber)
          .frame(width: 34, height: 34)
          .background(amber.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 3) {
          Text(L10n.text("CHANGE RITUAL CODE"))
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .tracking(1.8)
          Text(L10n.text("PERSISTENT · THIS MAC"))
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .tracking(1.4)
            .foregroundStyle(Color.white.opacity(0.44))
        }
      }

      VStack(alignment: .leading, spacing: 12) {
        passcodeField(
          title: L10n.text("NEW CODE"),
          placeholder: L10n.text("4–8 digits"),
          text: $passcode,
          field: .passcode
        )
        passcodeField(
          title: L10n.text("CONFIRM CODE"),
          placeholder: L10n.text("Enter again"),
          text: $confirmation,
          field: .confirmation
        )
      }

      HStack(spacing: 8) {
        Image(systemName: validationSymbol)
          .accessibilityHidden(true)
        Text(validationMessage)
      }
      .font(.system(size: 9, weight: .semibold, design: .monospaced))
      .tracking(1.1)
      .foregroundStyle(validationColor)
      .accessibilityElement(children: .combine)

      HStack(alignment: .top, spacing: 8) {
        Image(systemName: "exclamationmark.shield")
          .foregroundStyle(amber.opacity(0.76))
          .accessibilityHidden(true)
        Text(L10n.text("Threshold ritual code only. Never use your macOS password."))
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(Color.white.opacity(0.56))
          .fixedSize(horizontal: false, vertical: true)
      }

      HStack(spacing: 10) {
        Spacer()

        Button(L10n.text("Cancel")) {
          dismiss()
        }
        .buttonStyle(.bordered)
        .keyboardShortcut(.cancelAction)

        Button(L10n.text("Save Code")) {
          save()
        }
        .buttonStyle(.borderedProminent)
        .tint(amber)
        .foregroundStyle(Color.black.opacity(0.86))
        .keyboardShortcut(.defaultAction)
        .disabled(!canSave)
      }
    }
    .padding(24)
    .frame(width: 390)
    .background(
      LinearGradient(
        colors: [
          Color(red: 0.12, green: 0.135, blue: 0.14),
          Color(red: 0.045, green: 0.052, blue: 0.056),
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .preferredColorScheme(.dark)
    .onAppear {
      focusedField = .passcode
    }
  }

  private func passcodeField(
    title: String,
    placeholder: String,
    text: Binding<String>,
    field: Field
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.system(size: 9, weight: .semibold, design: .monospaced))
        .tracking(1.5)
        .foregroundStyle(Color.white.opacity(0.52))

      SecureField(placeholder, text: text)
        .textFieldStyle(.plain)
        .font(.system(size: 18, weight: .medium, design: .monospaced))
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Color.black.opacity(0.48))
        .overlay {
          RoundedRectangle(cornerRadius: 4)
            .stroke(
              focusedField == field ? amber.opacity(0.64) : Color.white.opacity(0.14),
              lineWidth: 1
            )
        }
        .focused($focusedField, equals: field)
        .onChange(of: text.wrappedValue) { _, value in
          let filteredValue = VaultPasscode.filteredInput(value)
          if filteredValue != value {
            text.wrappedValue = filteredValue
          }
          saveFailed = false
        }
        .accessibilityLabel(title.capitalized)
    }
  }

  private var canSave: Bool {
    LockFlow.isValidVaultPasscode(passcode) && passcode == confirmation && !saveFailed
  }

  private var validationMessage: String {
    if saveFailed {
      return L10n.text("CODE COULD NOT BE SAVED")
    }
    if passcode.isEmpty || confirmation.isEmpty {
      return L10n.text("ENTER AND CONFIRM 4–8 DIGITS")
    }
    if !LockFlow.isValidVaultPasscode(passcode) {
      return L10n.text("CODE MUST CONTAIN 4–8 DIGITS")
    }
    if passcode != confirmation {
      return L10n.text("CODES DO NOT MATCH")
    }
    return L10n.text("READY TO SAVE")
  }

  private var validationSymbol: String {
    canSave ? "checkmark.circle.fill" : "info.circle"
  }

  private var validationColor: Color {
    canSave ? amber : Color.white.opacity(0.48)
  }

  private func save() {
    guard canSave else { return }
    guard onSave(passcode) else {
      saveFailed = true
      return
    }
    dismiss()
  }
}
