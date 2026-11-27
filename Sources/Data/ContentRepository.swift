import Foundation
import Combine

/// In-memory store for the currently open playlist (Live / Movies / Series + their
/// category lists), plus the 3-tier instant-load cache. Mirrors the Android
/// `ContentRepository` singleton; published properties drive the SwiftUI screens.
@MainActor
final class ContentRepository: ObservableObject {
    static let shared = ContentRepository()
    private init() {}

    @Published var live: [LiveChannel] = []
    @Published var movies: [VodItem] = []
    @Published var series: [VodItem] = []

    @Published var liveCategories: [Category] = []
    @Published var movieCategories: [Category] = []
    @Published var seriesCategories: [Category] = []

    @Published var sourceLabel = ""

    struct LoadProgress {
        var stage = ""
        var live = 0
        var movies = 0
        var series = 0
    }
    @Published var loadProgress = LoadProgress()

    /// The movie/series currently opened in a detail screen.
    var detailItem: VodItem?

    /// XMLTV EPG url for the current M3U playlist (nil for Xtream).
    var epgUrl: String?

    private(set) var xtream: XtreamClient?
    private var current: Playlist? {
        didSet { ContentRepository.currentPlaylistId = current?.id ?? "" }
    }

    /// Non-isolated mirror of the connected playlist id, so the per-playlist stores
    /// (which run off the main actor) can key their data without touching the actor.
    nonisolated(unsafe) static var currentPlaylistId: String = ""

    /// Id of the currently connected playlist (used to scope per-playlist stores).
    var currentId: String { current?.id ?? "" }

    // MARK: - Series play queue (powers the "next episode" prompt)
    struct PlayItem { let id: String; let title: String; let url: String }
    private(set) var playQueue: [PlayItem] = []
    private(set) var playIndex = 0

    func setSeriesQueue(_ items: [PlayItem], index: Int) {
        playQueue = items
        playIndex = min(max(index, 0), max(items.count - 1, 0))
    }

    func clearQueue() { playQueue = []; playIndex = 0 }

    func initApp() { Prefs.ensureDefaultParental() }

    /// Connect and load a saved playlist. Returns true on success.
    func connect(_ playlist: Playlist, force: Bool = false) async -> Bool {
        if !force, current?.id == playlist.id, !(live.isEmpty && movies.isEmpty && series.isEmpty) {
            loadProgress.stage = "done"
            return true
        }
        current = playlist
        loadProgress = LoadProgress()

        // Fast path: restore the last saved snapshot from disk.
        if !force, let snap = ContentCache.load(playlist.id),
           !(snap.live.isEmpty && snap.movies.isEmpty && snap.series.isEmpty) {
            applySnapshot(snap, playlist)
            loadProgress = LoadProgress(stage: "done", live: snap.live.count, movies: snap.movies.count, series: snap.series.count)
            return true
        }

        var ok = false
        switch playlist.type {
        case .xtream:
            let host = playlist.activeHostValue().isEmpty ? playlist.host : playlist.activeHostValue()
            let client = XtreamClient(rawHost: host, username: playlist.username, password: playlist.password)
            if await client.authenticate() {
                ExpiryStore.set(playlist.id, client.expiresAtMs)
                await loadFromXtream(client, label: playlist.name)
                ok = true
            }
        case .m3u:
            let active = playlist.activeHostValue()
            let effectiveUrl = active.isEmpty ? playlist.url : swapHost(playlist.url, active)
            if let xc = xtreamFromM3uUrl(effectiveUrl), await xc.authenticate() {
                ExpiryStore.set(playlist.id, xc.expiresAtMs)
                await loadFromXtream(xc, label: playlist.name)
                ok = true
            } else if let body = await Http.getString(effectiveUrl) {
                let parsed = M3uParser.parse(body)
                loadFromM3u(parsed, label: playlist.name)
                epgUrl = playlist.epgUrl.nonBlank ?? parsed.tvgUrl
                ok = !(live.isEmpty && movies.isEmpty && series.isEmpty)
            }
        case .website:
            ok = false
        }
        if ok { saveSnapshot(playlist) }
        return ok
    }

    func refresh() async {
        if let c = current { _ = await connect(c, force: true) }
    }

    /// Forget everything cached and loaded for a playlist (used after an EDIT).
    func forget(_ playlistId: String) {
        ContentCache.remove(playlistId)
        if current?.id == playlistId {
            current = nil
            setAll([], [], [])
            setCategories([], [], [])
            epgUrl = nil
            xtream = nil
        }
    }

    func clear() {
        setAll([], [], [])
        setCategories([], [], [])
        xtream = nil
        current = nil
        sourceLabel = ""
        epgUrl = nil
        Epg.shared.clear()
    }

    // MARK: - internals

    private func applySnapshot(_ snap: ContentCache.Snapshot, _ playlist: Playlist) {
        setAll(snap.live, snap.movies, snap.series)
        setCategories(snap.liveCats, snap.movieCats, snap.seriesCats)
        sourceLabel = snap.sourceLabel.isEmpty ? playlist.name : snap.sourceLabel
        epgUrl = snap.epgUrl
        xtream = snap.isXtream ? buildXtreamClient(playlist) : nil
    }

    private func saveSnapshot(_ playlist: Playlist) {
        ContentCache.save(playlist.id, ContentCache.Snapshot(
            sourceLabel: sourceLabel, epgUrl: epgUrl, isXtream: xtream != nil,
            live: live, movies: movies, series: series,
            liveCats: liveCategories, movieCats: movieCategories, seriesCats: seriesCategories))
    }

    private func buildXtreamClient(_ playlist: Playlist) -> XtreamClient? {
        switch playlist.type {
        case .xtream:
            let host = playlist.activeHostValue().isEmpty ? playlist.host : playlist.activeHostValue()
            return XtreamClient(rawHost: host, username: playlist.username, password: playlist.password)
        case .m3u:
            let active = playlist.activeHostValue()
            let effectiveUrl = active.isEmpty ? playlist.url : swapHost(playlist.url, active)
            return xtreamFromM3uUrl(effectiveUrl)
        default: return nil
        }
    }

    private func swapHost(_ url: String, _ newBase: String) -> String {
        guard var comps = URLComponents(string: url), let scheme = comps.scheme, let host = comps.host else { return url }
        let authority = "\(scheme)://\(host)\(comps.port.map { ":\($0)" } ?? "")"
        let base = newBase.lowercased().hasPrefix("http") ? newBase.trimmingTrailingSlash() : "http://\(newBase.trimmingTrailingSlash())"
        return url.replacingOccurrences(of: authority, with: base)
    }

    private func xtreamFromM3uUrl(_ url: String) -> XtreamClient? {
        guard let comps = URLComponents(string: url),
              let user = comps.queryItems?.first(where: { $0.name == "username" })?.value?.nonBlank,
              let pass = comps.queryItems?.first(where: { $0.name == "password" })?.value?.nonBlank,
              let host = comps.host else { return nil }
        let scheme = comps.scheme ?? "http"
        let port = comps.port.map { ":\($0)" } ?? ""
        return XtreamClient(rawHost: "\(scheme)://\(host)\(port)", username: user, password: pass)
    }

    private func loadFromXtream(_ client: XtreamClient, label: String) async {
        xtream = client
        sourceLabel = label
        epgUrl = nil
        // Sequential (not parallel): most lines allow only 1-2 connections.
        loadProgress = LoadProgress(stage: "categories")
        let liveCats = await client.getLiveCategories()
        let movieCats = await client.getVodCategories()
        let seriesCats = await client.getSeriesCategories()

        loadProgress.stage = "live"
        let liveList = await client.getLive()
        loadProgress = LoadProgress(stage: "movies", live: liveList.count)
        let movieList = await client.getMovies()
        loadProgress = LoadProgress(stage: "series", live: liveList.count, movies: movieList.count)
        let seriesList = await client.getSeries()

        setAll(liveList, movieList, seriesList)
        setCategories(
            augmentCategories(liveCats, liveList.map { $0.group }),
            augmentCategories(movieCats, movieList.map { $0.group }),
            augmentCategories(seriesCats, seriesList.map { $0.group }))
        loadProgress.stage = "done"
    }

    private func augmentCategories(_ serverCats: [Category], _ groups: [String?]) -> [Category] {
        var present: [String] = []
        var seen = Set<String>()
        for g in groups {
            let v = (g?.nonBlank) ?? UNCATEGORIZED
            if seen.insert(v).inserted { present.append(v) }
        }
        let presentSet = Set(present)
        if present.isEmpty { return [] }
        let knownNames = Dictionary(serverCats.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        var out: [Category] = []
        var added = Set<String>()
        for c in serverCats where presentSet.contains(c.id) {
            if added.insert(c.id).inserted { out.append(c) }
        }
        for g in present where added.insert(g).inserted {
            out.append(Category(id: g, name: knownNames[g] ?? g))
        }
        return out
    }

    private func loadFromM3u(_ playlist: ParsedPlaylist, label: String) {
        xtream = nil
        sourceLabel = label
        loadProgress = LoadProgress(stage: "done", live: playlist.live.count, movies: playlist.movies.count, series: playlist.series.count)
        setAll(playlist.live, playlist.movies, playlist.series)
        setCategories(
            categoriesFromGroups(playlist.live.map { $0.group }),
            categoriesFromGroups(playlist.movies.map { $0.group }),
            categoriesFromGroups(playlist.series.map { $0.group }))
    }

    private func categoriesFromGroups(_ groups: [String?]) -> [Category] {
        var seen = Set<String>()
        var out: [Category] = []
        for g in groups {
            let v = (g?.nonBlank) ?? UNCATEGORIZED
            if seen.insert(v).inserted { out.append(Category(id: v, name: v)) }
        }
        return out
    }

    private func setAll(_ l: [LiveChannel], _ m: [VodItem], _ s: [VodItem]) {
        live = l; movies = m; series = s
    }
    private func setCategories(_ l: [Category], _ m: [Category], _ s: [Category]) {
        liveCategories = l; movieCategories = m; seriesCategories = s
    }
}
