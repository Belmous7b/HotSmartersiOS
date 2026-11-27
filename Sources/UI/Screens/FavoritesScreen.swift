import SwiftUI

/// Saved favorites with folder chips; play/open or remove. Mirrors Android `FavoritesScreen`.
struct FavoritesScreen: View {
    let onBack: () -> Void
    let onPlay: (FavItem) -> Void

    @State private var folders: [FavFolder] = []
    @State private var selected = FavoritesStore.defaultFolderId
    @State private var items: [FavItem] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white) }
                Text("Favorites").font(.headline).foregroundStyle(.white)
                Spacer()
                if selected != FavoritesStore.defaultFolderId {
                    Button {
                        FavoritesStore.deleteFolder(selected)
                        selected = FavoritesStore.defaultFolderId
                        refresh()
                    } label: { Image(systemName: "trash").foregroundStyle(.white) }
                }
            }
            .padding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(folders) { f in
                        folderChip(f.name, selected == f.id) { selected = f.id; items = FavoritesStore.itemsInFolder(f.id) }
                    }
                }
                .padding(12)
            }

            if items.isEmpty {
                Text("No favorites in this folder yet.").foregroundStyle(Color.textSecondary).frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items) { fav in favRow(fav) }
                    }
                }
            }
        }
        .background(Color.darkBg)
        .task { refresh() }
    }

    private func folderChip(_ name: String, _ sel: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(name).fontWeight(sel ? .bold : .regular).foregroundStyle(sel ? .white : .white)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(sel ? Color.hotRed : Color.darkSurface).clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func favRow(_ fav: FavItem) -> some View {
        Button { onPlay(fav) } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill").foregroundStyle(Color.hotRed)
                Text(fav.name).foregroundStyle(.white).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    FavoritesStore.removeFrom(fav.folderId, fav.kind, fav.streamId); refresh()
                } label: { Image(systemName: "trash").foregroundStyle(Color.textSecondary) }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func refresh() {
        folders = FavoritesStore.folders()
        items = FavoritesStore.itemsInFolder(selected)
    }
}
