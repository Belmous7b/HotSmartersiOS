import Foundation

/// Parses an M3U / M3U8 playlist into Live / Movies / Series buckets.
/// Tolerant of the many M3U variants in the wild (mirrors Android `M3uParser`).
enum M3uParser {

    static func parse(_ content: String) -> ParsedPlaylist {
        let cleaned = content.hasPrefix("\u{FEFF}") ? String(content.dropFirst()) : content
        return parseLines(cleaned.split(whereSeparator: { $0 == "\n" || $0 == "\r" }).map(String.init))
    }

    private static func parseLines(_ raw: [String]) -> ParsedPlaylist {
        var live: [LiveChannel] = []
        var movies: [VodItem] = []
        var series: [VodItem] = []

        var tvgUrl: String? = nil
        var counter = 0
        var pendingGroup: String? = nil

        var haveExtinf = false
        var eName = ""
        var eLogo: String? = nil
        var eGroup: String? = nil
        var eTvg: String? = nil

        for rawLine in raw {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            if line.range(of: "#EXTM3U", options: [.caseInsensitive, .anchored]) != nil {
                if tvgUrl == nil {
                    tvgUrl = attr(line, "url-tvg") ?? attr(line, "x-tvg-url") ?? attr(line, "tvg-url")
                }
            } else if line.range(of: "#EXTGRP", options: [.caseInsensitive, .anchored]) != nil {
                if let colon = line.firstIndex(of: ":") {
                    let g = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                    pendingGroup = g.isEmpty ? nil : g
                }
            } else if line.range(of: "#EXTINF", options: [.caseInsensitive, .anchored]) != nil {
                eName = extName(line)
                eLogo = attr(line, "tvg-logo") ?? attr(line, "logo")
                eGroup = attr(line, "group-title") ?? pendingGroup
                eTvg = attr(line, "tvg-id")
                haveExtinf = true
            } else if line.hasPrefix("#") {
                // #EXTVLCOPT / #KODIPROP / comments — ignore.
            } else {
                if haveExtinf {
                    let url = line
                    let id = "m3u_\(counter)"
                    counter += 1
                    let g = (eGroup ?? "").lowercased()
                    if g.contains("series") || g.contains("tv show") {
                        series.append(VodItem(id: id, name: eName, poster: eLogo, group: eGroup, url: url, type: .series))
                    } else if g.contains("movie") || g.contains("vod") || g.contains("film") {
                        movies.append(VodItem(id: id, name: eName, poster: eLogo, group: eGroup, url: url, type: .movie))
                    } else {
                        live.append(LiveChannel(id: id, name: eName, logo: eLogo, group: eGroup, url: url, tvgId: eTvg, archive: false))
                    }
                    haveExtinf = false
                    pendingGroup = nil
                }
            }
        }
        return ParsedPlaylist(live: live, movies: movies, series: series, tvgUrl: tvgUrl)
    }

    /// Display name = text after the first UNQUOTED comma; falls back to tvg-name.
    private static func extName(_ line: String) -> String {
        var inQuotes = false
        var idx: String.Index? = nil
        var i = line.startIndex
        while i < line.endIndex {
            let c = line[i]
            if c == "\"" { inQuotes.toggle() }
            else if c == "," && !inQuotes { idx = i; break }
            i = line.index(after: i)
        }
        let rawName: String
        if let idx { rawName = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces) }
        else { rawName = "" }
        return rawName.isEmpty ? (attr(line, "tvg-name") ?? "Channel") : rawName
    }

    private static func attr(_ line: String, _ name: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\(name)=\"([^\"]*)\"", options: [.caseInsensitive]) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let m = regex.firstMatch(in: line, range: range),
              let r = Range(m.range(at: 1), in: line) else { return nil }
        let v = String(line[r])
        return v.isEmpty ? nil : v
    }
}
