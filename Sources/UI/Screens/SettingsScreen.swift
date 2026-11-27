import SwiftUI

/// Settings: playback, app, account/activation and about, plus Disconnect.
/// Mirrors Android `SettingsScreen`.
struct SettingsScreen: View {
    let onBack: () -> Void
    let onDisconnect: () -> Void

    @EnvironmentObject var repo: ContentRepository
    @EnvironmentObject var i18n: I18n
    @EnvironmentObject var activation: ActivationStore

    @State private var autoNext = Prefs.autoPlayNext()
    @State private var audioLang = Prefs.audioLang()
    @State private var subLang = Prefs.subtitleLang()
    @State private var videoFit = Prefs.videoFit()
    @State private var startScreen = Prefs.startScreen()
    @State private var parentalSet = Prefs.parentalCode() != nil
    @State private var speed = "Not tested"

    @State private var picker: String?
    @State private var showLanguage = false
    @State private var showParental = false
    @State private var parentalCode = ""
    @State private var hasParental = Prefs.parentalCode() != nil

    private let langs: [(String, String)] = [
        ("Default", ""), ("English", "en"), ("French", "fr"), ("Arabic", "ar"),
        ("Spanish", "es"), ("German", "de"), ("Italian", "it"), ("Portuguese", "pt"), ("Turkish", "tr")
    ]
    private var subLangs: [(String, String)] { [("Off", "")] + langs.dropFirst() }

    private var plan: String { activation.current?.plan ?? "" }
    private var planLabel: String {
        switch plan { case "half_year": return "6 Months"; case "year": return "1 Year"
        case "lifetime": return "Lifetime"; case "trial": return "Trial"; case "": return "—"; default: return plan }
    }
    private var expiry: String {
        if plan == "lifetime" { return "Lifetime" }
        if let e = activation.current?.expiresAt { return String(e.prefix(10)) }
        return "—"
    }
    private var website: String {
        ApiKeys.panel.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").trimmingTrailingSlash()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white) }
                Text(tr("Settings")).font(.headline).foregroundStyle(.white)
                Spacer()
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    group(tr("Playback")) {
                        toggleRow(tr("Auto-play next episode"), tr("Start the next episode automatically"), $autoNext) { Prefs.setAutoPlayNext($0) }
                        pickerRow(tr("Audio language"), name(audioLang, langs)) { picker = "audio" }
                        pickerRow(tr("Subtitle language"), name(subLang, subLangs)) { picker = "sub" }
                        pickerRow(tr("Video fit"), videoFit) { picker = "fit" }
                    }
                    group(tr("App")) {
                        pickerRow(tr("Start screen"), startScreen == "Live" ? tr("Live TV") : tr("Home")) { picker = "start" }
                        pickerRow(tr("App language"), i18n.current) { showLanguage = true }
                        pickerRow(tr("Parental code"), hasParental ? tr("Enabled") : tr("Not set")) { parentalCode = ""; showParental = true }
                        actionRow(tr("Clear cache & refresh"), tr("Reload channels, movies and series")) {
                            CacheUtil.clear(); Task { await repo.refresh() }
                        }
                        actionRow(tr("Test internet speed"), speed) {
                            speed = tr("Testing…")
                            Task { let m = await NetworkSpeed.measureMbps(); speed = m != nil ? String(format: "%.1f Mbps", m!) : "Unavailable" }
                        }
                        actionRow(tr("Check for updates"), tr("Open the website for the latest version")) {
                            SupportLinks.open(ApiKeys.panel)
                        }
                    }
                    group(tr("Account & activation")) {
                        infoRow(tr("Subscription"), planLabel)
                        infoRow(tr("Expires"), expiry)
                        infoRow("MAC", DeviceId.get())
                        infoRow(tr("Key"), DeviceId.key())
                    }
                    group(tr("About")) {
                        infoRow(tr("App"), "Hot Smarters Player")
                        infoRow(tr("Version"), "1.0")
                        infoRow(tr("Website"), website)
                        infoRow(tr("Library"), "\(repo.live.count) live • \(repo.movies.count) movies • \(repo.series.count) series")
                    }
                    Button { repo.clear(); onDisconnect() } label: {
                        Text(tr("Disconnect")).fontWeight(.bold).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50).background(Color.hotRed).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 8)
            }
        }
        .background(Color.darkBg)
        .appDialog(item: Binding(get: { picker }, set: { picker = $0 })) { which in pickerDialog(which) }
        .appDialog(isPresented: $showLanguage) {
            AppOptionDialog(title: tr("App language"), options: I18n.languages.map { ($0.display, $0.display) }, current: i18n.current, onDismiss: { showLanguage = false }) { lang in
                i18n.set(lang); showLanguage = false
            }
        }
        .appDialog(isPresented: $showParental) { parentalDialog }
    }

    @ViewBuilder
    private func pickerDialog(_ which: String) -> some View {
        switch which {
        case "audio":
            AppOptionDialog(title: tr("Audio language"), options: langs, current: audioLang, onDismiss: { picker = nil }) { audioLang = $0; Prefs.setAudioLang($0); picker = nil }
        case "sub":
            AppOptionDialog(title: tr("Subtitle language"), options: subLangs, current: subLang, onDismiss: { picker = nil }) { subLang = $0; Prefs.setSubtitleLang($0); picker = nil }
        case "fit":
            AppOptionDialog(title: tr("Video fit"), options: [("Fit (keep shape)", "Fit"), ("Fill (crop edges)", "Fill"), ("Stretch", "Stretch")], current: videoFit, onDismiss: { picker = nil }) { videoFit = $0; Prefs.setVideoFit($0); picker = nil }
        default:
            AppOptionDialog(title: tr("Start screen"), options: [(tr("Home"), "Home"), (tr("Live TV"), "Live")], current: startScreen, onDismiss: { picker = nil }) { startScreen = $0; Prefs.setStartScreen($0); picker = nil }
        }
    }

    private var parentalDialog: some View {
        AppDialogCard(
            title: hasParental ? tr("Change parental code") : tr("Set parental code"),
            confirmText: tr("Save"),
            onConfirm: { if parentalCode.count >= 4 { Prefs.setParentalCode(parentalCode); hasParental = true; showParental = false } },
            confirmEnabled: parentalCode.count >= 4,
            dismissText: hasParental ? tr("Remove") : tr("Cancel"),
            onDismissClick: hasParental ? { Prefs.setParentalCode(nil); hasParental = false; showParental = false } : nil,
            onDismiss: { showParental = false }
        ) {
            SecureField(tr("4-digit code"), text: $parentalCode)
                .keyboardType(.numberPad)
                .onChange(of: parentalCode) { v in parentalCode = String(v.filter { $0.isNumber }.prefix(6)) }
                .padding(12).background(Color.darkSurface2).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
        }
    }

    // MARK: rows

    private func group<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 2).fill(Color.hotRed).frame(width: 4, height: 16)
                Text(title).font(.headline).foregroundStyle(.white)
            }
            .padding(.bottom, 10)
            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .glass(cornerRadius: 16, alpha: 0.55)
        }
    }

    private func toggleRow(_ title: String, _ subtitle: String, _ value: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        VStack(spacing: 0) {
            Toggle(isOn: Binding(get: { value.wrappedValue }, set: { value.wrappedValue = $0; onChange($0) })) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(.white)
                    Text(subtitle).font(.caption).foregroundStyle(Color.textSecondary)
                }
            }
            .tint(.hotRed)
            .padding(.vertical, 14)
            Divider().background(Color.dividerColor)
        }
    }

    private func pickerRow(_ title: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack {
                    Text(title).foregroundStyle(.white)
                    Spacer()
                    Text(value).font(.subheadline.bold()).foregroundStyle(Color.hotRed).lineLimit(1)
                }
                .padding(.vertical, 15)
                Divider().background(Color.dividerColor)
            }
        }
        .buttonStyle(.plain)
    }

    private func actionRow(_ title: String, _ subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(Color.hotRed)
                    Text(subtitle).font(.caption).foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 15)
                Divider().background(Color.dividerColor)
            }
        }
        .buttonStyle(.plain)
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.textSecondary).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1)
        }
        .padding(.vertical, 6)
    }

    private func name(_ code: String, _ opts: [(String, String)]) -> String {
        opts.first { $0.1 == code }?.0 ?? opts.first?.0 ?? ""
    }
}
