import SwiftUI
import AVKit
import Combine
import UIKit

/// Owns the AVPlayer and all IPTV-tuned behaviour: custom VLC User-Agent, resume,
/// silent auto-reconnect, keep-awake, progress reporting, and an external-subtitle
/// overlay with time-shift. The equivalent of the Android ExoPlayer `VideoPlayer`.
@MainActor
final class PlayerController: ObservableObject {
    let player = AVPlayer()

    @Published var isPlaying = false
    @Published var positionMs: Int64 = 0
    @Published var durationMs: Int64 = 0
    @Published var currentSubtitle: String = ""

    var videoGravity: AVLayerVideoGravity = .resizeAspect

    /// Called when playback reaches the end (powers auto-play-next).
    var onEnded: () -> Void = {}
    /// Called ~1/s with (positionMs, durationMs) (powers the next-episode prompt).
    var onProgress: (Int64, Int64) -> Void = { _, _ in }

    private var resumeId = ""
    private var currentUrl = ""
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var retries = 0
    private var accumulatedMs: Int64 = 0
    private var lastResumeAt: Date?

    // External subtitles
    private var cues: [(start: Int64, end: Int64, text: String)] = []
    private var originalSrt: String?
    private(set) var subtitleOffsetMs: Int64 = 0

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        player.allowsExternalPlayback = false   // hides the native AirPlay button
    }

    // MARK: - Embedded audio / subtitle tracks (multi-language streams)

    private func group(_ characteristic: AVMediaCharacteristic) -> AVMediaSelectionGroup? {
        player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: characteristic)
    }

    var audioOptions: [AVMediaSelectionOption] { group(.audible)?.options ?? [] }
    var subtitleOptions: [AVMediaSelectionOption] { group(.legible)?.options ?? [] }

    func selectedAudio() -> AVMediaSelectionOption? {
        guard let item = player.currentItem, let g = group(.audible) else { return nil }
        return item.currentMediaSelection.selectedMediaOption(in: g)
    }
    func selectedSubtitle() -> AVMediaSelectionOption? {
        guard let item = player.currentItem, let g = group(.legible) else { return nil }
        return item.currentMediaSelection.selectedMediaOption(in: g)
    }
    func selectAudio(_ opt: AVMediaSelectionOption) {
        if let g = group(.audible) { player.currentItem?.select(opt, in: g) }
    }
    /// Pass nil to turn subtitles off.
    func selectSubtitle(_ opt: AVMediaSelectionOption?) {
        if let g = group(.legible) { player.currentItem?.select(opt, in: g) }
    }

    // MARK: - Loading

    func load(url: String, resumeId: String = "") {
        currentUrl = url
        self.resumeId = resumeId
        retries = 0
        guard let u = URL(string: url) else { return }

        let asset = AVURLAsset(url: u, options: [
            "AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": Http.userAgent]
        ])
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)

        observe(item: item)
        if !resumeId.isEmpty {
            let pos = ResumeStore.position(resumeId)
            if pos > 0 { player.seek(to: CMTime(value: pos, timescale: 1000)) }
        }
        player.play()
        isPlaying = true
        lastResumeAt = Date()
        keepAwake(true)
    }

    private func observe(item: AVPlayerItem) {
        statusObserver?.invalidate()
        statusObserver = item.observe(\.status) { [weak self] item, _ in
            guard let self else { return }
            if item.status == .failed { Task { @MainActor in self.retry() } }
        }

        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.onEnded() }
        }

        if timeObserver == nil {
            timeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(value: 1, timescale: 2), queue: .main
            ) { [weak self] time in
                guard let self else { return }
                let pos = Int64(time.seconds.isFinite ? time.seconds * 1000 : 0)
                let dur = self.player.currentItem?.duration.seconds ?? 0
                self.positionMs = pos
                self.durationMs = dur.isFinite && dur > 0 ? Int64(dur * 1000) : 0
                self.isPlaying = self.player.timeControlStatus == .playing
                if self.durationMs > 0 { self.onProgress(pos, self.durationMs) }
                self.updateSubtitle(pos)
            }
        }
    }

    private func retry() {
        guard retries < 5 else { return }
        retries += 1
        let pos = resumeId.isEmpty ? 0 : positionMs // live → live edge
        guard let u = URL(string: currentUrl) else { return }
        let asset = AVURLAsset(url: u, options: ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": Http.userAgent]])
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        observe(item: item)
        if pos > 0 { player.seek(to: CMTime(value: pos, timescale: 1000)) }
        player.play()
    }

    // MARK: - Transport

    func togglePlayPause() {
        if player.timeControlStatus == .playing { player.pause(); isPlaying = false }
        else { player.play(); isPlaying = true }
    }

    func seek(toFraction f: Double) {
        guard durationMs > 0 else { return }
        player.seek(to: CMTime(value: Int64(Double(durationMs) * f), timescale: 1000))
    }

    func skip(_ seconds: Double) {
        let now = player.currentTime().seconds
        player.seek(to: CMTime(seconds: max(now + seconds, 0), preferredTimescale: 1000))
    }

    // MARK: - External subtitles (OpenSubtitles + time-shift)

    func applyExternalSrt(_ srt: String, offsetMs: Int64 = 0) {
        originalSrt = srt
        subtitleOffsetMs = offsetMs
        cues = SrtParser.parse(SubtitleShifter.shift(srt, offsetMs: offsetMs))
    }

    func shiftSubtitle(step: Int) {
        guard let orig = originalSrt else { return }
        subtitleOffsetMs = step == 0 ? 0 : subtitleOffsetMs + Int64(step) * 500
        cues = SrtParser.parse(SubtitleShifter.shift(orig, offsetMs: subtitleOffsetMs))
    }

    var hasExternalSubtitle: Bool { originalSrt != nil }

    private func updateSubtitle(_ pos: Int64) {
        guard !cues.isEmpty else { if !currentSubtitle.isEmpty { currentSubtitle = "" }; return }
        let text = cues.first { pos >= $0.start && pos <= $0.end }?.text ?? ""
        if text != currentSubtitle { currentSubtitle = text }
    }

    // MARK: - Lifecycle

    func teardown() {
        if lastResumeAt != nil { accumulatedMs += Int64(Date().timeIntervalSince(lastResumeAt!) * 1000) }
        StatsStore.addWatchMs(accumulatedMs)
        if !resumeId.isEmpty {
            ResumeStore.save(resumeId, positionMs: positionMs, durationMs: durationMs)
        }
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        statusObserver?.invalidate()
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        player.pause()
        player.replaceCurrentItem(with: nil)
        keepAwake(false)
    }

    private func keepAwake(_ on: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = on
        #endif
    }
}

/// Minimal SRT cue parser used for external-subtitle overlay.
enum SrtParser {
    static func parse(_ srt: String) -> [(start: Int64, end: Int64, text: String)] {
        var out: [(Int64, Int64, String)] = []
        let blocks = srt.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n\n")
        for block in blocks {
            let lines = block.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard let timeLineIdx = lines.firstIndex(where: { $0.contains("-->") }) else { continue }
            let parts = lines[timeLineIdx].components(separatedBy: "-->")
            guard parts.count == 2 else { continue }
            let start = ms(parts[0]); let end = ms(parts[1])
            let text = lines[(timeLineIdx + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if end > 0 && !text.isEmpty { out.append((start, end, text)) }
        }
        return out
    }

    private static func ms(_ s: String) -> Int64 {
        let t = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ":").replacingOccurrences(of: ".", with: ":")
        let p = t.components(separatedBy: ":").compactMap { Int64($0) }
        guard p.count == 4 else { return 0 }
        return ((p[0] * 60 + p[1]) * 60 + p[2]) * 1000 + p[3]
    }
}
