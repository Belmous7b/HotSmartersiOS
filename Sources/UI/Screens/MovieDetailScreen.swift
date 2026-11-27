import SwiftUI

/// Movie detail: TMDB backdrop header, title/year/rating/genres, Play / Trailer /
/// Watch Later, overview. Mirrors Android `MovieDetailScreen`.
struct MovieDetailScreen: View {
    let onBack: () -> Void
    let onPlay: (String, String, String) -> Void

    @EnvironmentObject var repo: ContentRepository
    @State private var info: TmdbInfo?
    @State private var loading = true
    @State private var saved = false

    private var item: VodItem? { repo.detailItem }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.darkBg.ignoresSafeArea()
            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack(alignment: .bottom) {
                            RemoteImage(url: info?.backdrop ?? info?.poster ?? item.poster, contentMode: .fill) { Color.darkSurface2 }
                                .frame(height: 260).frame(maxWidth: .infinity).clipped()
                            LinearGradient(colors: [.clear, .darkBg.opacity(0.35), .darkBg], startPoint: .top, endPoint: .bottom)
                                .frame(height: 260)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.name).font(.title.bold()).foregroundStyle(.white)
                            Spacer().frame(height: 6)
                            HStack {
                                if let y = info?.year, !y.isEmpty { Text(y).foregroundStyle(Color.textSecondary) }
                                if let r = info?.rating, r > 0 { Text("★ \(String(format: "%.1f", r))").fontWeight(.bold).foregroundStyle(Color.hotOrange) }
                            }
                            if let genres = info?.genres, !genres.isEmpty {
                                HStack(spacing: 8) {
                                    ForEach(genres.prefix(3), id: \.self) { g in
                                        Text(g).font(.caption).foregroundStyle(.white)
                                            .padding(.horizontal, 12).padding(.vertical, 5)
                                            .background(Color.darkSurface2).clipShape(Capsule())
                                            .overlay(Capsule().stroke(Color.dividerColor, lineWidth: 1))
                                    }
                                }
                                .padding(.top, 8)
                            }
                            Spacer().frame(height: 16)
                            HStack(spacing: 12) {
                                Button {
                                    repo.clearQueue()
                                    HistoryStore.record(HistoryItem(kind: .movie, streamId: item.id, name: item.name, poster: item.poster, url: item.url, group: item.group))
                                    onPlay(item.url, item.name, item.id)
                                } label: {
                                    Label("Play", systemImage: "play.fill").fontWeight(.bold).foregroundStyle(.white)
                                        .padding(.horizontal, 18).frame(height: 48).background(Color.hotRed).clipShape(Capsule()).glow()
                                }
                                if let key = info?.trailerKey {
                                    Button { SupportLinks.open("https://www.youtube.com/watch?v=\(key)") } label: {
                                        Label("Trailer", systemImage: "film").foregroundStyle(.white)
                                            .padding(.horizontal, 18).frame(height: 48).overlay(Capsule().stroke(Color.white, lineWidth: 1))
                                    }
                                }
                                Button {
                                    saved = WatchLaterStore.toggle(WatchLaterItem(kind: .movie, streamId: item.id, name: item.name, poster: item.poster, url: item.url, group: item.group))
                                } label: {
                                    Label(saved ? "  Saved" : "  Watch Later", systemImage: saved ? "checkmark" : "clock")
                                        .foregroundStyle(.white).padding(.horizontal, 18).frame(height: 48)
                                        .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                                }
                            }
                            Spacer().frame(height: 16)
                            if loading { ProgressView().tint(.hotRed) }
                            else if let o = info?.overview, !o.isEmpty { Text(o).foregroundStyle(.white) }
                            else { Text("No extra details found for this title.").font(.footnote).foregroundStyle(Color.textSecondary) }
                        }
                        .padding(16)
                    }
                }
            } else {
                EmptyStateView("Not available.")
            }
            Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white).padding(12).background(Color.black.opacity(0.4)).clipShape(Circle()) }
                .padding(8)
        }
        .task {
            if let item {
                saved = WatchLaterStore.contains(.movie, item.id)
                info = await TmdbClient.fetch(title: item.name, series: item.type == .series)
            }
            loading = false
        }
    }
}
