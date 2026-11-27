import Foundation

/// Accumulated watch time (screen time). Mirrors the Android `StatsStore`.
enum StatsStore {
    private static let d = UserDefaults.standard
    private static let key = "hsu_stats_watch_ms"

    static func addWatchMs(_ ms: Int64) {
        if ms <= 0 { return }
        d.set(totalWatchMs() + ms, forKey: key)
    }

    static func totalWatchMs() -> Int64 { Int64(d.integer(forKey: key)) }

    static func reset() { d.removeObject(forKey: key) }

    static func formatted() -> String {
        let totalSec = totalWatchMs() / 1000
        let h = totalSec / 3600
        let m = (totalSec % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}
