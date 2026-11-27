import SwiftUI

/// List of saved lines; open / edit / delete / add, plus MAC+KEY, support,
/// alerts, refresh and the subscription badge. Mirrors Android `PlaylistsScreen`.
struct PlaylistsScreen: View {
    let onAdd: () -> Void
    let onOpen: () -> Void
    let onEdit: (Playlist) -> Void
    var onEmpty: () -> Void = {}
    var onSettings: () -> Void = {}

    @EnvironmentObject var repo: ContentRepository
    @EnvironmentObject var activation: ActivationStore

    @State private var playlists: [Playlist] = []
    @State private var connecting: String?
    @State private var error: String?
    @State private var showSupport = false
    @State private var showNotifs = false
    @State private var unread = 0
    @State private var failed: String?
    @State private var pendingDelete: Playlist?
    @State private var pendingLockedDelete: Playlist?
    @State private var lockPin = ""
    @State private var lockErr: String?

    private var notifications: [PanelNotification] { activation.current?.notifications ?? [] }

    private let columns = [GridItem(.adaptive(minimum: 200), spacing: 14)]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.darkBg.ignoresSafeArea()
            VStack(spacing: 0) {
                BrandTitle(height: 80).frame(maxWidth: .infinity)
                if let error {
                    Text(error).font(.footnote).foregroundStyle(Color.hotRed).padding(.top, 10)
                }
                Spacer().frame(height: 16)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(playlists) { p in playlistCard(p) }
                        addCard
                    }
                    .padding(4)
                }
                .frame(maxHeight: .infinity)

                Spacer().frame(height: 16)
                bottomBar
            }
            .padding(.horizontal, 20).padding(.vertical, 16)

            SubscriptionBadge(activation: activation.current).padding(20)

            if let name = connecting { connectOverlay(name) }
        }
        .appDialog(item: $pendingDelete) { p in deleteDialog(p) }
        .appDialog(item: $pendingLockedDelete) { p in lockedDeleteDialog(p) }
        .appDialog(isPresented: $showSupport) { SupportDialog(support: activation.current?.support ?? SupportInfo()) { showSupport = false } }
        .appDialog(isPresented: $showNotifs) { NotificationsDialog(items: notifications) { showNotifs = false } }
        .appDialog(item: Binding(get: { failed.map { FailedBox(name: $0) } }, set: { if $0 == nil { failed = nil } })) { box in
            AppDialogCard(title: tr("Playlist not working"), confirmText: tr("Contact support"),
                          onConfirm: { failed = nil; showSupport = true }, dismissText: tr("Close"), onDismiss: { failed = nil }) {
                Text("\"\(box.name)\" isn't responding. The service may be down or your subscription expired — please contact your provider. You'll find their contact under Support.").foregroundStyle(.white)
            }
        }
        .task {
            reload()
            await syncFromPanel()
        }
    }

    struct FailedBox: Identifiable { let id = UUID(); let name: String }

    // MARK: cards

    private func playlistCard(_ p: Playlist) -> some View {
        let hostCount = p.hosts().count
        let expiry = ExpiryStore.get(p.id)
        return VStack(alignment: .leading, spacing: 0) {
            Text(p.name).font(.headline).foregroundStyle(.white).lineLimit(1)
            Text(p.type.rawValue.lowercased().capitalized).font(.caption).foregroundStyle(Color.textSecondary)
            Spacer().frame(height: 8)
            if p.isLocked {
                Label(tr("Protected"), systemImage: "lock.fill").font(.caption).foregroundStyle(Color.textSecondary)
            } else if hostCount > 1 {
                Text("Server \(min(p.activeHost, hostCount - 1) + 1) of \(hostCount)").font(.caption).foregroundStyle(Color.textSecondary)
            }
            if let expiry {
                let expired = expiry > 0 && expiry < Int64(Date().timeIntervalSince1970 * 1000)
                Text(expiry <= 0 ? "\(tr("Expires")): \(tr("Never"))" : "\(tr("Expires")): \(formatExpiry(expiry))")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(expired ? Color.hotRed : Color.textSecondary).padding(.top, 4)
            }
            Spacer()
            HStack {
                if !p.isLocked {
                    iconBtn("pencil") { onEdit(p) }
                    iconBtn("trash") { pendingDelete = p }
                    if hostCount > 1 { iconBtn("arrow.left.arrow.right", tint: .hotOrange) { switchDns(p) } }
                } else {
                    iconBtn("trash") { pendingLockedDelete = p; lockPin = ""; lockErr = nil }
                }
                Spacer()
                Button { open(p) } label: { Image(systemName: "play.fill").font(.title2).foregroundStyle(Color.hotRed) }
            }
        }
        .padding(14).frame(height: 162)
        .brandCardStyle()
        .contentShape(Rectangle())
        .onTapGesture { open(p) }
    }

    private var addCard: some View {
        Button(action: onAdd) {
            VStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 40)).foregroundStyle(Color.hotRed)
                Text(tr("ADD Playlist")).fontWeight(.bold).foregroundStyle(Color.hotRed)
            }
            .frame(maxWidth: .infinity).frame(height: 150)
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.hotRed, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func iconBtn(_ system: String, tint: Color = .textSecondary, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: system).foregroundStyle(tint).frame(width: 34, height: 34) }
            .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        HStack {
            infoColumn("MAC", DeviceId.get())
            infoColumn("KEY", DeviceId.key())
            barAction("gearshape.fill", tr("Settings")) { onSettings() }
            barAction("questionmark.circle.fill", tr("Support")) { showSupport = true }
            ZStack(alignment: .topTrailing) {
                barAction("bell.fill", tr("Alerts")) {
                    showNotifs = true; NotificationStore.markAllRead(notifications); unread = 0
                }
                if unread > 0 { Circle().fill(Color.hotRed).frame(width: 9, height: 9).padding(4) }
            }
            barAction("arrow.clockwise", tr("Refresh")) { Task { reload(); await syncFromPanel() } }
        }
    }

    private func infoColumn(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(Color.textSecondary)
            Text(value).fontWeight(.bold).foregroundStyle(.white).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func barAction(_ system: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: system).foregroundStyle(Color.hotRed)
                Text(label).fontWeight(.bold).foregroundStyle(.white)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(LinearGradient.brandCard)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.leading, 10)
    }

    // MARK: dialogs

    private func deleteDialog(_ p: Playlist) -> some View {
        AppDialogCard(title: tr("Delete playlist?"), confirmText: tr("Delete"),
                      onConfirm: {
                          pendingDelete = nil
                          Task {
                              Prefs.removePlaylist(p.id); reload()
                              await activation.pushPlaylists()
                              if playlists.isEmpty { onEmpty() }
                          }
                      }, dismissText: tr("Cancel"), onDismiss: { pendingDelete = nil }) {
            Text("\(tr("Delete")) \"\(p.name)\"? \(tr("You can add it again later."))").foregroundStyle(.white)
        }
    }

    private func lockedDeleteDialog(_ p: Playlist) -> some View {
        AppDialogCard(title: "Remove locked playlist", confirmText: "Remove",
                      onConfirm: {
                          Task {
                              let e = await activation.deletePlaylist(id: p.id, pin: lockPin.trimmingCharacters(in: .whitespaces))
                              if e == nil { pendingLockedDelete = nil; reload(); if playlists.isEmpty { onEmpty() } }
                              else {
                                  switch e {
                                  case "bad_pin": lockErr = "Wrong PIN. The playlist was not removed."
                                  case "reseller_locked": lockErr = "This playlist is locked by your reseller and can't be removed here."
                                  case "network", "offline": lockErr = "Couldn't reach the server. Try again."
                                  default: lockErr = "Couldn't remove the playlist."
                                  }
                              }
                          }
                      }, confirmEnabled: lockPin.count >= 3, dismissText: "Cancel", onDismiss: { pendingLockedDelete = nil }) {
            Text("\"\(p.name)\" is protected. Enter its PIN to remove it.").foregroundStyle(.white)
            SecureField("PIN", text: $lockPin)
                .keyboardType(.numberPad)
                .onChange(of: lockPin) { v in lockPin = String(v.filter { $0.isNumber }.prefix(8)); lockErr = nil }
                .padding(12).background(Color.darkSurface2).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
            if let lockErr { Text(lockErr).font(.footnote).foregroundStyle(Color.hotRed) }
        }
    }

    private func connectOverlay(_ name: String) -> some View {
        let prog = repo.loadProgress
        return ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().tint(.hotRed)
                Text("\(tr("Connecting to")) \(name)").font(.headline).foregroundStyle(.white)
                progressLine(tr("Live TV"), prog.live, sectionState("live", prog.stage))
                progressLine(tr("Movies"), prog.movies, sectionState("movies", prog.stage))
                progressLine(tr("Series"), prog.series, sectionState("series", prog.stage))
            }
        }
    }

    private func progressLine(_ label: String, _ count: Int, _ state: String) -> some View {
        HStack {
            Text(label).fontWeight(.semibold).foregroundStyle(.white)
            Spacer()
            Text(state == "done" ? "\(count)  ✓" : (state == "loading" ? "loading…" : "—"))
                .fontWeight(.bold)
                .foregroundStyle(state == "done" ? Color(hex: 0x2ECC71) : (state == "loading" ? .white : .white.opacity(0.4)))
        }
        .frame(width: 240).padding(.vertical, 4)
    }

    // MARK: actions

    private func reload() { playlists = Prefs.playlists() }

    private func syncFromPanel() async {
        let had = !Prefs.playlists().isEmpty
        await activation.refresh()
        reload()
        unread = NotificationStore.unreadCount(activation.current?.notifications ?? [])
        if had && Prefs.playlists().isEmpty { onEmpty() }
    }

    private func open(_ p: Playlist) {
        Task {
            error = nil; connecting = p.name
            let ok = await repo.connect(p)
            connecting = nil
            if ok { onOpen() } else { failed = p.name }
        }
    }

    private func switchDns(_ p: Playlist) {
        let hs = p.hosts()
        if hs.count > 1 {
            var copy = p; copy.activeHost = (p.activeHost + 1) % hs.count
            Prefs.updatePlaylist(copy); reload()
        }
    }

    private func formatExpiry(_ ms: Int64) -> String {
        let f = DateFormatter(); f.dateFormat = "dd MMM yyyy"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
}

private let stageOrder = ["", "live", "movies", "series", "categories", "done"]
private func sectionState(_ section: String, _ stage: String) -> String {
    let si = stageOrder.firstIndex(of: section) ?? 0
    let ci = max(stageOrder.firstIndex(of: stage) ?? 0, 0)
    if ci > si { return "done" }
    if ci == si { return "loading" }
    return "pending"
}

/// Subscription status badge (plan + expiry / trial days remaining).
struct SubscriptionBadge: View {
    let activation: Activation?

    var body: some View {
        if let info = subscriptionInfo(activation) {
            let accent: Color = info.severity == 2 ? .hotRed : (info.severity == 1 ? Color(hex: 0xF1C40F) : Color.textSecondary)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Circle().fill(info.severity == 0 ? Color(hex: 0x2ECC71) : accent).frame(width: 8, height: 8)
                    Text(info.title).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1)
                }
                Text(info.subtitle).font(.caption.weight(.semibold)).foregroundStyle(accent).lineLimit(2)
            }
            .frame(maxWidth: 260)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(LinearGradient.brandCard)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
    }

    private func subscriptionInfo(_ a: Activation?) -> (title: String, subtitle: String, severity: Int)? {
        guard let a else { return nil }
        func dayWord(_ n: Int) -> String { n == 1 ? "day" : "days" }
        if a.status == "banned" { return (tr("Subscription"), "Account blocked", 2) }
        switch a.plan {
        case "lifetime": return (tr("Lifetime"), tr("Never expires"), 0)
        case "trial":
            let d = daysRemaining(a.expiresAt)
            if a.status == "expired" || (d != nil && d! <= 0) { return (tr("Free Trial"), "Your free trial has ended", 2) }
            if let d { return (tr("Free Trial"), "\(d) \(dayWord(d)) remaining of your free trial", d <= 2 ? 1 : 0) }
            return (tr("Free Trial"), "Free trial active", 0)
        case "half_year", "year":
            let label = a.plan == "half_year" ? "6 Months" : "1 Year"
            let d = daysRemaining(a.expiresAt)
            let date = a.expiresAt.map { String($0.prefix(10)) } ?? ""
            if a.status == "expired" || (d != nil && d! <= 0) {
                return (tr(label), "\(tr("Expired"))\(date.isEmpty ? "" : " • \(date)")", 2)
            }
            if let d, !date.isEmpty { return (tr(label), "\(tr("Expires")) \(date) • \(d) \(dayWord(d)) left", d <= 5 ? 1 : 0) }
            if !date.isEmpty { return (tr(label), "\(tr("Expires")) \(date)", 0) }
            return (tr(label), "Active", 0)
        default: return nil
        }
    }

    private func daysRemaining(_ iso: String?) -> Int? {
        guard let iso, !iso.isEmpty else { return nil }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"
        guard let exp = f.date(from: String(iso.prefix(10))), let today = f.date(from: f.string(from: Date())) else { return nil }
        return Int((exp.timeIntervalSince1970 - today.timeIntervalSince1970) / 86400) + 1
    }
}
