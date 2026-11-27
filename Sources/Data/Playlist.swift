import Foundation

enum PlaylistType: String, Codable { case xtream = "XTREAM", m3u = "M3U", website = "WEBSITE" }

/// A saved playlist/source the user added. Stored on-device via `Prefs`.
struct Playlist: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let type: PlaylistType
    var host: String = ""
    var username: String = ""
    var password: String = ""
    var url: String = ""
    var key: String = ""
    var epgUrl: String = ""
    var backupHosts: [String] = []
    var activeHost: Int = 0
    /// Non-empty = locked by the customer on the website.
    var pin: String = ""

    /// The playlist is locked (set on the website) — view-only in the app.
    var isLocked: Bool { !pin.isEmpty }

    /// Primary host + any backup DNS, de-duplicated.
    func hosts() -> [String] {
        let primary: String
        switch type {
        case .xtream:
            primary = host
        case .m3u:
            if let u = URLComponents(string: url), let scheme = u.scheme, let h = u.host {
                let port = u.port.map { ":\($0)" } ?? ""
                primary = "\(scheme)://\(h)\(port)"
            } else {
                primary = ""
            }
        case .website:
            primary = ""
        }
        var seen = Set<String>()
        return ([primary] + backupHosts)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
    }

    /// The currently selected host (primary or a chosen backup DNS).
    func activeHostValue() -> String {
        let h = hosts()
        if h.isEmpty { return "" }
        let idx = min(max(activeHost, 0), h.count - 1)
        return h[idx]
    }
}
