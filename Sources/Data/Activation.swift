import Foundation
import Combine

/// Reseller support contacts, shown in the app's Support screen.
struct SupportInfo: Equatable {
    var website = ""
    var whatsapp = ""
    var telegram = ""
    var isEmpty: Bool { website.isEmpty && whatsapp.isEmpty && telegram.isEmpty }
}

/// A playlist/line the panel manages for this device.
struct PanelPlaylist {
    var id = ""
    let name: String
    let type: String   // "xtream" | "m3u"
    let host: String
    let username: String
    let password: String
    let url: String
    let epgUrl: String
    var pin = ""
}

/// A push notification from the reseller who activated this device.
struct PanelNotification: Identifiable, Equatable {
    let id: Int64
    let title: String
    let body: String
    let createdAt: String
}

/// Result of an activation check against the panel.
struct Activation: Equatable {
    let status: String    // active | expired | banned | not_found | unknown
    var plan = ""
    var expiresAt: String? = nil
    var support = SupportInfo()
    var playlists: [PanelPlaylist] = []
    var notifications: [PanelNotification] = []

    var isActive: Bool { status == "active" }
    var isBlocked: Bool { status == "expired" || status == "banned" }

    static func == (l: Activation, r: Activation) -> Bool {
        l.status == r.status && l.plan == r.plan && l.expiresAt == r.expiresAt &&
        l.support == r.support && l.notifications == r.notifications
    }
}

/// Talks to the activation panel and caches the last result (persisted + in-memory).
/// Mirrors the Android `ActivationStore`.
@MainActor
final class ActivationStore: ObservableObject {
    static let shared = ActivationStore()
    private init() {}

    @Published private(set) var current: Activation?
    private let d = UserDefaults.standard
    private let fileKey = "hsu_activation_data"

    private func base() -> String {
        ApiKeys.panel.hasSuffix("/") ? String(ApiKeys.panel.dropLast()) : ApiKeys.panel
    }

    @discardableResult
    func load() -> Activation? {
        current = parse(d.string(forKey: fileKey))
        return current
    }

    /// Ask the panel for the live status. Returns nil if disabled or unreachable.
    @discardableResult
    func refresh() async -> Activation? {
        if ApiKeys.panel.isEmpty { return nil }
        let body = JSON.stringify([
            "mac": DeviceId.mac(),
            "key": DeviceId.key(),
            "platform": platform(),
            "playlists": appPlaylistsJson()
        ])
        guard let resp = await Http.postJson("\(base())/api/activate", json: body),
              let a = parse(resp) else { return nil }
        current = a
        persist(a)
        if a.isActive { adoptPlaylists(a.playlists) }
        return a
    }

    /// Push the app's current playlists to the panel (after an in-app add/delete).
    func pushPlaylists() async {
        if ApiKeys.panel.isEmpty { return }
        let body = JSON.stringify([
            "mac": DeviceId.mac(), "key": DeviceId.key(), "playlists": appPlaylistsJson()
        ])
        await Http.postJson("\(base())/api/app-playlists", json: body)
    }

    /// Remove a PIN-locked playlist on the server (needs the PIN) and then locally.
    /// Returns nil on success, or an error code: "bad_pin", "reseller_locked",
    /// "network", "offline".
    func deletePlaylist(id: String, pin: String) async -> String? {
        if ApiKeys.panel.isEmpty { return "offline" }
        let body = JSON.stringify(["mac": DeviceId.mac(), "key": DeviceId.key(), "id": id, "pin": pin])
        guard let r = await Http.postJsonResult("\(base())/api/customer/delete-playlist", json: body) else { return "network" }
        if r.ok {
            Prefs.removePlaylist(id)
            ContentCache.remove(id)
            return nil
        }
        let err = JSON.object(r.body ?? "{}")?.optString("error") ?? ""
        return err.isEmpty ? "error" : err
    }

    func clear() {
        current = nil
        d.removeObject(forKey: fileKey)
    }

    private func platform() -> String {
        #if canImport(UIKit)
        return "iOS \(ProcessInfo.processInfo.operatingSystemVersionString)"
        #else
        return "iOS"
        #endif
    }

    // MARK: - playlist bridging

    private func appPlaylistsJson() -> [[String: Any]] {
        Prefs.playlists().compactMap { p -> [String: Any]? in
            let type: String
            switch p.type {
            case .xtream: type = "xtream"
            case .m3u: type = "m3u"
            case .website: return nil
            }
            return ["id": p.id, "name": p.name, "type": type, "host": p.host,
                    "username": p.username, "password": p.password,
                    "url": p.url, "epgUrl": p.epgUrl, "pin": p.pin]
        }
    }

    private func adoptPlaylists(_ playlists: [PanelPlaylist]) {
        let mapped = playlists.enumerated().map { (i, p) in
            Playlist(id: p.id.isEmpty ? "panel_\(i)" : p.id, name: p.name,
                     type: p.type == "m3u" ? .m3u : .xtream,
                     host: p.host, username: p.username, password: p.password,
                     url: p.url, epgUrl: p.epgUrl, pin: p.pin)
        }
        let previous = Prefs.playlists()
        let websiteOnly = previous.filter { $0.type == .website }

        let newById = Dictionary(mapped.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        for old in previous where old.type != .website {
            if let now = newById[old.id] {
                if sig(now) != sig(old) { ContentCache.remove(old.id) }
            } else {
                ContentCache.remove(old.id)
            }
        }
        Prefs.setPlaylists(mapped + websiteOnly)
    }

    private func sig(_ p: Playlist) -> String {
        "\(p.type.rawValue)|\(p.host.trimmingCharacters(in: .whitespaces))|\(p.username.trimmingCharacters(in: .whitespaces))|\(p.url.trimmingCharacters(in: .whitespaces))".lowercased()
    }

    // MARK: - persistence

    private func persist(_ a: Activation) {
        let o: [String: Any] = [
            "status": a.status, "plan": a.plan, "expires_at": a.expiresAt ?? "",
            "support": ["website": a.support.website, "whatsapp": a.support.whatsapp, "telegram": a.support.telegram],
            "notifications": a.notifications.map { ["id": $0.id, "title": $0.title, "body": $0.body, "created_at": $0.createdAt] }
        ]
        d.set(JSON.stringify(o), forKey: fileKey)
    }

    private func parse(_ raw: String?) -> Activation? {
        guard let o = JSON.object(raw) else { return nil }
        let sup = o.optObject("support")
        return Activation(
            status: str(o, "status").ifBlank("unknown"),
            plan: str(o, "plan"),
            expiresAt: str(o, "expires_at").nonBlank,
            support: SupportInfo(
                website: sup.map { str($0, "website") } ?? "",
                whatsapp: sup.map { str($0, "whatsapp") } ?? "",
                telegram: sup.map { str($0, "telegram") } ?? ""),
            playlists: parsePlaylists(o.optArray("playlists")),
            notifications: parseNotifs(o.optArray("notifications")))
    }

    private func parsePlaylists(_ arr: [Any]?) -> [PanelPlaylist] {
        (arr ?? []).compactMap { $0 as? [String: Any] }.map { o in
            PanelPlaylist(id: str(o, "id"), name: str(o, "name"), type: str(o, "type"),
                          host: str(o, "host"), username: str(o, "username"), password: str(o, "password"),
                          url: str(o, "url"), epgUrl: str(o, "epgUrl"), pin: str(o, "pin"))
        }
    }

    private func parseNotifs(_ arr: [Any]?) -> [PanelNotification] {
        (arr ?? []).compactMap { $0 as? [String: Any] }.map { o in
            PanelNotification(id: o.optLong("id"), title: str(o, "title"), body: str(o, "body"), createdAt: str(o, "created_at"))
        }
    }

    /// optString but treats explicit JSON null as empty string.
    private func str(_ o: [String: Any], _ key: String) -> String {
        o.isNull(key) ? "" : o.optString(key)
    }
}
