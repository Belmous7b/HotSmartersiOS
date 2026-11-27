import Foundation

/// Remembers playback position (ms) per movie/episode so the user can resume.
/// Scoped to the current playlist. Mirrors the Android `ResumeStore`.
enum ResumeStore {
    private static let d = UserDefaults.standard
    private static func k(_ id: String) -> String { "\(ContentRepository.currentPlaylistId)|\(id)" }

    static func save(_ id: String, positionMs: Int64, durationMs: Int64) {
        if id.isEmpty || positionMs <= 0 { return }
        if durationMs > 0 && positionMs >= durationMs - 5000 { clear(id); return }
        if positionMs < 10_000 { return }
        d.set(positionMs, forKey: "hsu_resume_p_\(k(id))")
        d.set(durationMs, forKey: "hsu_resume_d_\(k(id))")
    }

    static func position(_ id: String) -> Int64 {
        id.isEmpty ? 0 : Int64(d.integer(forKey: "hsu_resume_p_\(k(id))"))
    }

    static func duration(_ id: String) -> Int64 {
        id.isEmpty ? 0 : Int64(d.integer(forKey: "hsu_resume_d_\(k(id))"))
    }

    /// 0...1 watched fraction, or 0 if unknown.
    static func progress(_ id: String) -> Double {
        let dur = duration(id)
        if dur <= 0 { return 0 }
        return min(max(Double(position(id)) / Double(dur), 0), 1)
    }

    static func clear(_ id: String) {
        d.removeObject(forKey: "hsu_resume_p_\(k(id))")
        d.removeObject(forKey: "hsu_resume_d_\(k(id))")
    }
}
