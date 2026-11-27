import SwiftUI

/// App navigation routes — mirror the Android `AppNavHost` destinations.
enum Route: Hashable {
    case welcome
    case addPlaylist(id: String, lock: String)
    case playlists
    case dashboard
    case home(tab: Int)
    case favorites
    case watchLater
    case speedtest
    case search
    case movieDetail
    case sport
    case settings
    case account
    case player(url: String, title: String, resumeId: String)
    case series(id: String, title: String)
}

/// Holds the NavigationStack path and provides the navigate/pop helpers the
/// Android nav graph used (navigate, popBackStack, popUpTo-style resets).
@MainActor
final class Router: ObservableObject {
    /// The stack's base screen (changing it clears the pushed path — like popUpTo root).
    @Published var root: Route
    @Published var path: [Route] = []

    init() {
        root = Prefs.playlists().isEmpty ? .welcome : .playlists
    }

    func push(_ route: Route) { path.append(route) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path.removeAll() }

    /// Reset the whole stack to a single base destination (popUpTo(root, inclusive)).
    func reset(to route: Route) { root = route; path = [] }

    /// After adding a playlist → go to the user's Start Screen setting.
    func goToStart() {
        reset(to: Prefs.startScreen() == "Live" ? .home(tab: 0) : .dashboard)
    }
}
