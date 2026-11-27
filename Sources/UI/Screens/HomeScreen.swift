import SwiftUI

/// Tabbed Live / Movies / Series with a left navigation rail. Mirrors Android `HomeScreen`.
struct HomeScreen: View {
    var startTab: Int = 0
    @EnvironmentObject var router: Router
    @EnvironmentObject var repo: ContentRepository
    @State private var tab: Int

    init(startTab: Int = 0) {
        self.startTab = startTab
        _tab = State(initialValue: startTab)
    }

    var body: some View {
        HStack(spacing: 0) {
            rail
            ZStack {
                switch tab {
                case 0:
                    LiveScreen(onFullscreenPlay: { url, title in router.push(.player(url: url, title: title, resumeId: "")) })
                case 1:
                    VodScreen(items: repo.movies, categories: repo.movieCategories, unitLabel: "movies") { item in
                        repo.detailItem = item; router.push(.movieDetail)
                    }
                default:
                    VodScreen(items: repo.series, categories: repo.seriesCategories, unitLabel: "series") { item in
                        if !item.url.isEmpty {
                            HistoryStore.record(HistoryItem(kind: .series, streamId: item.id, name: item.name, poster: item.poster, url: item.url, group: item.group))
                            router.push(.player(url: item.url, title: item.name, resumeId: item.id))
                        } else {
                            router.push(.series(id: item.id, title: item.name))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Keep the search row / headers clear of the very top edge.
            .padding(.top, 8)
        }
        .background(Color.darkBg)
    }

    private var rail: some View {
        VStack(spacing: 6) {
            Spacer()
            railItem("house.fill", tr("Home"), false) { router.path = [.dashboard] }
            railItem("tv.fill", tr("Live TV"), tab == 0) { tab = 0 }
            railItem("film.fill", tr("Movies"), tab == 1) { tab = 1 }
            railItem("rectangle.stack.fill", tr("Series"), tab == 2) { tab = 2 }
            railItem("arrow.left.arrow.right", tr("Switch"), false) { router.reset(to: .playlists) }
            Spacer()
        }
        .frame(width: 92)
        .padding(.vertical, 10)
    }

    private func railItem(_ system: String, _ label: String, _ selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: system).foregroundStyle(selected ? .white : Color.textSecondary)
                Text(label).font(.caption2).foregroundStyle(selected ? .white : Color.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(selected ? Color.hotRed : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}
