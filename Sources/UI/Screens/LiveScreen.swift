import SwiftUI
import AVKit

private enum LiveMode { case channels, favorites, folders }

/// Live TV: category/folder pane, channel list, and a preview player + EPG +
/// catch-up. Mirrors Android `LiveScreen`. `onFullscreenPlay` is used for catch-up.
struct LiveScreen: View {
    let onFullscreenPlay: (String, String) -> Void

    @EnvironmentObject var repo: ContentRepository
    @StateObject private var player = VlcPlayerController()      // shared preview + fullscreen

    @State private var mode: LiveMode = .channels
    @State private var searchOpen = false
    @State private var query = ""
    @State private var selectedCat: String?
    @State private var selectedFolder: String?

    @State private var cur: LiveChannel?
    @State private var fullscreen = false
    @State private var showFavDialog = false
    @State private var epg: [EpgEntry] = []
    @State private var unlocked: Set<String> = []
    @State private var pendingCat: Category?
    @State private var folders: [FavFolder] = []
    @State private var favLive: [FavItem] = []
    @State private var refreshTick = 0
    @State private var showCatchup = false
    @State private var catchupList: [EpgProgramme]?
    @State private var catchupLoading = false

    private var isXtream: Bool { repo.xtream != nil }

    private struct Row: Identifiable { let id: String; let name: String; let url: String; let logo: String?; let group: String?; let tvgId: String?; let archive: Bool }

    private var rows: [Row] {
        switch mode {
        case .channels:
            return repo.live.filter { ch in
                let g = ch.group?.nonBlank ?? UNCATEGORIZED
                return (selectedCat == nil || g == selectedCat) && (query.isEmpty || ch.name.range(of: query, options: .caseInsensitive) != nil)
            }.map { Row(id: $0.id, name: $0.name, url: $0.url, logo: $0.logo, group: $0.group, tvgId: $0.tvgId, archive: $0.archive) }
        case .favorites:
            return dedup(favLive).filter { query.isEmpty || $0.name.range(of: query, options: .caseInsensitive) != nil }
                .map { Row(id: $0.streamId, name: $0.name, url: $0.url, logo: $0.poster, group: $0.group, tvgId: nil, archive: false) }
        case .folders:
            return favLive.filter { $0.folderId == selectedFolder && (query.isEmpty || $0.name.range(of: query, options: .caseInsensitive) != nil) }
                .map { Row(id: $0.streamId, name: $0.name, url: $0.url, logo: $0.poster, group: $0.group, tvgId: nil, archive: false) }
        }
    }

    private var curIsFav: Bool {
        guard let id = cur?.id else { return false }
        return FavoritesStore.foldersContaining(.live, id).contains(FavoritesStore.defaultFolderId)
    }

    var body: some View {
        Group {
            if repo.live.isEmpty {
                EmptyStateView(tr("No live channels in this playlist."))
            } else {
                content
            }
        }
        .background(Color.darkBg)
        .fullScreenCover(isPresented: $fullscreen) { fullscreenPlayer }
        .appDialog(isPresented: $showFavDialog) {
            if let c = cur {
                FavoriteDialog(kind: .live, streamId: c.id, name: c.name, poster: c.logo, url: c.url, group: c.group) {
                    showFavDialog = false; refreshTick += 1
                }
            }
        }
        .appDialog(item: $pendingCat) { cat in
            PinDialog(onDismiss: { pendingCat = nil }, onSuccess: { unlocked.insert(cat.id); selectedCat = cat.id; pendingCat = nil })
        }
        .appDialog(isPresented: $showCatchup) { catchupDialog }
        .task { setup() }
        .onChange(of: cur?.id) { _ in loadEpgAndPreview() }
        .onDisappear { player.teardown() }
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button { searchOpen.toggle() } label: { Image(systemName: "magnifyingglass").foregroundStyle(.white) }
                topChip(tr("Live"), mode == .channels) { mode = .channels }
                topChip(tr("Favorites"), mode == .favorites) { mode = .favorites }
                topChip(tr("Folders"), mode == .folders) { mode = .folders }
                Spacer()
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(Color.darkSurface)
            if searchOpen { SearchField(query: $query).padding(.horizontal, 8).padding(.vertical, 4) }

            // Three columns that all stay visible: categories (fixed) | channel
            // names (flexible) | preview + guide (flexible).
            HStack(spacing: 0) {
                leftPane.frame(width: 138)
                Divider().background(Color.dividerColor)
                middlePane.frame(width: 192)
                Divider().background(Color.dividerColor)
                // Preview + guide take all remaining width, so the video is bigger.
                rightPane.frame(maxWidth: .infinity)
            }
        }
    }

    private var leftPane: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch mode {
                case .channels:
                    menuRow(tr("All"), selectedCat == nil) { selectedCat = nil }
                    ForEach(repo.liveCategories) { c in
                        menuRow(c.name, selectedCat == c.id) {
                            if isLockedCategory(c.name) && !unlocked.contains(c.id) { pendingCat = c } else { selectedCat = c.id }
                        }
                    }
                case .folders:
                    ForEach(folders) { f in menuRow(f.name, selectedFolder == f.id) { selectedFolder = f.id } }
                case .favorites:
                    Text("Favorites").font(.caption).foregroundStyle(Color.textSecondary).padding()
                }
            }
        }
        .background(Color.darkSurface)
    }

    private var middlePane: some View {
        Group {
            if rows.isEmpty {
                Text("Empty").foregroundStyle(Color.textSecondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(rows) { row in channelRow(row) }
                    }
                }
            }
        }
        .background(Color.darkSurface)
    }

    private var rightPane: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Color.black
                VlcPlayerView(controller: player, active: !fullscreen)
                HStack(spacing: 16) {
                    ctrlButton(curIsFav ? "heart.fill" : "heart", tint: .hotRed) { toggleFav() }
                    ctrlButton("folder.badge.plus") { if cur != nil { showFavDialog = true } }
                    if isXtream, cur?.archive == true { ctrlButton("clock.arrow.circlepath") { loadCatchup() } }
                    ctrlButton("arrow.clockwise") { reloadPreview() }
                    ctrlButton("arrow.up.left.and.arrow.down.right") { fullscreen = true }
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .top, endPoint: .bottom))
            }
            .aspectRatio(16.0/9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.hotRed.opacity(0.55), lineWidth: 2))
            .padding(6)

            epgPanel.frame(height: 140)
        }
    }

    private var epgPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2).fill(Color.hotRed).frame(width: 4, height: 15)
                Text(tr("Program Guide")).font(.subheadline.bold()).foregroundStyle(.white)
            }
            if !epg.isEmpty {
                let nowItem = epg.first { $0.nowPlaying }
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let n = nowItem { epgNowCard(n) }
                        let upcoming = epg.filter { $0 != nowItem }
                        if !upcoming.isEmpty {
                            Text(tr("UP NEXT")).font(.caption.bold()).foregroundStyle(Color.textSecondary).padding(.top, 12)
                            ForEach(Array(upcoming.enumerated()), id: \.offset) { _, e in epgRow(e) }
                        }
                    }
                }
            } else {
                Text(!isXtream && repo.epgUrl == nil ? "No EPG source in this playlist." : "No EPG data for this channel.")
                    .font(.footnote).foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(cornerRadius: 0, alpha: 0.5, border: false)
    }

    private func epgNowCard(_ e: EpgEntry) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text("● NOW").font(.caption2.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Color.hotRed).clipShape(RoundedRectangle(cornerRadius: 6))
                Text("\(e.start) – \(e.end)").font(.caption.bold()).foregroundStyle(Color.hotRed)
            }
            Text(e.title).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(2)
            if !e.description.isEmpty { Text(e.description).font(.footnote).foregroundStyle(Color.textSecondary).lineLimit(3) }
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.hotRed.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func epgRow(_ e: EpgEntry) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(e.start).font(.caption.bold()).foregroundStyle(Color.hotRed.opacity(0.9)).frame(width: 46, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(e.title).font(.footnote).foregroundStyle(.white).lineLimit(2)
                if !e.description.isEmpty { Text(e.description).font(.caption).foregroundStyle(Color.textSecondary).lineLimit(1) }
            }
        }
        .padding(.vertical, 7)
    }

    private var catchupDialog: some View {
        AppDialogCard(title: "\(tr("Catch-up")) • \(cur?.name ?? "")", dismissText: tr("Close"), onDismiss: { showCatchup = false }) {
            if catchupLoading {
                HStack { ProgressView().tint(.hotRed); Text("  Loading…").foregroundStyle(.white) }
            } else if (catchupList ?? []).isEmpty {
                Text("No catch-up available for this channel.").foregroundStyle(.white)
            } else {
                ForEach(Array((catchupList ?? []).enumerated()), id: \.offset) { _, p in
                    Button {
                        if let id = cur?.id, let xc = repo.xtream {
                            let u = xc.catchupUrl(streamId: id, programme: p)
                            showCatchup = false
                            onFullscreenPlay(u, "\(cur?.name ?? "") • \(p.title)")
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.title.isEmpty ? "Programme" : p.title).fontWeight(.bold).foregroundStyle(.white).lineLimit(1)
                            Text(catchupTime(p.startMs)).font(.caption).foregroundStyle(Color.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var fullscreenPlayer: some View {
        // Same running player — the video surface just moves here instantly.
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            VlcPlayerView(controller: player, active: true).ignoresSafeArea()
            Button { fullscreen = false } label: {
                Image(systemName: "arrow.left").font(.title3).foregroundStyle(.white)
                    .frame(width: 44, height: 44).background(Color.black.opacity(0.4), in: Circle()).padding(16)
            }
        }
    }

    // MARK: rows & chips

    private func topChip(_ label: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.caption.weight(selected ? .bold : .medium))
                .foregroundStyle(selected ? .white : Color.textSecondary)
                .padding(.horizontal, 16).padding(.vertical, 7)
                .background(selected ? Color.hotRed : Color.darkSurface2.opacity(0.45))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func menuRow(_ name: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name).font(.footnote).fontWeight(selected ? .bold : .regular)
                .foregroundStyle(selected ? Color.hotRed : .white).lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(selected ? Color.hotRed.opacity(0.18) : .clear)
        }
        .buttonStyle(.plain)
        .overlay(Divider().background(Color.white.opacity(0.06)), alignment: .bottom)
    }

    private func channelRow(_ row: Row) -> some View {
        let selected = cur?.id == row.id
        return Button {
            if selected { fullscreen = true } else { selectRow(row) }
        } label: {
            HStack {
                Text(row.name).font(.footnote).fontWeight(selected ? .bold : .regular)
                    .foregroundStyle(selected ? Color.hotRed : .white).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                if row.archive {
                    // Clean catch-up badge on channels that support it.
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.hotRed)
                        .padding(4)
                        .background(Color.hotRed.opacity(0.15), in: Circle())
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 4)
            .background(selected ? Color.hotRed.opacity(0.18) : .clear)
        }
        .buttonStyle(.plain)
        .overlay(Divider().background(Color.white.opacity(0.06)), alignment: .bottom)
    }

    private func ctrlButton(_ system: String, tint: Color = .white, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system).font(.system(size: 20)).foregroundStyle(tint)
                .frame(width: 46, height: 46).glass(cornerRadius: 23, alpha: 0.45)
        }
        .buttonStyle(.plain)
    }

    // MARK: actions

    private func setup() {
        folders = FavoritesStore.folders()
        favLive = FavoritesStore.items().filter { $0.kind == .live }
        if mode == .folders && selectedFolder == nil { selectedFolder = folders.first?.id }
        if cur == nil, let first = repo.live.first { selectRow(Row(id: first.id, name: first.name, url: first.url, logo: first.logo, group: first.group, tvgId: first.tvgId, archive: first.archive)) }
        Task {
            if !isXtream, let url = repo.epgUrl, !Epg.shared.isLoadedFor(url) {
                await Epg.shared.load(url)
                loadEpgAndPreview()
            }
        }
    }

    private func selectRow(_ row: Row) {
        cur = LiveChannel(id: row.id, name: row.name, logo: row.logo, group: row.group, url: row.url, tvgId: row.tvgId, archive: row.archive)
        HistoryStore.record(HistoryItem(kind: .live, streamId: row.id, name: row.name, poster: row.logo, url: row.url, group: row.group))
    }

    private func loadEpgAndPreview() {
        guard let c = cur else { return }
        player.load(url: c.url)
        Task {
            if isXtream { epg = await repo.xtream?.getShortEpg(streamId: c.id) ?? [] }
            else { epg = Epg.shared.forChannel(c.tvgId) }
        }
    }

    private func reloadPreview() { if let c = cur { player.load(url: c.url) } }

    private func toggleFav() {
        guard let c = cur else { return }
        if curIsFav { FavoritesStore.removeFrom(FavoritesStore.defaultFolderId, .live, c.id) }
        else { FavoritesStore.addTo(FavoritesStore.defaultFolderId, FavItem(folderId: FavoritesStore.defaultFolderId, kind: .live, streamId: c.id, name: c.name, poster: c.logo, url: c.url, group: c.group)) }
        refreshTick += 1
    }

    private func loadCatchup() {
        guard let id = cur?.id else { return }
        catchupLoading = true; showCatchup = true
        Task {
            catchupList = await repo.xtream?.getArchiveEpg(streamId: id) ?? []
            catchupLoading = false
        }
    }

    private func dedup(_ list: [FavItem]) -> [FavItem] {
        var seen = Set<String>(); return list.filter { seen.insert($0.streamId).inserted }
    }

    private func catchupTime(_ ms: Int64) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE dd MMM • HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }
}
