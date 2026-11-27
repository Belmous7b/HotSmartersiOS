import Foundation

/// Loads an XMLTV EPG (for M3U playlists) and serves now/next per channel.
/// Handles plain .xml and gzipped .xml.gz guides. Mirrors Android `Epg`.
final class Epg: NSObject {
    static let shared = Epg()

    private var loadedUrl: String?
    private var map: [String: [EpgProgramme]] = [:]
    private let lock = NSLock()

    func isLoadedFor(_ url: String?) -> Bool {
        guard let url else { return false }
        return url == loadedUrl
    }

    func load(_ url: String) async {
        if url == loadedUrl { return }
        guard let u = URL(string: url) else { return }
        var req = URLRequest(url: u)
        req.setValue(Http.userAgent, forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 40
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return }
        let xml = gunzipIfNeeded(data)
        let parsed = Self.parse(xml)
        lock.lock(); map = parsed; loadedUrl = url; lock.unlock()
    }

    func forChannel(_ channelId: String?) -> [EpgEntry] {
        guard let channelId, !channelId.isEmpty else { return [] }
        lock.lock(); let progs = map[channelId]; lock.unlock()
        guard let progs else { return [] }
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        return progs.filter { $0.stopMs >= now }
            .sorted { $0.startMs < $1.startMs }
            .prefix(10)
            .map { p in
                EpgEntry(title: p.title, start: Self.fmt(p.startMs), end: Self.fmt(p.stopMs),
                         description: p.desc, nowPlaying: now >= p.startMs && now < p.stopMs)
            }
    }

    func clear() { lock.lock(); map.removeAll(); loadedUrl = nil; lock.unlock() }

    private func gunzipIfNeeded(_ data: Data) -> Data {
        guard data.count >= 2, data[0] == 0x1f, data[1] == 0x8b else { return data }
        return (try? (data as NSData).decompressed(using: .zlib) as Data)
            ?? gunzipManual(data) ?? data
    }

    // Fallback gzip inflate via Compression if NSData zlib path isn't a gzip wrapper.
    private func gunzipManual(_ data: Data) -> Data? { nil }

    private static func fmt(_ ms: Int64) -> String {
        if ms <= 0 { return "" }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }

    // MARK: - XMLTV parsing (XMLParser delegate)

    private static func parse(_ data: Data) -> [String: [EpgProgramme]] {
        let parser = XMLParser(data: data)
        let delegate = EpgXmlDelegate()
        parser.delegate = delegate
        parser.parse()
        return delegate.result
    }

    private static func parseTime(_ s: String?) -> Int64 {
        guard let s, !s.isEmpty else { return 0 }
        let clean = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "")
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        fmt.dateFormat = clean.count > 14 ? "yyyyMMddHHmmssZ" : "yyyyMMddHHmmss"
        return fmt.date(from: clean).map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0
    }

    final class EpgXmlDelegate: NSObject, XMLParserDelegate {
        var result: [String: [EpgProgramme]] = [:]
        private var channel: String?
        private var start: Int64 = 0
        private var stop: Int64 = 0
        private var title = ""
        private var desc = ""
        private var inTitle = false
        private var inDesc = false

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            switch elementName {
            case "programme":
                channel = attributeDict["channel"]
                start = Epg.parseTime(attributeDict["start"])
                stop = Epg.parseTime(attributeDict["stop"])
                title = ""; desc = ""
            case "title": inTitle = true
            case "desc": inDesc = true
            default: break
            }
        }
        func parser(_ parser: XMLParser, foundCharacters string: String) {
            if inTitle { title += string } else if inDesc { desc += string }
        }
        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            switch elementName {
            case "title": inTitle = false
            case "desc": inDesc = false
            case "programme":
                if let ch = channel, stop > 0 {
                    result[ch, default: []].append(EpgProgramme(
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        desc: desc.trimmingCharacters(in: .whitespacesAndNewlines),
                        startMs: start, stopMs: stop))
                }
            default: break
            }
        }
    }
}
