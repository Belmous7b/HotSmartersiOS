import SwiftUI
import UIKit

/// Opens a reseller's support contacts in the right app. Mirrors Android `SupportLinks`.
enum SupportLinks {
    static func website(_ raw: String) {
        let url = raw.lowercased().hasPrefix("http") ? raw : "https://\(raw)"
        open(url)
    }
    static func whatsapp(_ raw: String) {
        let digits = raw.filter { $0.isNumber }
        if digits.isEmpty { return }
        open("https://wa.me/\(digits)")
    }
    static func telegram(_ raw: String) {
        let h = raw.trimmingCharacters(in: .whitespaces)
        let url: String
        if h.lowercased().hasPrefix("http") { url = h }
        else if h.hasPrefix("@") { url = "https://t.me/\(h.dropFirst())" }
        else { url = "https://t.me/\(h)" }
        open(url)
    }
    static func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }
}

struct SupportRow: View {
    let icon: String
    let label: String
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(Color.hotRed)
                Text(label).foregroundStyle(.white)
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

/// Support dialog used from the dashboard/playlists.
struct SupportDialog: View {
    let support: SupportInfo
    let onDismiss: () -> Void
    var body: some View {
        AppDialogCard(title: tr("Support"), dismissText: tr("Close"), onDismiss: onDismiss) {
            if support.isEmpty {
                Text("No support contact is available yet. Please try again after activation.")
                    .foregroundStyle(.white)
            } else {
                if !support.website.isEmpty {
                    SupportRow(icon: "globe", label: support.website) { SupportLinks.website(support.website) }
                }
                if !support.whatsapp.isEmpty {
                    SupportRow(icon: "phone.fill", label: "WhatsApp: \(support.whatsapp)") { SupportLinks.whatsapp(support.whatsapp) }
                }
                if !support.telegram.isEmpty {
                    SupportRow(icon: "paperplane.fill", label: "Telegram: \(support.telegram)") { SupportLinks.telegram(support.telegram) }
                }
            }
        }
    }
}

/// List of panel notifications, reusable across screens.
struct NotificationsDialog: View {
    let items: [PanelNotification]
    let onDismiss: () -> Void
    var body: some View {
        AppDialogCard(title: tr("Notifications"), dismissText: tr("Close"), onDismiss: onDismiss) {
            if items.isEmpty {
                Text(tr("No notifications yet.")).foregroundStyle(.white)
            } else {
                ForEach(items) { n in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(n.title).fontWeight(.bold).foregroundStyle(.white)
                        Text(n.body).font(.subheadline).foregroundStyle(Color.textSecondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }
}
