import Foundation

/// Tracks which panel notifications the user has read and which were shown as a
/// launch popup, so nothing repeats. Mirrors the Android `NotificationStore`.
enum NotificationStore {
    private static let d = UserDefaults.standard
    private static let READ = "hsu_notif_read_ids"
    private static let SHOWN = "hsu_notif_shown_ids"

    private static func ids(_ key: String) -> Set<String> {
        Set((d.array(forKey: key) as? [String]) ?? [])
    }

    static func unread(_ all: [PanelNotification]) -> [PanelNotification] {
        let read = ids(READ)
        return all.filter { !read.contains(String($0.id)) }
    }

    static func unreadCount(_ all: [PanelNotification]) -> Int { unread(all).count }

    static func markAllRead(_ all: [PanelNotification]) {
        var read = ids(READ)
        all.forEach { read.insert(String($0.id)) }
        d.set(Array(read), forKey: READ)
    }

    static func nextPopup(_ all: [PanelNotification]) -> PanelNotification? {
        let read = ids(READ); let shown = ids(SHOWN)
        return all.first { !read.contains(String($0.id)) && !shown.contains(String($0.id)) }
    }

    static func markShown(_ n: PanelNotification) {
        var shown = ids(SHOWN)
        shown.insert(String(n.id))
        d.set(Array(shown), forKey: SHOWN)
    }
}
