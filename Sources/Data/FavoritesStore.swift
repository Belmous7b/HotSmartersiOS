import Foundation

struct FavFolder: Identifiable, Hashable { let id: String; let name: String }

struct FavItem: Identifiable, Hashable {
    var id: String { "\(folderId)_\(kind.rawValue)_\(streamId)" }
    let folderId: String
    let kind: MediaKind
    let streamId: String
    let name: String
    let poster: String?
    let url: String
    let group: String?
}

/// Favorites with named folders (e.g. "Dad's channels"). Per active playlist.
enum FavoritesStore {
    static let defaultFolderId = "default"
    private static let d = UserDefaults.standard

    private static func foldersKey() -> String { "hsu_favs_folders_\(ContentRepository.currentPlaylistId)" }
    private static func itemsKey() -> String { "hsu_favs_items_\(ContentRepository.currentPlaylistId)" }

    static func folders() -> [FavFolder] {
        var list = [FavFolder(id: defaultFolderId, name: "Favorites")]
        if let raw = d.string(forKey: foldersKey()), let arr = JSON.array(raw) {
            for o in arr.compactMap({ $0 as? [String: Any] }) {
                list.append(FavFolder(id: o.optString("id"), name: o.optString("name")))
            }
        }
        return list
    }

    private static func saveFolders(_ folders: [FavFolder]) {
        let arr = folders.filter { $0.id != defaultFolderId }.map { ["id": $0.id, "name": $0.name] }
        d.set(JSON.stringify(arr), forKey: foldersKey())
    }

    @discardableResult
    static func createFolder(_ name: String) -> FavFolder {
        let folder = FavFolder(id: String(Int64(Date().timeIntervalSince1970 * 1000)), name: name)
        saveFolders(folders() + [folder])
        return folder
    }

    static func deleteFolder(_ id: String) {
        if id == defaultFolderId { return }
        saveFolders(folders().filter { $0.id != id })
        saveItems(items().filter { $0.folderId != id })
    }

    static func items() -> [FavItem] {
        guard let raw = d.string(forKey: itemsKey()), let arr = JSON.array(raw) else { return [] }
        return arr.compactMap { $0 as? [String: Any] }.map { o in
            FavItem(
                folderId: o.optString("folderId"),
                kind: MediaKind(rawValue: o.optString("kind")) ?? .live,
                streamId: o.optString("streamId"),
                name: o.optString("name"),
                poster: o.optString("poster").nonBlank,
                url: o.optString("url"),
                group: o.optString("group").nonBlank
            )
        }
    }

    private static func saveItems(_ items: [FavItem]) {
        let arr = items.map { i in
            ["folderId": i.folderId, "kind": i.kind.rawValue, "streamId": i.streamId,
             "name": i.name, "poster": i.poster ?? "", "url": i.url, "group": i.group ?? ""]
        }
        d.set(JSON.stringify(arr), forKey: itemsKey())
    }

    static func itemsInFolder(_ folderId: String) -> [FavItem] { items().filter { $0.folderId == folderId } }

    static func foldersContaining(_ kind: MediaKind, _ streamId: String) -> Set<String> {
        Set(items().filter { $0.kind == kind && $0.streamId == streamId }.map { $0.folderId })
    }

    static func addTo(_ folderId: String, _ item: FavItem) {
        let exists = items().contains { $0.folderId == folderId && $0.kind == item.kind && $0.streamId == item.streamId }
        if !exists {
            var copy = item
            copy = FavItem(folderId: folderId, kind: item.kind, streamId: item.streamId, name: item.name, poster: item.poster, url: item.url, group: item.group)
            saveItems(items() + [copy])
        }
    }

    static func removeFrom(_ folderId: String, _ kind: MediaKind, _ streamId: String) {
        saveItems(items().filter { !($0.folderId == folderId && $0.kind == kind && $0.streamId == streamId) })
    }
}
