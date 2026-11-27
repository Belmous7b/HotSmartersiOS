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

            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Text(currentTitle).foregroundStyle(.white).fontWeight(.bold).lineLimit(1)
                    Spacer()
                    audioMenu
                    subtitleMenu
                    Button(action: onBack) { topIcon("xmark") }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                if let subStatus {
                    Text(subStatus).font(.caption).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.black.opacity(0.55), in: Capsule())
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

    // MARK: - Top-right controls

    private func topIcon(_ system: String) -> some View {
        Image(systemName: system).foregroundStyle(.white).frame(width: 40, height: 40)
            .background(Color.black.opacity(0.35), in: Circle())
    }

    private var audioMenu: some View {
        Menu {
            if player.audioOptions.isEmpty {
                Text("Single audio track")
            } else {
                ForEach(Array(player.audioOptions.enumerated()), id: \.offset) { _, opt in
                    Button {
                        player.selectAudio(opt)
                    } label: {
                        if player.selectedAudio() == opt { Label(opt.displayName, systemImage: "checkmark") }
                        else { Text(opt.displayName) }
                    }
                }
            }
        } label: { topIcon("waveform") }
    }

    private var subtitleMenu: some View {
        Menu {
            Button { player.selectSubtitle(nil) } label: {
                if player.selectedSubtitle() == nil { Label(tr("Off"), systemImage: "checkmark") } else { Text(tr("Off")) }
            }
            ForEach(Array(player.subtitleOptions.enumerated()), id: \.offset) { _, opt in
                Button {
                    player.selectSubtitle(opt)
                } label: {
                    if player.selectedSubtitle() == opt { Label(opt.displayName, systemImage: "checkmark") }
                    else { Text(opt.displayName) }
                }
            }
            Divider()
            Menu("Download subtitles") {
                Button("English") { fetchSub("en") }
                Button("Français") { fetchSub("fr") }
                Button("العربية") { fetchSub("ar") }
                Button("Español") { fetchSub("es") }
            }
            if player.hasExternalSubtitle {
                Button("Delay +0.5s") { player.shiftSubtitle(step: 1) }
                Button("Delay −0.5s") { player.shiftSubtitle(step: -1) }
                Button("Reset delay") { player.shiftSubtitle(step: 0) }
            }
        } label: { topIcon("captions.bubble") }
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
