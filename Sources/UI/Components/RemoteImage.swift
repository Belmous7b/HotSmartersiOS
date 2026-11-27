import SwiftUI

/// Thin wrapper over AsyncImage so every poster/thumbnail across the app has the
/// same placeholder + fill/fit behaviour (equivalent to the Android Coil usage).
struct RemoteImage<Placeholder: View>: View {
    let url: String?
    var contentMode: ContentMode
    let placeholder: () -> Placeholder

    init(url: String?, contentMode: ContentMode = .fill, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.contentMode = contentMode
        self.placeholder = placeholder
    }

    var body: some View {
        if let s = url, let u = URL(string: s) {
            AsyncImage(url: u) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: contentMode)
                case .empty:
                    ZStack { Color.darkSurface2; ProgressView().tint(.hotRed) }
                default:
                    placeholder()
                }
            }
        } else {
            placeholder()
        }
    }
}

extension RemoteImage where Placeholder == Color {
    init(url: String?, contentMode: ContentMode = .fill) {
        self.init(url: url, contentMode: contentMode, placeholder: { Color.darkSurface2 })
    }
}
