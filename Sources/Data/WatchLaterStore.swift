import Foundation

/// One saved "Watch Later" title. A MOVIE keeps its direct play url; a SERIES
/// keeps only its streamId (url blank) so the list opens the series page.
struct WatchLaterItem: Identifiable, Hashable {
    var id: String { "\(kind.rawValue)_\(streamId)" }
    let kind: MediaKind
    let streamId: String
    let name: String
    let poster: String?
    let url: String
    let group: String?
}

/// "Watch Later" — titles saved for another time. Per playlist, newest first.
enum WatchLaterStore {
    private static let d = UserDefaults.standard
    private static var hasPlaylist: Bool { !ContentRepository.currentPlaylistId.isEmpty }
    private static func key() -> String { "hsu_watch_later_\(ContentRepository.currentPlaylistId)" }

    static func items() -> [WatchLaterItem] {
        guard hasPlaylist, let raw = d.string(forKey: key()), let arr = JSON.array(raw) else { return [] }
        return arr.compactMap { $0 as? [String: Any] }.map { o in
            WatchLaterItem(
                kind: MediaKind(rawValue: o.optString("kind")) ?? .movie,
                streamId: o.optString("streamId"),
                name: o.optString("name"),
                poster: o.optString("poster").nonBlank,
                url: o.optString("url"),
                group: o.optString("group").nonBlank
            )
        }
    }

    private static func save(_ items: [WatchLaterItem]) {
        guard hasPlaylist else { return }
        let arr = items.map { i in
            ["kind": i.kind.rawValue, "streamId": i.streamId, "name": i.name,
             "poster": i.poster ?? "", "url": i.url, "group": i.group ?? ""]
        }
        d.set(JSON.stringify(arr), forKey: key())
    }

    static func contains(_ kind: MediaKind, _ streamId: String) -> Bool {
        items().contains { $0.kind == kind && $0.streamId == streamId }
    }

    static func add(_ item: WatchLaterItem) {
        if contains(item.kind, item.streamId) { return }
        save([item] + items())
    }

    static func remove(_ kind: MediaKind, _ streamId: String) {
        save(items().filter { !($0.kind == kind && $0.streamId == streamId) })
    }

    /// Add if missing, remove if present. Returns true if now saved.
    @discardableResult
    static func toggle(_ item: WatchLaterItem) -> Bool {
        if contains(item.kind, item.streamId) { remove(item.kind, item.streamId); return false }
        add(item); return true
    }
}
