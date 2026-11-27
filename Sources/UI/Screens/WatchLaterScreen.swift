import SwiftUI

/// Saved movies/series (per-playlist). A movie plays immediately; a series opens
/// its page. Mirrors Android `WatchLaterScreen`.
struct WatchLaterScreen: View {
    let onBack: () -> Void
    let onOpen: (WatchLaterItem) -> Void
    @State private var items: [WatchLaterItem] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white) }
                Text(tr("Watch Later")).font(.headline).foregroundStyle(.white)
                Spacer()
            }
            .padding()

            if items.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 56)).foregroundStyle(Color.textSecondary)
                    Text(tr("Nothing saved yet.")).fontWeight(.bold).foregroundStyle(.white).padding(.top, 12)
                    Text(tr("Open any movie or series and tap Watch Later to save it here."))
                        .font(.footnote).foregroundStyle(Color.textSecondary).multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { item in row(item) }
                    }
                    .padding(12)
                }
            }
        }
        .background(Color.darkBg)
        .task { items = WatchLaterStore.items() }
    }

    private func row(_ item: WatchLaterItem) -> some View {
        Button { onOpen(item) } label: {
            HStack(spacing: 12) {
                RemoteImage(url: item.poster, contentMode: .fill) {
                    ZStack { Color.darkSurface2; Text(String(item.name.prefix(1)).uppercased()).fontWeight(.bold).foregroundStyle(.white) }
                }
                .frame(width: 64, height: 91).clipped().clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).fontWeight(.bold).foregroundStyle(.white).lineLimit(1)
                    Text(item.kind == .series ? tr("Series") : tr("Movie")).font(.footnote).foregroundStyle(Color.textSecondary)
                }
                Spacer()
                Button {
                    WatchLaterStore.remove(item.kind, item.streamId)
                    items = WatchLaterStore.items()
                } label: { Image(systemName: "trash").foregroundStyle(Color.textSecondary) }
            }
            .padding(8)
        }
        .buttonStyle(.plain)
    }
}
