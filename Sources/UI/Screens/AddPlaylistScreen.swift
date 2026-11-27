import SwiftUI
import UIKit

/// Add/edit a playlist. Tabs: 0 = Upload via website, 1 = Xtream, 2 = M3U URL.
/// Mirrors the Android `AddPlaylistScreen`.
struct AddPlaylistScreen: View {
    var editId: String? = nil
    var lockType: String? = nil
    let onSaved: () -> Void
    var onWebsiteLoaded: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil

    @EnvironmentObject var repo: ContentRepository
    @EnvironmentObject var activation: ActivationStore

    @State private var tab: Int
    @State private var error: String?
    @State private var connecting = false
    @State private var savedId: String?

    @State private var name = ""
    @State private var host = ""
    @State private var user = ""
    @State private var pass = ""
    @State private var m3uUrl = ""
    @State private var epg = ""
    @State private var activeHost = 0

    private let locked: Bool

    init(editId: String?, lockType: String?, onSaved: @escaping () -> Void,
         onWebsiteLoaded: (() -> Void)? = nil, onBack: (() -> Void)? = nil) {
        self.editId = editId
        self.lockType = lockType
        self.onSaved = onSaved
        self.onWebsiteLoaded = onWebsiteLoaded
        self.onBack = onBack
        let lockedTab: Int? = lockType == "xtream" ? 1 : (lockType == "m3u" ? 2 : nil)
        self.locked = lockedTab != nil && editId == nil
        _tab = State(initialValue: lockedTab ?? 0)
        _savedId = State(initialValue: editId)
    }

    private var website: String {
        ApiKeys.panel.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").trimmingTrailingSlash()
    }
    private var qrUrl: String {
        "\(ApiKeys.panel.trimmingTrailingSlash())/?mac=\(DeviceId.get().urlEncoded)&key=\(DeviceId.key().urlEncoded)"
    }
    private let tabs = ["Upload via website", "Xtream Codes", "M3U URL"]

    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let onBack {
                        Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white).padding(8) }
                    }
                    Spacer().frame(height: 8)
                    BrandTitle()
                    Spacer().frame(height: 4)
                    Text(headerTitle).font(.title3).foregroundStyle(Color.textSecondary)
                    Spacer().frame(height: 24)

                    if tab != 0 {
                        field("Playlist name", text: $name)
                        Spacer().frame(height: 16)
                    }

                    if !locked {
                        Picker("", selection: $tab) {
                            ForEach(0..<tabs.count, id: \.self) { i in Text(tabs[i]).tag(i) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: tab) { _ in error = nil }
                        Spacer().frame(height: 18)
                    }

                    tabContent
                    Spacer().frame(height: 16)
                    if let error {
                        Text(error).font(.footnote).foregroundStyle(Color.hotRed)
                        Spacer().frame(height: 12)
                    }

                    Button { primaryTapped() } label: {
                        Text(buttonLabel).fontWeight(.bold).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Color.hotRed)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .glow()
                    }
                    .disabled(connecting)
                }
                .padding(24)
            }
            if connecting { ConnectingOverlay(isWebsite: tab == 0, isEdit: editId != nil) }
        }
        .onAppear(perform: prefill)
    }

    private var headerTitle: String {
        if editId != nil { return "Edit playlist" }
        if locked && tab == 1 { return "Add Xtream playlist" }
        if locked && tab == 2 { return "Add M3U playlist" }
        return "Add a playlist"
    }

    private var buttonLabel: String {
        if connecting { return tab == 0 ? "Checking…" : "Connecting…" }
        if editId != nil { return "Save changes" }
        if tab == 0 { return "Load my playlist" }
        return "Save & connect"
    }

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case 0:
            VStack(alignment: .leading, spacing: 10) {
                Text("Upload your playlist from our website, then come back and tap \"Load my playlist\".")
                    .font(.subheadline).foregroundStyle(Color.textSecondary)
                if !website.isEmpty { copyField("Website", website) }
                copyField("MAC address", DeviceId.get())
                copyField("Device key", DeviceId.key())
                if !website.isEmpty {
                    VStack(spacing: 8) {
                        QrCode(data: qrUrl, size: 160)
                        Text("Scan to open & manage on the website").font(.caption).foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        case 1:
            VStack(spacing: 12) {
                field("Server URL (http://host:port)", text: $host)
                field("Username", text: $user)
                secureField("Password", text: $pass)
                field("EPG / XMLTV URL (optional)", text: $epg)
            }
        default:
            VStack(spacing: 12) {
                field("M3U / M3U8 playlist URL", text: $m3uUrl)
                field("EPG / XMLTV URL (optional)", text: $epg)
            }
        }
    }

    private func field(_ label: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: Text(label).foregroundColor(Color.textSecondary))
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .foregroundStyle(.white).padding(14)
            .background(Color.darkSurface).clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dividerColor, lineWidth: 1))
    }
    private func secureField(_ label: String, text: Binding<String>) -> some View {
        SecureField("", text: text, prompt: Text(label).foregroundColor(Color.textSecondary))
            .foregroundStyle(.white).padding(14)
            .background(Color.darkSurface).clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dividerColor, lineWidth: 1))
    }
    private func copyField(_ label: String, _ value: String) -> some View {
        Button {
            #if canImport(UIKit)
            UIPasteboard.general.string = value
            #endif
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption).foregroundStyle(Color.textSecondary)
                    Text(value).fontWeight(.bold).foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "doc.on.doc").foregroundStyle(Color.textSecondary)
            }
            .padding(14).frame(maxWidth: .infinity)
            .background(LinearGradient.brandCard)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func prefill() {
        guard let editId, let p = Prefs.playlist(editId) else { return }
        name = p.name; host = p.host; user = p.username; pass = p.password
        m3uUrl = p.url; epg = p.epgUrl; activeHost = p.activeHost
        tab = p.type == .website ? 0 : (p.type == .xtream ? 1 : 2)
    }

    private func primaryTapped() {
        if tab == 0 && editId == nil { loadFromWebsite() } else { save() }
    }

    private func save() {
        if tab == 0 { onSaved(); return }
        if name.trimmingCharacters(in: .whitespaces).isEmpty { error = "Give this playlist a name."; return }
        let id = savedId ?? String(Int64(Date().timeIntervalSince1970 * 1000))
        let playlist: Playlist
        if tab == 1 {
            if host.isEmpty || user.isEmpty || pass.isEmpty { error = "Fill in host, username and password."; return }
            playlist = Playlist(id: id, name: name.trimmingCharacters(in: .whitespaces), type: .xtream,
                                host: host.trimmingCharacters(in: .whitespaces), username: user.trimmingCharacters(in: .whitespaces),
                                password: pass.trimmingCharacters(in: .whitespaces), epgUrl: epg.trimmingCharacters(in: .whitespaces), activeHost: activeHost)
        } else {
            if m3uUrl.isEmpty { error = "Paste your M3U URL."; return }
            playlist = Playlist(id: id, name: name.trimmingCharacters(in: .whitespaces), type: .m3u,
                                url: m3uUrl.trimmingCharacters(in: .whitespaces), epgUrl: epg.trimmingCharacters(in: .whitespaces), activeHost: activeHost)
        }
        let firstSave = savedId == nil && editId == nil
        if firstSave { Prefs.addPlaylist(playlist) } else { Prefs.updatePlaylist(playlist) }
        savedId = id

        Task {
            connecting = true; error = nil
            if !firstSave { repo.forget(id) }
            let ok = await repo.connect(playlist, force: !firstSave)
            await activation.pushPlaylists()
            connecting = false
            if ok { onSaved() } else { error = "Couldn't connect. Check your details — if it keeps failing, contact support." }
        }
    }

    private func loadFromWebsite() {
        Task {
            connecting = true; error = nil
            await activation.refresh()
            connecting = false
            if !Prefs.playlists().isEmpty { (onWebsiteLoaded ?? onSaved)() }
            else { error = "No playlist found yet. Upload it on our website first, then tap again." }
        }
    }
}

/// Full-screen "please wait" overlay shown while a playlist connects/loads.
struct ConnectingOverlay: View {
    let isWebsite: Bool
    let isEdit: Bool
    @EnvironmentObject var repo: ContentRepository

    var body: some View {
        let progress = repo.loadProgress
        let title = isWebsite ? "Checking your account…" : (isEdit ? "Reconnecting your playlist…" : "Connecting to your playlist…")
        let stageText: String = {
            if isWebsite { return "Please wait a moment…" }
            switch progress.stage {
            case "live": return "Loading live channels…"
            case "movies": return "Loading movies…"
            case "series": return "Loading series…"
            case "categories": return "Organising categories…"
            case "done": return "Almost ready…"
            default: return "Please wait a moment…"
            }
        }()
        var counts: [String] = []
        if progress.live > 0 { counts.append("Live \(progress.live)") }
        if progress.movies > 0 { counts.append("Movies \(progress.movies)") }
        if progress.series > 0 { counts.append("Series \(progress.series)") }

        return ZStack {
            Color.darkBg.opacity(0.94).ignoresSafeArea()
            VStack(spacing: 0) {
                BrandTitle(height: 52)
                Spacer().frame(height: 30)
                ProgressView().tint(.hotRed).scaleEffect(1.6)
                Spacer().frame(height: 26)
                Text(title).font(.title3.bold()).foregroundStyle(.white)
                Spacer().frame(height: 8)
                Text(stageText).font(.subheadline).foregroundStyle(Color.textSecondary)
                if !counts.isEmpty && !isWebsite {
                    Spacer().frame(height: 8)
                    Text(counts.joined(separator: "   ·   ")).font(.callout.bold()).foregroundStyle(.hotRed)
                }
            }
            .padding(24)
        }
    }
}
