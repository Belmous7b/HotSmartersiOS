import Foundation

/// On-disk snapshot of a loaded playlist, so reopening restores instantly instead
/// of refetching. Mirrors the Android `ContentCache` (uses Codable JSON on iOS).
enum ContentCache {
    struct Snapshot: Codable {
        let sourceLabel: String
        let epgUrl: String?
        let isXtream: Bool
        let live: [LiveChannel]
        let movies: [VodItem]
        let series: [VodItem]
        let liveCats: [Category]
        let movieCats: [Category]
        let seriesCats: [Category]
    }

    private static func dir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    /// Deterministic hash (djb2) — String.hashValue is randomized per process and
    /// would change the filename every launch, defeating the disk cache.
    private static func stableHash(_ s: String) -> UInt64 {
        var h: UInt64 = 5381
        for b in s.utf8 { h = (h &* 33) &+ UInt64(b) }
        return h
    }

    private static func file(_ id: String) -> URL {
        dir().appendingPathComponent("content_\(stableHash(id)).json")
    }

    static func save(_ id: String, _ s: Snapshot) {
        guard let data = try? JSONEncoder().encode(s) else { return }
        try? data.write(to: file(id))
    }

    static func load(_ id: String) -> Snapshot? {
        guard let data = try? Data(contentsOf: file(id)) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    static func remove(_ id: String) {
        try? FileManager.default.removeItem(at: file(id))
    }
}
