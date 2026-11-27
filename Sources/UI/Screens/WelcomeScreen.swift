import SwiftUI
import UIKit

/// First screen a new user sees (no playlist yet). Shows how to add a playlist
/// from the website (MAC + Key + QR) or directly inside the app (M3U / Xtream).
struct WelcomeScreen: View {
    let onAddXtream: () -> Void
    let onAddM3u: () -> Void
    let onHasPlaylists: () -> Void

    @EnvironmentObject var activation: ActivationStore
    @State private var checking = false
    @State private var current: Activation?

    private let mac = DeviceId.mac()
    private let key = DeviceId.key()

    private var website: String {
        ApiKeys.panel.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
            .trimmingTrailingSlash()
    }
    private var qrUrl: String {
        let base = ApiKeys.panel.trimmingTrailingSlash()
        return "\(base)/?mac=\(mac.urlEncoded)&key=\(key.urlEncoded)"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                BrandTitle(height: 52)
                Spacer().frame(height: 12)
                Text(tr("Welcome to Hot Smarters")).font(.title.bold()).foregroundStyle(.white)
                Spacer().frame(height: 6)
                Text(tr("Upload your playlist from our website"))
                    .font(.subheadline).foregroundStyle(Color.textSecondary)
                Spacer().frame(height: 14)

                HStack(spacing: 20) {
                    if !website.isEmpty {
                        VStack(spacing: 8) {
                            Button { SupportLinks.open(qrUrl) } label: { QrCode(data: qrUrl, size: 150) }
                                .buttonStyle(.plain)
                            Text("Tap or scan to manage").font(.caption2).foregroundStyle(Color.textSecondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        if !website.isEmpty { infoRow("Website", website) { copy(website) } }
                        infoRow("MAC", mac) { copy(mac) }
                        infoRow("Key", key) { copy(key) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(LinearGradient.brandCard)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer().frame(height: 12)
                Button { Task { await loadUploadedTapped() } } label: {
                    Group {
                        if checking { ProgressView().tint(.white) }
                        else { Text(tr("I've uploaded — load my playlist")).fontWeight(.bold).foregroundStyle(.white) }
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(LinearGradient.brandCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(checking)

                Spacer().frame(height: 24)
                Text(tr("Or upload inside the app")).font(.subheadline.bold()).foregroundStyle(.white)
                Spacer().frame(height: 10)
                HStack(spacing: 14) {
                    uploadButton("M3U", action: onAddM3u)
                    uploadButton("Xtream Code", action: onAddXtream)
                }

                Spacer().frame(height: 14)
                trialBanner
            }
            .padding(.horizontal, 24).padding(.vertical, 16)
        }
        .background(Color.darkBg)
        .onAppear { current = activation.current }
    }

    private var trialBanner: some View {
        let a = current
        let paid = a != nil && a!.status == "active" && !a!.plan.isEmpty && a!.plan != "trial"
        let text: String
        if paid, let a {
            let exp = a.plan == "lifetime" ? nil : a.expiresAt.map { String($0.prefix(10)) }
            text = "You're activated — \(planName(a.plan))" + (exp.map { "  ·  expires \($0)" } ?? "")
        } else {
            text = "Your free 7-day trial has started"
        }
        let color: Color = paid ? Color(hex: 0x2ECC71) : .hotRed
        return Text(text).font(.subheadline.bold()).foregroundStyle(color)
            .frame(maxWidth: .infinity).padding(14)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func planName(_ p: String) -> String {
        switch p {
        case "half_year": return "6 Months"
        case "year": return "1 Year"
        case "lifetime": return "Lifetime"
        default: return "Full version"
        }
    }

    @ViewBuilder
    private func infoRow(_ label: String, _ value: String, onCopy: @escaping () -> Void) -> some View {
        Button(action: onCopy) {
            HStack {
                Text("\(label):").foregroundStyle(Color.textSecondary).frame(minWidth: 76, alignment: .leading)
                Text(value).fontWeight(.bold).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "doc.on.doc").foregroundStyle(Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func uploadButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).fontWeight(.bold).foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.hotRed)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .glow()
        }
    }

    private func loadUploadedTapped() async {
        checking = true
        let result = await loadUploaded()
        checking = false
        if result == 1 { onHasPlaylists() }
    }

    /// 1 = loaded, 0 = reached server but no playlist, -1 = unreachable.
    private func loadUploaded() async -> Int {
        let a = await activation.refresh()
        if let a { current = a }
        if a == nil { return -1 }
        return Prefs.playlists().isEmpty ? 0 : 1
    }

    private func copy(_ text: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
    }
}

extension String {
    func trimmingTrailingSlash() -> String {
        var s = self
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }
}
