import Foundation

/// Shifts all timestamps in an SRT subtitle by offsetMs (can be negative).
enum SubtitleShifter {
    private static let regex = try! NSRegularExpression(pattern: "(\\d{2}):(\\d{2}):(\\d{2}),(\\d{3})")

    static func shift(_ srt: String, offsetMs: Int64) -> String {
        let ns = srt as NSString
        var result = ""
        var last = 0
        regex.enumerateMatches(in: srt, range: NSRange(location: 0, length: ns.length)) { m, _, _ in
            guard let m else { return }
            result += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            let h = Int64(ns.substring(with: m.range(at: 1))) ?? 0
            let mi = Int64(ns.substring(with: m.range(at: 2))) ?? 0
            let s = Int64(ns.substring(with: m.range(at: 3))) ?? 0
            let ms = Int64(ns.substring(with: m.range(at: 4))) ?? 0
            var t = (((h * 60 + mi) * 60 + s) * 1000 + ms) + offsetMs
            if t < 0 { t = 0 }
            result += format(t)
            last = m.range.location + m.range.length
        }
        result += ns.substring(from: last)
        return result
    }

    private static func format(_ total: Int64) -> String {
        let ms = total % 1000
        let s = (total / 1000) % 60
        let mi = (total / 60000) % 60
        let h = total / 3600000
        return String(format: "%02d:%02d:%02d,%03d", Int(h), Int(mi), Int(s), Int(ms))
    }
}
