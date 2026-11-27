import SwiftUI
import MobileVLCKit

/// VLC-backed player used for Live TV. Unlike AVPlayer, VLC decodes the MPEG-TS,
/// HLS and exotic audio/video codecs that real IPTV live streams use — which is
/// why the native player showed a broken-video icon for every channel.
@MainActor
final class VlcPlayerController: ObservableObject {
    let mediaPlayer = VLCMediaPlayer()
    private var currentUrl = ""

    /// Point VLC at the UIView it should render into.
    func attach(to view: UIView) {
        mediaPlayer.drawable = view
    }

    func load(url: String) {
        guard let u = URL(string: url) else { return }
        currentUrl = url
        let media = VLCMedia(url: u)
        // Match the Android player's User-Agent and give live streams a small buffer.
        media.addOption(":http-user-agent=\(Http.userAgent)")
        media.addOption(":network-caching=1500")
        media.addOption(":live-caching=1500")
        mediaPlayer.media = media
        mediaPlayer.play()
    }

    func reload() { if !currentUrl.isEmpty { load(url: currentUrl) } }

    func pause() { if mediaPlayer.isPlaying { mediaPlayer.pause() } }
    func resume() { if !mediaPlayer.isPlaying { mediaPlayer.play() } }

    func teardown() {
        mediaPlayer.stop()
        mediaPlayer.drawable = nil
    }
}

/// SwiftUI host for a `VlcPlayerController`'s video output.
///
/// `active` lets two views (the inline preview and a fullscreen cover) share ONE
/// player: only the active surface claims the VLC drawable, so entering/leaving
/// fullscreen just moves the output of the *same* running stream — instant, with
/// no reconnect or quality drop.
struct VlcPlayerView: UIViewRepresentable {
    @ObservedObject var controller: VlcPlayerController
    var active: Bool = true

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        if active { controller.attach(to: view) }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if active && (controller.mediaPlayer.drawable as? UIView) !== uiView {
            controller.attach(to: uiView)
        }
    }
}
