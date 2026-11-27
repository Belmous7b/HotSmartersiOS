import Foundation

/// Searches OpenSubtitles by title + language and returns a direct URL to the
/// subtitle file. Mirrors the Android `OpenSubtitlesClient`.
enum OpenSubtitlesClient {
    private static let base = "https://api.opensubtitles.com/api/v1"
    private static let ua = "HotSmartersiOS v1.0"

    static func fetch(title: String, lang: String) async -> String? {
        let key = ApiKeys.openSubtitles
        if key.isEmpty || title.isEmpty { return nil }
        let query = clean(title).urlEncoded

        guard let searchUrl = URL(string: "\(base)/subtitles?query=\(query)&languages=\(lang)") else { return nil }
        var searchReq = URLRequest(url: searchUrl)
        searchReq.setValue(key, forHTTPHeaderField: "Api-Key")
        searchReq.setValue(ua, forHTTPHeaderField: "User-Agent")

        guard let (sData, sResp) = try? await URLSession.shared.data(for: searchReq),
              let http = sResp as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let obj = JSON.object(String(data: sData, encoding: .utf8)),
              let data = obj.optArray("data"), !data.isEmpty,
              let first = data.first as? [String: Any],
              let files = first.optObject("attributes")?.optArray("files"),
              let file0 = files.first as? [String: Any] else { return nil }
        let fileId = file0.optInt("file_id", -1)
        if fileId < 0 { return nil }

        guard let dlUrl = URL(string: "\(base)/download") else { return nil }
        var dlReq = URLRequest(url: dlUrl)
        dlReq.httpMethod = "POST"
        dlReq.setValue(key, forHTTPHeaderField: "Api-Key")
        dlReq.setValue(ua, forHTTPHeaderField: "User-Agent")
        dlReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        dlReq.httpBody = JSON.stringify(["file_id": fileId]).data(using: .utf8)

        guard let (dData, dResp) = try? await URLSession.shared.data(for: dlReq),
              let dhttp = dResp as? HTTPURLResponse, (200..<300).contains(dhttp.statusCode),
              let dobj = JSON.object(String(data: dData, encoding: .utf8)) else { return nil }
        return dobj.optString("link").nonBlank
    }

    private static func clean(_ title: String) -> String {
        var t = title
        let subs: [(String, String)] = [
            ("\\[[^\\]]*\\]", " "),
            ("\\([^)]*\\)", " "),
            ("(?i)\\b(4k|uhd|fhd|hd|sd|multi-?sub|vod)\\b", " "),
            ("[|\\-_:]+", " "),
            ("\\s+", " ")
        ]
        for (p, r) in subs { t = t.replacingOccurrences(of: p, with: r, options: .regularExpression) }
        return t.trimmingCharacters(in: .whitespaces)
    }
}
