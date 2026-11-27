import SwiftUI

/// True if a parental code is set and the category name looks adult/locked.
func isLockedCategory(_ name: String) -> Bool {
    if Prefs.parentalCode() == nil { return false }
    let n = name.lowercased()
    return n.contains("adult") || n.contains("xxx") || n.contains("porn")
        || n.contains("+18") || n.contains("18+") || n.contains("for adults")
}

/// Parental-code entry dialog. Mirrors the Android `PinDialog`.
struct PinDialog: View {
    let onDismiss: () -> Void
    let onSuccess: () -> Void
    @State private var pin = ""
    @State private var error = false

    var body: some View {
        AppDialogCard(
            title: tr("Parental code"),
            confirmText: "Unlock",
            onConfirm: {
                if !pin.isEmpty && pin == Prefs.parentalCode() { onSuccess() } else { error = true }
            },
            dismissText: tr("Cancel"),
            onDismiss: onDismiss
        ) {
            Text("Enter your code to continue.")
                .font(.subheadline).foregroundStyle(Color.textSecondary)
            SecureField("", text: $pin)
                .keyboardType(.numberPad)
                .onChange(of: pin) { v in pin = String(v.filter { $0.isNumber }.prefix(6)); error = false }
                .padding(12)
                .background(Color.darkSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
            if error {
                Text("Wrong code").font(.caption).foregroundStyle(Color.hotRed)
            }
        }
    }
}
