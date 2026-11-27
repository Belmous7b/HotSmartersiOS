import SwiftUI
import AVKit

/// Hosts an `AVPlayerViewController` for a `PlayerController`. Native controls give
/// play/pause, scrubbing, and embedded audio/subtitle track selection for free;
/// the caller overlays extra UI (external subtitles, next-episode) on top.
struct VideoPlayerView: UIViewControllerRepresentable {
    @ObservedObject var controller: PlayerController
    var showControls: Bool = true
    var gravity: AVLayerVideoGravity = .resizeAspect

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = controller.player
        vc.showsPlaybackControls = showControls
        vc.videoGravity = gravity
        vc.allowsPictureInPicturePlayback = false
        vc.view.backgroundColor = .black
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        vc.showsPlaybackControls = showControls
        vc.videoGravity = gravity
        if vc.player !== controller.player { vc.player = controller.player }
    }
}

/// Maps the "video fit" preference to an AVLayer gravity.
func gravityForFit(_ fit: String, forcedFill: Bool = false) -> AVLayerVideoGravity {
    if forcedFill { return .resizeAspectFill }
    switch fit {
    case "Fill": return .resizeAspectFill
    case "Stretch": return .resize
    default: return .resizeAspect
    }
}
