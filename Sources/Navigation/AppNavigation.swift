import SwiftUI

/// The NavigationStack and the route → screen wiring (mirrors `AppNavHost`).
struct RootNavigationView: View {
    @EnvironmentObject var router: Router

    var body: some View {
        NavigationStack(path: $router.path) {
            screen(for: router.root)
                .navigationDestination(for: Route.self) { route in
                    screen(for: route)
                }
        }
        .tint(.hotRed)
    }

    @ViewBuilder
    private func screen(for route: Route) -> some View {
        switch route {
        case .welcome:
            WelcomeScreen(
                onAddXtream: { router.push(.addPlaylist(id: "", lock: "xtream")) },
                onAddM3u: { router.push(.addPlaylist(id: "", lock: "m3u")) },
                onHasPlaylists: { router.reset(to: .playlists) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case let .addPlaylist(id, lock):
            AddPlaylistScreen(
                editId: id.isEmpty ? nil : id,
                lockType: lock.isEmpty ? nil : lock,
                onSaved: { router.goToStart() },
                onWebsiteLoaded: { router.reset(to: .playlists) },
                onBack: router.path.isEmpty ? nil : { router.pop() }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .playlists:
            PlaylistsScreen(
                onAdd: { router.push(.addPlaylist(id: "", lock: "")) },
                onOpen: { router.push(Prefs.startScreen() == "Live" ? .home(tab: 0) : .dashboard) },
                onEdit: { p in router.push(.addPlaylist(id: p.id, lock: "")) },
                onEmpty: { router.reset(to: .welcome) },
                onSettings: { router.push(.settings) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .dashboard:
            DashboardScreen(
                onLive: { router.push(.home(tab: 0)) },
                onMovies: { router.push(.home(tab: 1)) },
                onSeries: { router.push(.home(tab: 2)) },
                onSearch: { router.push(.search) },
                onSwitchPlaylist: { router.reset(to: .playlists) },
                onAccount: { router.push(.account) },
                onSettings: { router.push(.settings) },
                onSpeedTest: { router.push(.speedtest) },
                onWatchLater: { router.push(.watchLater) },
                onPlay: { url, title, resumeId in router.push(.player(url: url, title: title, resumeId: resumeId)) },
                onOpenMovie: { item in ContentRepository.shared.detailItem = item; router.push(.movieDetail) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case let .home(tab):
            HomeScreen(startTab: tab)
                .toolbar(.hidden, for: .navigationBar)

        case .favorites:
            FavoritesScreen(
                onBack: { router.pop() },
                onPlay: { fav in router.push(.player(url: fav.url, title: fav.name, resumeId: "")) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .watchLater:
            WatchLaterScreen(
                onBack: { router.pop() },
                onOpen: { item in
                    if item.kind == .series {
                        router.push(.series(id: item.streamId, title: item.name))
                    } else {
                        HistoryStore.record(HistoryItem(kind: .movie, streamId: item.streamId, name: item.name, poster: item.poster, url: item.url, group: item.group))
                        router.push(.player(url: item.url, title: item.name, resumeId: item.streamId))
                    }
                }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .speedtest:
            SpeedTestScreen(onBack: { router.pop() })
                .toolbar(.hidden, for: .navigationBar)

        case .search:
            SearchScreen(
                onBack: { router.pop() },
                onPlay: { url, title in router.push(.player(url: url, title: title, resumeId: "")) },
                onOpenSeries: { id, title in router.push(.series(id: id, title: title)) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .movieDetail:
            MovieDetailScreen(
                onBack: { router.pop() },
                onPlay: { url, title, id in router.push(.player(url: url, title: title, resumeId: id)) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .sport:
            SportScreen(onBack: { router.pop() })
                .toolbar(.hidden, for: .navigationBar)

        case .settings:
            SettingsScreen(
                onBack: { router.pop() },
                onDisconnect: { router.reset(to: .playlists) }
            )
            .toolbar(.hidden, for: .navigationBar)

        case .account:
            AccountScreen(onBack: { router.pop() })
                .toolbar(.hidden, for: .navigationBar)

        case let .player(url, title, resumeId):
            PlayerScreen(url: url, title: title, resumeId: resumeId, onBack: { router.pop() })
                .toolbar(.hidden, for: .navigationBar)

        case let .series(id, title):
            SeriesDetailScreen(
                seriesId: id, title: title,
                onBack: { router.pop() },
                onPlay: { url, t, sid in router.push(.player(url: url, title: t, resumeId: sid)) }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
