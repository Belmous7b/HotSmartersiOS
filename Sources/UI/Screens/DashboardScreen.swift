import SwiftUI

/// The home hub: left rail + featured hero + Continue Watching + Latest added.
/// Mirrors Android `DashboardScreen` (Sport tile hidden, kept in nav).
struct DashboardScreen: View {
    let onLive: () -> Void
    let onMovies: () -> Void
    let onSeries: () -> Void
    let onSearch: () -> Void
    let onSwitchPlaylist: () -> Void
    let onAccount: () -> Void
    let onSettings: () -> Void
    let onSpeedTest: () -> Void
    let onWatchLater: () -> Void
    let onPlay: (String, String, String) -> Void
    let onOpenMovie: (VodItem) -> Void

    @EnvironmentObject var repo: ContentRepository
    @EnvironmentObject var activation: ActivationStore

    @State private var continueItems: [(item: HistoryItem, progress: Double)] = []
    @State private var featured: VodItem?
    @State private var featuredInfo: TmdbInfo?
    @State private var showSupport = false
    @State private var showNotifs = false
    @State private var unread = 0

    private var notifications: [PanelNotification] { activation.current?.notifications ?? [] }

    private var newVod: [VodItem] {
        let withPoster = repo.movies.filter { !($0.poster ?? "").isEmpty }
        return Array((withPoster.isEmpty ? repo.movies : withPoster).prefix(20))
    }

    var body: some View {
        HStack(spacing: 0) {
            leftRail
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    hero
                    if !continueItems.isEmpty {
                        section(tr("Continue Watching")) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(continueItems, id: \.item.id) { entry in
                                        continueCard(entry.item, entry.progress)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    section(tr("Latest added")) {
                        if newVod.isEmpty {
                            Text(tr("Connect a playlist to see movies.")).font(.footnote)
                                .foregroundStyle(Color.textSecondary).padding(.leading, 16)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(newVod) { item in newVodCard(item) }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    Spacer().frame(height: 16)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color.darkBg)
        .appDialog(isPresented: $showSupport) { SupportDialog(support: activation.current?.support ?? SupportInfo()) { showSupport = false } }
        .appDialog(isPresented: $showNotifs) { NotificationsDialog(items: notifications) { showNotifs = false } }
        .task {
            reloadContinue()
            unread = NotificationStore.unreadCount(notifications)
            await loadFeatured()
        }
    }

    private var leftRail: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                BrandTitle(height: 48).padding(.bottom, 8)
                railButton(tr("Home"), "house.fill", selected: true) {}
                railButton(tr("Live"), "tv.fill") { onLive() }
                railButton(tr("Movies"), "film.fill") { onMovies() }
                railButton(tr("Series"), "rectangle.stack.fill") { onSeries() }
                railButton(tr("Watch Later"), "clock.fill") { onWatchLater() }
                railButton(tr("Playlist"), "arrow.left.arrow.right") { onSwitchPlaylist() }
                railButton(tr("Support"), "questionmark.circle.fill") { showSupport = true }
                ZStack(alignment: .topTrailing) {
                    railButton(tr("Alerts"), "bell.fill") {
                        showNotifs = true; NotificationStore.markAllRead(notifications); unread = 0
                    }
                    if unread > 0 { Circle().fill(Color.hotRed).frame(width: 9, height: 9).padding(.top, 8).padding(.trailing, 20) }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 92)
    }

    private func railButton(_ label: String, _ system: String, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: system).font(.system(size: 22))
                    .foregroundStyle(selected ? Color.hotRed : Color.textSecondary)
                Text(label).font(.caption2).foregroundStyle(selected ? .white : Color.textSecondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 9)
            .background(selected ? Color.hotRed.opacity(0.14) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            let bg = featuredInfo?.backdrop ?? featuredInfo?.poster ?? featured?.poster
            RemoteImage(url: bg, contentMode: .fill) { LinearGradient.brandPanel }
                .frame(height: 210).frame(maxWidth: .infinity).clipped()
            LinearGradient(colors: [.clear, .darkBg], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.darkBg.opacity(0.9), .clear], startPoint: .leading, endPoint: .trailing)

            VStack(alignment: .trailing) {
                HStack(spacing: 10) {
                    Spacer()
                    headerIcon("arrow.clockwise") { Task { await refreshAll() } }
                    headerIcon("magnifyingglass", action: onSearch)
                    headerIcon("gearshape.fill", action: onSettings)
                    headerIcon("person.crop.circle", action: onAccount)
                }
                .padding(16)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if let info = featuredInfo, !info.genres.isEmpty {
                        Text(info.genres.prefix(2).joined(separator: " · ")).font(.caption.bold()).foregroundStyle(Color.hotRed)
                    }
                    if let r = featuredInfo?.rating, r > 0 {
                        Text("   ★ \(String(format: "%.1f", r))").font(.caption.bold()).foregroundStyle(Color(hex: 0xF1C40F))
                    }
                    if let y = featuredInfo?.year, !y.isEmpty {
                        Text("   \(y)").font(.caption).foregroundStyle(Color.textSecondary)
                    }
                }
                Text(featured?.name ?? "Welcome").font(.title2.bold()).foregroundStyle(.white).lineLimit(2)
                if let o = featuredInfo?.overview, !o.isEmpty {
                    Text(o).font(.footnote).foregroundStyle(Color.textSecondary).lineLimit(2)
                }
                if let item = featured {
                    Button { onOpenMovie(item) } label: {
                        HStack { Image(systemName: "play.fill"); Text("  " + tr("Play")).fontWeight(.bold) }
                            .foregroundStyle(.white).padding(.horizontal, 20).padding(.vertical, 8)
                            .background(Color.hotRed).clipShape(Capsule())
                    }
                    .padding(.top, 10)
                }
            }
            .frame(maxWidth: 420, alignment: .leading)
            .padding(.leading, 24).padding(.bottom, 16).padding(.trailing, 16)
        }
        .frame(height: 210)
    }

    private func headerIcon(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system).foregroundStyle(.white).frame(width: 40, height: 40)
                .background(Color.black.opacity(0.35)).clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 2).fill(Color.hotRed).frame(width: 4, height: 18)
                Text(title).font(.headline).foregroundStyle(.white)
            }
            .padding(.leading, 16)
            content()
        }
        .padding(.vertical, 10)
    }

    private func continueCard(_ item: HistoryItem, _ progress: Double) -> some View {
        Button { onPlay(item.url, item.name, item.streamId) } label: {
            VStack(alignment: .leading, spacing: 3) {
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(url: item.poster, contentMode: item.kind == .live ? .fit : .fill) {
                        ZStack { Color.darkSurface2; Text(String(item.name.prefix(1)).uppercased()).foregroundStyle(.white) }
                    }
                    .frame(width: item.kind == .live ? 210 : 100, height: 150).clipped()
                    if progress > 0 && item.kind != .live {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Color.black.opacity(0.5)
                                Color.hotRed.frame(width: geo.size.width * progress)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(item.name).font(.caption2).foregroundStyle(.white).lineLimit(1)
                    .frame(width: item.kind == .live ? 210 : 100, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func newVodCard(_ item: VodItem) -> some View {
        Button { onOpenMovie(item) } label: {
            VStack(alignment: .leading, spacing: 3) {
                RemoteImage(url: item.poster, contentMode: .fill) {
                    ZStack { Color.darkSurface2; Text(String(item.name.prefix(1)).uppercased()).foregroundStyle(.white) }
                }
                .frame(width: 110, height: 166).clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(item.name).font(.caption2).foregroundStyle(.white).lineLimit(1).frame(width: 110, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private func reloadContinue() {
        let recent = HistoryStore.recent().filter { $0.playlistId == repo.currentId }
        continueItems = recent.map { ($0, ResumeStore.progress($0.streamId)) }
    }

    private func loadFeatured() async {
        let candidates = newVod
        if candidates.isEmpty { featured = nil; featuredInfo = nil; return }
        for c in candidates.shuffled().prefix(12) {
            if let info = await TmdbClient.fetch(title: c.name, series: false),
               !(info.backdrop ?? "").isEmpty, !info.overview.isEmpty {
                featured = c; featuredInfo = info; return
            }
        }
        featured = candidates.first
        if let first = candidates.first { featuredInfo = await TmdbClient.fetch(title: first.name, series: false) }
    }

    private func refreshAll() async {
        await activation.refresh()
        await repo.refresh()
        reloadContinue()
        await loadFeatured()
    }
}
