import Foundation

/// Minimal Xtream Codes API client (mirrors the Android `XtreamClient`).
/// Endpoint shape:  {host}/player_api.php?username=..&password=..&action=..
/// Stream URLs:     {host}/live|movie|series/{user}/{pass}/{id}.{ext}
final class XtreamClient {
    let host: String
    let username: String
    let password: String
    private let api: String

    /// This line's expiry (epoch ms), captured on authenticate(); nil = never expires.
    private(set) var expiresAtMs: Int64?

    init(rawHost: String, username: String, password: String) {
        self.host = XtreamClient.normalize(rawHost)
        self.username = username
        self.password = password
        self.api = "\(self.host)/player_api.php?username=\(username.urlEncoded)&password=\(password.urlEncoded)"
    }

    func authenticate() async -> Bool {
        guard let body = await Http.getString(api),
              let info = JSON.object(body)?.optObject("user_info") else { return false }
        let auth = JSON.string(info["auth"])
        let status = info.optString("status")
        let ok = auth == "1" || status.caseInsensitiveCompare("Active") == .orderedSame
        if ok {
            if !info.isNull("exp_date") {
                if let secs = Int64(info.optString("exp_date")), secs > 0 {
                    expiresAtMs = secs * 1000
                }
            }
        }
        return ok
    }

    func getLive() async -> [LiveChannel] {
        guard let body = await Http.getString("\(api)&action=get_live_streams") else { return [] }
        return parseArray(body) { o in
            let id = o.optString("stream_id")
            return LiveChannel(
                id: id,
                name: o.optString("name"),
                logo: o.optString("stream_icon").nonBlank,
                group: o.optString("category_id"),
                // Canonical Xtream live format. VLC (the live player) decodes MPEG-TS
                // natively, so we use the always-available .ts endpoint.
                url: "\(host)/live/\(username.urlEncoded)/\(password.urlEncoded)/\(id).ts",
                tvgId: nil,
                archive: o.optInt("tv_archive") == 1 || o.optInt("tv_archive_duration") > 0
            )
        }
    }

    func getMovies() async -> [VodItem] {
        guard let body = await Http.getString("\(api)&action=get_vod_streams") else { return [] }
        return parseArray(body) { o in
            let id = o.optString("stream_id")
            let ext = o.optString("container_extension").ifBlank("mp4")
            return VodItem(
                id: id,
                name: o.optString("name"),
                poster: o.optString("stream_icon").nonBlank,
                group: o.optString("category_id"),
                url: "\(host)/movie/\(username.urlEncoded)/\(password.urlEncoded)/\(id).\(ext)",
                type: .movie
            )
        }
    }

    func getSeries() async -> [VodItem] {
        guard let body = await Http.getString("\(api)&action=get_series") else { return [] }
        return parseArray(body) { o in
            VodItem(
                id: o.optString("series_id"),
                name: o.optString("name"),
                poster: o.optString("cover").nonBlank,
                group: o.optString("category_id"),
                url: "",
                type: .series
            )
        }
    }

    func getLiveCategories() async -> [Category] { await categories("get_live_categories") }
    func getVodCategories() async -> [Category] { await categories("get_vod_categories") }
    func getSeriesCategories() async -> [Category] { await categories("get_series_categories") }

    private func categories(_ action: String) async -> [Category] {
        guard let body = await Http.getString("\(api)&action=\(action)") else { return [] }
        return parseArray(body) { o in
            Category(id: o.optString("category_id"), name: o.optString("category_name").ifBlank("Category"))
        }
    }

    func getEpisodes(seriesId: String) async -> [Episode] {
        guard let body = await Http.getString("\(api)&action=get_series_info&series_id=\(seriesId)"),
              let episodes = JSON.object(body)?.optObject("episodes") else { return [] }
        var out: [Episode] = []
        for (season, value) in episodes {
            guard let arr = value as? [Any] else { continue }
            let seasonNum = Int(season) ?? 0
            for (k, e0) in arr.enumerated() {
                guard let e = e0 as? [String: Any] else { continue }
                let id = e.optString("id")
                let ext = e.optString("container_extension").ifBlank("mp4")
                let epNum = Int(e.optString("episode_num")) ?? (k + 1)
                let title = e.optString("title").ifBlank("Season \(season) • Ep \(epNum)")
                let meta = e.optObject("info")
                out.append(Episode(
                    id: id,
                    title: title,
                    url: "\(host)/series/\(username.urlEncoded)/\(password.urlEncoded)/\(id).\(ext)",
                    season: seasonNum,
                    episodeNum: epNum,
                    plot: meta?.optString("plot") ?? "",
                    cover: meta?.optString("movie_image") ?? ""
                ))
            }
        }
        return out
    }

    func getShortEpg(streamId: String) async -> [EpgEntry] {
        guard let body = await Http.getString("\(api)&action=get_short_epg&stream_id=\(streamId)&limit=12"),
              let arr = JSON.object(body)?.optArray("epg_listings") else { return [] }
        return arr.compactMap { $0 as? [String: Any] }.map { o in
            EpgEntry(
                title: decodeMaybeBase64(o.optString("title")),
                start: formatEpgTime(o.optString("start")),
                end: formatEpgTime(o.optString("end")),
                description: decodeMaybeBase64(o.optString("description")),
                nowPlaying: o.optInt("now_playing") == 1
            )
        }
    }

    /// Past programmes for a channel's archive (catch-up), newest first.
    func getArchiveEpg(streamId: String) async -> [EpgProgramme] {
        guard let body = await Http.getString("\(api)&action=get_simple_data_table&stream_id=\(streamId)"),
              let arr = JSON.object(body)?.optArray("epg_listings") else { return [] }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return arr.compactMap { $0 as? [String: Any] }.compactMap { o -> EpgProgramme? in
            let startSec = Int64(o.optString("start_timestamp")) ?? 0
            let stopSec = Int64(o.optString("stop_timestamp")) ?? 0
            if startSec <= 0 || stopSec <= 0 || stopSec * 1000 > now { return nil }
            return EpgProgramme(
                title: decodeMaybeBase64(o.optString("title")),
                desc: decodeMaybeBase64(o.optString("description")),
                startMs: startSec * 1000,
                stopMs: stopSec * 1000
            )
        }.sorted { $0.startMs > $1.startMs }.prefix(80).map { $0 }
    }

    /// Timeshift URL for a past programme.
    func catchupUrl(streamId: String, programme: EpgProgramme) -> String {
        let durationMin = max((programme.stopMs - programme.startMs) / 60000, 1)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = "yyyy-MM-dd:HH-mm"
        let start = fmt.string(from: Date(timeIntervalSince1970: Double(programme.startMs) / 1000))
        return "\(host)/timeshift/\(username.urlEncoded)/\(password.urlEncoded)/\(durationMin)/\(start)/\(streamId).ts"
    }

    // MARK: - helpers

    private func decodeMaybeBase64(_ s: String) -> String {
        if s.isEmpty { return "" }
        if let d = Data(base64Encoded: s), let decoded = String(data: d, encoding: .utf8), !decoded.isEmpty {
            return decoded
        }
        return s
    }

    private func formatEpgTime(_ s: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = parser.date(from: s) {
            let out = DateFormatter()
            out.dateFormat = "HH:mm"
            return out.string(from: date)
        }
        if s.count >= 16 {
            let start = s.index(s.startIndex, offsetBy: 11)
            let end = s.index(s.startIndex, offsetBy: 16)
            return String(s[start..<end])
        }
        return s
    }

    private func parseArray<T>(_ body: String, _ map: ([String: Any]) -> T) -> [T] {
        guard let arr = JSON.array(body) else { return [] }
        return arr.compactMap { $0 as? [String: Any] }.map(map)
    }

    static func normalize(_ raw: String) -> String {
        var h = raw.trimmingCharacters(in: .whitespaces)
        while h.hasSuffix("/") { h.removeLast() }
        let lower = h.lowercased()
        if !lower.hasPrefix("http://") && !lower.hasPrefix("https://") { h = "http://\(h)" }
        return h
    }
}
