import Foundation

/// Remembers each playlist's own subscription expiry (from the Xtream line's
/// exp_date). Per playlist id. nil = unknown, 0 = never expires, positive = epoch ms.
enum ExpiryStore {
    private static let d = UserDefaults.standard
    private static func key(_ id: String) -> String { "hsu_expiry_\(id)" }

    static func set(_ playlistId: String, _ expiresAtMs: Int64?) {
        if playlistId.isEmpty { return }
        d.set(expiresAtMs ?? 0, forKey: key(playlistId))
    }

    static func get(_ playlistId: String) -> Int64? {
        if playlistId.isEmpty || d.object(forKey: key(playlistId)) == nil { return nil }
        return Int64(d.integer(forKey: key(playlistId)))
    }

    static func remove(_ playlistId: String) { d.removeObject(forKey: key(playlistId)) }
}
