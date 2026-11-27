import Foundation

/// API keys baked into the app, so users never enter anything.
/// Mirrors the Android `ApiKeys` object exactly.
enum ApiKeys {
    /// TMDB v3 API key.
    static let tmdb = "ea7af18eec39c33c5c05620dcb1b0fa5"

    /// OpenSubtitles API key (opensubtitles.com).
    static let openSubtitles = "quZdFEeqoYDI3IVQjSKdyjVJxvTzfu7f"

    /// TheSportsDB key for the Sport hub (the free "3" test key is used if blank).
    static let sports = "123"

    /// Activation / reseller panel base URL. Leave BLANK to disable activation.
    static let panel = "https://hotsmarters.app"
}
