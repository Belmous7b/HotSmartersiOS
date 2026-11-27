import SwiftUI

/// Wraps the app. If a panel is configured and the device's subscription is
/// expired or banned, it shows a block screen instead of the app. A trial /
/// not-yet-activated / offline device passes through. Mirrors Android `ActivationGate`.
struct ActivationGate<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @EnvironmentObject var activation: ActivationStore

    @State private var checked = false
    @State private var checking = false
    @State private var current: Activation?

    var body: some View {
        Group {
            if ApiKeys.panel.isEmpty {
                content()
            } else if !checked {
                SplashView()
            } else if let a = current, a.isBlocked {
                BlockedScreen(activation: a, mac: DeviceId.mac(), retrying: checking) {
                    Task { await doCheck() }
                }
            } else {
                content()
            }
        }
        .task {
            if !ApiKeys.panel.isEmpty && !checked { await doCheck() }
        }
    }

    private func doCheck() async {
        checking = true
        activation.load()
        let fresh = await activation.refresh()
        current = fresh ?? activation.current
        checking = false
        checked = true
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()
            VStack(spacing: 24) {
                BrandTitle(height: 120)
                ProgressView().tint(.hotRed)
            }
        }
    }
}

/// Shown whenever the device isn't active (expired OR banned). Shows the MAC and
/// the activation steps. Mirrors Android `BlockedScreen`.
struct BlockedScreen: View {
    let activation: Activation
    let mac: String
    let retrying: Bool
    let onRetry: () -> Void

    private var portal: String {
        let base = ApiKeys.panel.hasSuffix("/") ? String(ApiKeys.panel.dropLast()) : ApiKeys.panel
        return base + "/portal"
    }
    private var portalLabel: String {
        portal.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "")
    }

    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    BrandTitle(height: 96)
                    Text("Subscription expired").font(.title.bold()).foregroundStyle(.white)
                    Text("Your device is no longer active. Activate it again to keep watching.")
                        .multilineTextAlignment(.center).foregroundStyle(Color.textSecondary)

                    VStack(spacing: 2) {
                        Text("YOUR MAC").font(.caption).foregroundStyle(Color.textSecondary)
                        Text(mac).font(.title3.bold()).foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12).padding(.horizontal, 16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How to activate").fontWeight(.bold).foregroundStyle(.white)
                        stepLine("1", "Go to  ", link: portalLabel)
                        stepLine("2", "Type your MAC:  \(mac)")
                        stepLine("3", "Choose a plan and activate")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))

                    Button {
                        SupportLinks.website(portal)
                    } label: {
                        Text("Open activation page").frame(maxWidth: .infinity).padding(.vertical, 12)
                            .background(Color.hotRed).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(action: onRetry) {
                        Text(retrying ? "Checking…" : "I've activated — check again")
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.hotRed, lineWidth: 1))
                            .foregroundStyle(.white)
                    }
                    .disabled(retrying)
                }
                .frame(maxWidth: 460)
                .padding(28)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func stepLine(_ number: String, _ text: String, link: String? = nil) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(number).font(.footnote.bold()).foregroundStyle(.white)
                .frame(width: 24, height: 24).background(Color.hotRed).clipShape(Circle())
            (Text(text).foregroundColor(.white)
             + (link != nil ? Text(link!).foregroundColor(.hotRed).underline() : Text("")))
            Spacer()
        }
    }
}
