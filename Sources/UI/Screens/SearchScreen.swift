import SwiftUI

/// Search across live + movies + series of the current playlist. Mirrors Android `SearchScreen`.
struct SearchScreen: View {
    let onBack: () -> Void
    let onPlay: (String, String) -> Void
    let onOpenSeries: (String, String) -> Void

    @EnvironmentObject var repo: ContentRepository
    @State private var query = ""

    private struct Result: Identifiable { let id: String; let kind: MediaKind; let streamId: String; let name: String; let image: String?; let url: String }

    private var live: [Result] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return [] }
        return repo.live.filter { $0.name.range(of: q, options: .caseInsensitive) != nil }.prefix(60)
            .map { Result(id: "l_\($0.id)", kind: .live, streamId: $0.id, name: $0.name, image: $0.logo, url: $0.url) }
    }
    private var movies: [Result] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return [] }
        return repo.movies.filter { $0.name.range(of: q, options: .caseInsensitive) != nil }.prefix(60)
            .map { Result(id: "m_\($0.id)", kind: .movie, streamId: $0.id, name: $0.name, image: $0.poster, url: $0.url) }
    }
    private var series: [Result] {
        let q = query.trimmingCharacters(in: .whitespaces)
        if q.isEmpty { return [] }
        return repo.series.filter { $0.name.range(of: q, options: .caseInsensitive) != nil }.prefix(60)
            .map { Result(id: "s_\($0.id)", kind: .series, streamId: $0.id, name: $0.name, image: $0.poster, url: $0.url) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white) }
                SearchField(query: $query, hint: "Search everything").padding(.trailing, 8)
            }
            .padding(8)

            let q = query.trimmingCharacters(in: .whitespaces)
            if q.isEmpty {
                centered("Search across Live TV, Movies & Series")
            } else if live.isEmpty && movies.isEmpty && series.isEmpty {
                centered("No results for \"\(q)\"")
            } else {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        if !live.isEmpty { section("Live TV (\(live.count))", live) }
                        if !movies.isEmpty { section("Movies (\(movies.count))", movies) }
                        if !series.isEmpty { section("Series (\(series.count))", series) }
                    }
                }
            }
        }
        .background(Color.darkBg)
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [Result]) -> some View {
        Section {
            ForEach(items) { r in resultRow(r) }
        } header: {
            Text(title).fontWeight(.bold).foregroundStyle(Color.hotRed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 8).background(Color.darkSurface)
        }
    }

    private func resultRow(_ r: Result) -> some View {
        Button { open(r) } label: {
            HStack(spacing: 12) {
                RemoteImage(url: r.image, contentMode: .fill) {
                    ZStack { Color.darkSurface2; Text(String(r.name.prefix(1)).uppercased()).foregroundStyle(.white) }
                }
                .frame(width: 48, height: 64).clipped().clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(r.name).foregroundStyle(.white).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                Text(r.kind.rawValue).font(.caption2).foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private func centered(_ text: String) -> some View {
        Text(text).foregroundStyle(Color.textSecondary).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func open(_ r: Result) {
        if r.kind == .series && r.url.isEmpty {
            onOpenSeries(r.streamId, r.name)
        } else {
            HistoryStore.record(HistoryItem(kind: r.kind, streamId: r.streamId, name: r.name, poster: r.image, url: r.url, group: nil))
            onPlay(r.url, r.name)
        }
    }
}
