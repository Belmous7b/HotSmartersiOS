import Foundation

/// Fetches rich metadata (poster, overview, rating, year, genres, trailer) from
/// TMDB. Mirrors the Android `TmdbClient`. Results are cached in-memory.
enum TmdbClient {
    private static let img = "https://image.tmdb.org/t/p/"
    private static var cache: [String: TmdbInfo] = [:]

    static func fetch(title: String, series: Bool) async -> TmdbInfo? {
        let key = ApiKeys.tmdb
        if key.isEmpty { return nil }
        let query = clean(title)
        if query.isEmpty { return nil }
        let cacheKey = "\(series ? "tv" : "movie")|\(title)"
        if let hit = cache[cacheKey] { return hit }

        let type = series ? "tv" : "movie"
        let year = extractYear(title)
        guard let id = await searchId(key: key, type: type, query: query, year: year, series: series) else { return nil }

        guard let body = await Http.getString("https://api.themoviedb.org/3/\(type)/\(id)?api_key=\(key)&append_to_response=videos"),
              let o = JSON.object(body) else { return nil }

        let date = o.optString(series ? "first_air_date" : "release_date")
        let genres = (o.optArray("genres") ?? []).compactMap { ($0 as? [String: Any])?.optString("name") }
        var trailer: String? = nil
        if let results = o.optObject("videos")?.optArray("results") {
            trailer = results.compactMap { $0 as? [String: Any] }
                .first { $0.optString("site") == "YouTube" && $0.optString("type") == "Trailer" }?
                .optString("key").nonBlank
        }

        let info = TmdbInfo(
            poster: o.optString("poster_path").nonBlank.map { "\(img)w500\($0)" },
            backdrop: o.optString("backdrop_path").nonBlank.map { "\(img)w780\($0)" },
            overview: o.optString("overview"),
            rating: o.optDouble("vote_average"),
            year: date.count >= 4 ? String(date.prefix(4)) : "",
            genres: genres,
            trailerKey: trailer
        )
        cache[cacheKey] = info
        return info
    }

    /// Search TMDB (with the year first for accuracy, then without) → first result id.
    private static func searchId(key: String, type: String, query: String, year: String?, series: Bool) async -> Int? {
        func url(_ withYear: Bool) -> String {
            let yp: String
            if withYear, let year { yp = series ? "&first_air_date_year=\(year)" : "&year=\(year)" } else { yp = "" }
            return "https://api.themoviedb.org/3/search/\(type)?api_key=\(key)&query=\(query.urlEncoded)\(yp)&include_adult=false"
        }
        for withYear in [true, false] {
            if withYear && year == nil { continue }
            guard let search = await Http.getString(url(withYear)),
                  let results = JSON.object(search)?.optArray("results"), !results.isEmpty,
                  let first = results.first as? [String: Any] else { continue }
            return first.optInt("id")
        }
        return nil
    }

    private static func extractYear(_ title: String) -> String? {
        if let r = title.range(of: "\\b(19|20)\\d{2}\\b", options: .regularExpression) {
            return String(title[r])
        }
        return nil
    }

    /// Strips IPTV tags/quality/brackets/prefixes so the title matches TMDB search.
    private static func clean(_ title: String) -> String {
        var t = title
        let subs: [(String, String)] = [
            ("\\[[^\\]]*\\]", " "),
            ("\\([^)]*\\)", " "),
            ("^(?:\\s*[A-Z]{2,3}\\s*[-|:►]+\\s*)+", " "),
            ("(?i)\\b(4k|uhd|fhd|hd|sd|multi-?sub|vod|hevc|x265|h264)\\b", " "),
            ("\\d{3,4}p", " "),
            ("\\b(19|20)\\d{2}\\b", " "),
            ("[|\\-_:►]+", " "),
            ("\\s+", " ")
        ]
        for (pattern, repl) in subs {
            t = t.replacingOccurrences(of: pattern, with: repl, options: .regularExpression)
        }
        return t.trimmingCharacters(in: .whitespaces)
    }
}
