import SwiftUI
import AVKit

/// Full-screen player: native AVPlayer controls (play/pause, scrub, embedded
/// audio/subtitle tracks), resume, keep-awake, auto-play-next episode, a
/// next-episode prompt, and external OpenSubtitles with time-shift.
/// Mirrors Android `PlayerScreen` + the ExoPlayer controls.
struct PlayerScreen: View {
    let url: String
    let title: String
    var resumeId: String = ""
    let onBack: () -> Void

    @EnvironmentObject var repo: ContentRepository
    @StateObject private var player = PlayerController()

    @State private var qIndex = 0
    @State private var currentUrl: String
    @State private var currentTitle: String
    @State private var currentResume: String
    @State private var nearEnd = false
    @State private var showSubMenu = false
    @State private var subStatus: String?
    @State private var queue: [ContentRepository.PlayItem] = []
    @State private var isSeries = false

    init(url: String, title: String, resumeId: String = "", onBack: @escaping () -> Void) {
        self.url = url; self.title = title; self.resumeId = resumeId; self.onBack = onBack
        _currentUrl = State(initialValue: url)
        _currentTitle = State(initialValue: title)
        _currentResume = State(initialValue: resumeId)
    }

    private var hasNext: Bool { isSeries && qIndex < queue.count - 1 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VideoPlayerView(controller: player, showControls: true, gravity: gravityForFit(Prefs.videoFit()))
                .ignoresSafeArea()

            // External subtitle overlay (native embedded subs render themselves).
            if !player.currentSubtitle.isEmpty {
                VStack {
                    Spacer()
                    Text(player.currentSubtitle)
                        .font(.title3).foregroundStyle(.white).multilineTextAlignment(.center)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.black.opacity(0.5))
                        .padding(.bottom, 80)
                }
                .allowsHitTesting(false)
            }

            VStack {
                HStack {
                    Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white).padding(12) }
                    Spacer()
                    Text(title).foregroundStyle(.white).fontWeight(.bold).lineLimit(1)
                    Spacer()
                    Button { showSubMenu = true } label: { Image(systemName: "captions.bubble").foregroundStyle(.white).padding(12) }
                }
                Spacer()
            }

            if nearEnd && hasNext {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: goNext) {
                            Label("Next episode", systemImage: "forward.end.fill").fontWeight(.bold).foregroundStyle(.white)
                                .padding(.horizontal, 22).padding(.vertical, 12).background(Color.hotRed).clipShape(Capsule())
                        }
                        .padding(24)
                    }
                }
            }
        }
        .confirmationDialog("Subtitles", isPresented: $showSubMenu, titleVisibility: .visible) {
            Button("Download English subtitles") { fetchSub("en") }
            Button("Download French subtitles") { fetchSub("fr") }
            Button("Download Arabic subtitles") { fetchSub("ar") }
            Button("Download Spanish subtitles") { fetchSub("es") }
            if player.hasExternalSubtitle {
                Button("Subtitle delay +0.5s") { player.shiftSubtitle(step: 1) }
                Button("Subtitle delay −0.5s") { player.shiftSubtitle(step: -1) }
                Button("Reset delay") { player.shiftSubtitle(step: 0) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(subStatus ?? "Pick embedded tracks from the player's own menu, or fetch external subtitles here.")
        }
        .onAppear {
            let q = repo.playQueue
            let idx = repo.playIndex
            queue = q
            qIndex = idx
            isSeries = !q.isEmpty && q.indices.contains(idx) && q[idx].id == resumeId
            player.onEnded = { if Prefs.autoPlayNext() { goNext() } }
            player.onProgress = { pos, dur in
                nearEnd = hasNext && dur > 0 && pos >= dur - 120_000
            }
            player.load(url: currentUrl, resumeId: currentResume)
        }
        .onDisappear { player.teardown() }
    }

    private func goNext() {
        guard isSeries && qIndex < queue.count - 1 else { return }
        qIndex += 1
        let n = queue[qIndex]
        currentUrl = n.url; currentTitle = n.title; currentResume = n.id
        nearEnd = false
        HistoryStore.record(HistoryItem(kind: .series, streamId: n.id, name: n.title, poster: nil, url: n.url, group: nil))
        player.load(url: n.url, resumeId: n.id)
    }

    private func fetchSub(_ lang: String) {
        subStatus = "Searching subtitles…"
        Task {
            if let link = await OpenSubtitlesClient.fetch(title: currentTitle, lang: lang),
               let srt = await Http.getString(link) {
                player.applyExternalSrt(srt)
                subStatus = "Subtitles loaded."
            } else {
                subStatus = "No subtitles found."
            }
        }
    }
}
