import SwiftUI

/// Series detail: TMDB header, overview, season picker, Watch Later (below the
/// season selector), and the episode list. Mirrors Android `SeriesDetailScreen`.
struct SeriesDetailScreen: View {
    let seriesId: String
    let title: String
    let onBack: () -> Void
    let onPlay: (String, String, String) -> Void

    @EnvironmentObject var repo: ContentRepository
    @State private var episodes: [Episode]?
    @State private var info: TmdbInfo?
    @State private var season: Int?
    @State private var saved = false

    private var seasons: [Int] { Array(Set((episodes ?? []).map { $0.season })).sorted() }
    private var selected: Int { season ?? seasons.first ?? 0 }
    private var epsForSeason: [Episode] {
        (episodes ?? []).filter { $0.season == selected }.sorted { $0.episodeNum < $1.episodeNum }
    }
    private var allOrdered: [Episode] {
        (episodes ?? []).sorted { ($0.season, $0.episodeNum) < ($1.season, $1.episodeNum) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white).padding(8) }
                Spacer()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let img = info?.backdrop ?? info?.poster {
                        RemoteImage(url: img, contentMode: .fill) { Color.darkSurface2 }
                            .aspectRatio(16.0/9.0, contentMode: .fill).frame(maxWidth: .infinity).frame(height: 200).clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    Text(title).font(.title2.bold()).foregroundStyle(.white)
                    HStack {
                        if let y = info?.year, !y.isEmpty { Text(y).foregroundStyle(Color.textSecondary) }
                        if let r = info?.rating, r > 0 { Text("★ \(String(format: "%.1f", r))").fontWeight(.bold).foregroundStyle(Color.hotOrange) }
                    }
                    if let o = info?.overview, !o.isEmpty { Text(o).font(.footnote).foregroundStyle(.white).lineLimit(8) }

                    if !seasons.isEmpty {
                        Menu {
                            ForEach(seasons, id: \.self) { s in Button(seasonLabel(s)) { season = s } }
                        } label: {
                            HStack { Text(seasonLabel(selected)).fontWeight(.bold).foregroundStyle(.white); Image(systemName: "chevron.down").foregroundStyle(.white) }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(LinearGradient.brandCard).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }

                    Button {
                        saved = WatchLaterStore.toggle(WatchLaterItem(kind: .series, streamId: seriesId, name: title, poster: info?.poster, url: "", group: nil))
                    } label: {
                        Label(saved ? "  Saved" : "  Watch Later", systemImage: saved ? "checkmark" : "clock")
                            .foregroundStyle(.white).padding(.horizontal, 18).frame(height: 44).overlay(Capsule().stroke(Color.white, lineWidth: 1))
                    }

                    episodesPane
                }
                .padding(.horizontal, 16).padding(.bottom, 20)
            }
        }
        .background(Color.darkBg)
        .task {
            saved = WatchLaterStore.contains(.series, seriesId)
            episodes = await repo.xtream?.getEpisodes(seriesId: seriesId) ?? []
            info = await TmdbClient.fetch(title: title, series: true)
            if season == nil { season = seasons.first }
        }
    }

    @ViewBuilder
    private var episodesPane: some View {
        if episodes == nil {
            ProgressView().tint(.hotRed).frame(maxWidth: .infinity).padding()
        } else if (episodes ?? []).isEmpty {
            Text("No episodes found.").foregroundStyle(Color.textSecondary).frame(maxWidth: .infinity).padding()
        } else {
            VStack(spacing: 8) {
                ForEach(epsForSeason) { ep in episodeRow(ep) }
            }
        }
    }

    private func episodeRow(_ ep: Episode) -> some View {
        Button { playFromQueue(ep) } label: {
            HStack(spacing: 12) {
                ZStack {
                    RemoteImage(url: ep.cover.nonBlank, contentMode: .fill) {
                        ZStack { Color.darkSurface2; Image(systemName: "play.fill").foregroundStyle(Color.hotRed) }
                    }
                }
                .frame(width: 92, height: 52).clipped().clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(ep.episodeNum > 0 ? "E\(ep.episodeNum)  \(ep.title)" : ep.title).fontWeight(.bold).foregroundStyle(.white).lineLimit(1)
                    if !ep.plot.isEmpty { Text(ep.plot).font(.footnote).foregroundStyle(Color.textSecondary).lineLimit(2) }
                }
                Spacer()
                Image(systemName: "play.fill").foregroundStyle(Color.hotRed)
            }
            .padding(10)
            .background(LinearGradient.brandCard).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func playFromQueue(_ ep: Episode) {
        let queue = allOrdered.map { ContentRepository.PlayItem(id: $0.id, title: $0.title, url: $0.url) }
        repo.setSeriesQueue(queue, index: allOrdered.firstIndex { $0.id == ep.id } ?? 0)
        onPlay(ep.url, ep.title, ep.id)
    }

    private func seasonLabel(_ s: Int) -> String { s <= 0 ? "All episodes" : "Season \(s)" }
}
