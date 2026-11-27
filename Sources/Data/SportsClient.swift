import Foundation

/// Football fixtures by day from TheSportsDB, cached per day. Mirrors Android `SportsClient`.
enum SportsClient {
    private static let ttl: Int64 = 6 * 60 * 60 * 1000 // 6 hours
    private static let d = UserDefaults.standard
    private static func key() -> String { ApiKeys.sports.isEmpty ? "3" : ApiKeys.sports }

    static func eventsOn(date: String) async -> [SportEvent] {
        let cached = d.string(forKey: "hsu_sport_ev_\(date)")
        let ts = Int64(d.integer(forKey: "hsu_sport_ts_\(date)"))
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        if let cached, now - ts < ttl, let parsed = fromJson(cached) { return parsed }

        let fresh = await fetchRemote(date)
        if !fresh.isEmpty {
            d.set(toJson(fresh), forKey: "hsu_sport_ev_\(date)")
            d.set(now, forKey: "hsu_sport_ts_\(date)")
            return fresh
        }
        return fromJson(cached) ?? []
    }

    private static func fetchRemote(_ date: String) async -> [SportEvent] {
        guard let body = await Http.getString("https://www.thesportsdb.com/api/v1/json/\(key())/eventsday.php?d=\(date)&s=Soccer"),
              let arr = JSON.object(body)?.optArray("events") else { return [] }
        return arr.compactMap { $0 as? [String: Any] }.map { o in
            SportEvent(
                name: o.optString("strEvent"),
                league: o.optString("strLeague"),
                time: localTime(o.optString("dateEvent"), o.optString("strTime")),
                thumb: o.optString("strThumb").nonBlank,
                startMs: startMillis(o.optString("dateEvent"), o.optString("strTime"))
            )
        }.sorted { $0.time < $1.time }
    }

    private static func toJson(_ list: [SportEvent]) -> String {
        JSON.stringify(list.map { ["n": $0.name, "l": $0.league, "t": $0.time, "th": $0.thumb ?? "", "s": $0.startMs] })
    }

    private static func fromJson(_ s: String?) -> [SportEvent]? {
        guard let s, let arr = JSON.array(s) else { return nil }
        return arr.compactMap { $0 as? [String: Any] }.map { o in
            SportEvent(name: o.optString("n"), league: o.optString("l"), time: o.optString("t"),
                       thumb: o.optString("th").nonBlank, startMs: o.optLong("s"))
        }
    }

    private static func startMillis(_ date: String, _ time: String) -> Int64 {
        if date.isEmpty || time.isEmpty { return 0 }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return fmt.date(from: "\(date) \(time)").map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0
    }

    private static func localTime(_ date: String, _ time: String) -> String {
        if time.isEmpty { return "" }
        let inFmt = DateFormatter()
        inFmt.locale = Locale(identifier: "en_US_POSIX")
        inFmt.timeZone = TimeZone(identifier: "UTC")
        inFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let d = inFmt.date(from: "\(date) \(time)") {
            let out = DateFormatter(); out.dateFormat = "HH:mm"
            return out.string(from: d)
        }
        return String(time.prefix(5))
    }
}
