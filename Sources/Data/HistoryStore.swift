import Foundation

struct HistoryItem: Identifiable, Hashable {
    var id: String { "\(kind.rawValue)_\(streamId)" }
    let kind: MediaKind
    let streamId: String
    let name: String
    let poster: String?
    let url: String
    let group: String?
    var playlistId: String = ""
}

/// Recently watched (Live / Movies / Series). Newest first, capped at MAX,
/// fully isolated per playlist. Mirrors the Android `HistoryStore`.
enum HistoryStore {
    private static let d = UserDefaults.standard
    private static let MAX = 20
    private static func key(_ playlistId: String) -> String { "hsu_history_recent_\(playlistId)" }

    static func recent() -> [HistoryItem] { read(key(ContentRepository.currentPlaylistId)) }

    static func record(_ item: HistoryItem) {
        if item.url.isEmpty { return }
        let pid = item.playlistId.isEmpty ? ContentRepository.currentPlaylistId : item.playlistId
        if pid.isEmpty { return }
        var tagged = item; tagged.playlistId = pid
        let existing = read(key(pid)).filter { !($0.kind == tagged.kind && $0.streamId == tagged.streamId) }
        let updated = Array(([tagged] + existing).prefix(MAX))
        d.set(serialize(updated), forKey: key(pid))
    }

    static func clear(_ playlistId: String = ContentRepository.currentPlaylistId) {
        d.removeObject(forKey: key(playlistId))
    }

    private static func read(_ k: String) -> [HistoryItem] {
        guard let raw = d.string(forKey: k), let arr = JSON.array(raw) else { return [] }
        return arr.compactMap { $0 as? [String: Any] }.map { o in
            HistoryItem(
                kind: MediaKind(rawValue: o.optString("kind")) ?? .live,
                streamId: o.optString("streamId"),
                name: o.optString("name"),
                poster: o.optString("poster").nonBlank,
                url: o.optString("url"),
                group: o.optString("group").nonBlank,
                playlistId: o.optString("playlistId")
            )
        }
    }

    private static func serialize(_ items: [HistoryItem]) -> String {
        let arr = items.map { i in
            ["kind": i.kind.rawValue, "streamId": i.streamId, "name": i.name,
             "poster": i.poster ?? "", "url": i.url, "group": i.group ?? "", "playlistId": i.playlistId]
        }
        return JSON.stringify(arr)
    }
}
