import Foundation

/// Clears image caches without touching the user's login or favorites.
/// Mirrors the Android `CacheUtil` (iOS uses URLCache for AsyncImage).
enum CacheUtil {
    static func clear() {
        URLCache.shared.removeAllCachedResponses()
    }
}
