import Foundation

/// On-device storage (UserDefaults + JSON) for saved playlists and app settings.
/// Mirrors the Android `Prefs` object.
enum Prefs {
    private static let d = UserDefaults.standard

    private static let kPlaylists = "hsu_playlists"
    private static let kParental = "hsu_parental_code"
    private static let kLanguage = "hsu_language"

    // MARK: - Playlists

    static func playlists() -> [Playlist] {
        guard let data = d.data(forKey: kPlaylists) else { return [] }
        return (try? JSONDecoder().decode([Playlist].self, from: data)) ?? []
    }

    private static func savePlaylists(_ list: [Playlist]) {
        if let data = try? JSONEncoder().encode(list) { d.set(data, forKey: kPlaylists) }
    }

    static func addPlaylist(_ playlist: Playlist) { savePlaylists(playlists() + [playlist]) }

    /// Replace the whole playlist list (used when the panel manages playlists).
    static func setPlaylists(_ list: [Playlist]) { savePlaylists(list) }

    static func removePlaylist(_ id: String) { savePlaylists(playlists().filter { $0.id != id }) }

    static func updatePlaylist(_ playlist: Playlist) {
        savePlaylists(playlists().map { $0.id == playlist.id ? playlist : $0 })
    }

    static func playlist(_ id: String) -> Playlist? { playlists().first { $0.id == id } }

    // MARK: - Settings

    static func parentalCode() -> String? {
        guard let c = d.string(forKey: kParental), !c.isEmpty else { return nil }
        return c
    }
    static func setParentalCode(_ code: String?) { d.set(code ?? "", forKey: kParental) }

    /// Seed a default parental PIN "0000" once, so adult categories are protected
    /// out of the box. After the user sets/clears it, their choice is kept.
    static func ensureDefaultParental() {
        if d.object(forKey: kParental) == nil { d.set("0000", forKey: kParental) }
    }

    static func language() -> String { d.string(forKey: kLanguage) ?? "English" }
    static func setLanguage(_ v: String) { d.set(v, forKey: kLanguage) }

    static func profileName() -> String { d.string(forKey: "profile_name") ?? "" }
    static func setProfileName(_ v: String) { d.set(v, forKey: "profile_name") }

    static func profileAvatar() -> String { d.string(forKey: "profile_avatar") ?? "" }
    static func setProfileAvatar(_ v: String) { d.set(v, forKey: "profile_avatar") }

    static func tmdbKey() -> String? {
        guard let k = d.string(forKey: "tmdb_key"), !k.isEmpty else { return nil }
        return k
    }
    static func setTmdbKey(_ v: String) { d.set(v.trimmingCharacters(in: .whitespaces), forKey: "tmdb_key") }

    // MARK: - Playback / app preferences

    static func autoPlayNext() -> Bool { d.object(forKey: "auto_next") == nil ? true : d.bool(forKey: "auto_next") }
    static func setAutoPlayNext(_ v: Bool) { d.set(v, forKey: "auto_next") }

    static func audioLang() -> String { d.string(forKey: "audio_lang") ?? "" }
    static func setAudioLang(_ v: String) { d.set(v, forKey: "audio_lang") }

    static func subtitleLang() -> String { d.string(forKey: "sub_lang") ?? "" }
    static func setSubtitleLang(_ v: String) { d.set(v, forKey: "sub_lang") }

    /// "Fit" | "Fill" | "Stretch"
    static func videoFit() -> String { d.string(forKey: "video_fit") ?? "Fit" }
    static func setVideoFit(_ v: String) { d.set(v, forKey: "video_fit") }

    /// "Home" | "Live"
    static func startScreen() -> String { d.string(forKey: "start_screen") ?? "Home" }
    static func setStartScreen(_ v: String) { d.set(v, forKey: "start_screen") }
}
