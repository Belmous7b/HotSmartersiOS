import SwiftUI

/// Add-to-favorites dialog with folder checkboxes + new-folder field.
/// Mirrors the Android `FavoriteDialog`.
struct FavoriteDialog: View {
    let kind: MediaKind
    let streamId: String
    let name: String
    let poster: String?
    let url: String
    let group: String?
    let onDismiss: () -> Void

    @State private var folders: [FavFolder] = []
    @State private var membership: Set<String> = []
    @State private var newFolder = ""

    var body: some View {
        AppDialogCard(title: "Add to favorites", confirmText: "Done", onConfirm: onDismiss, dismissText: nil, onDismiss: onDismiss) {
            Text(name).lineLimit(1).foregroundStyle(.white)
            ForEach(folders) { folder in
                Button {
                    let checked = !membership.contains(folder.id)
                    if checked {
                        FavoritesStore.addTo(folder.id, FavItem(folderId: folder.id, kind: kind, streamId: streamId, name: name, poster: poster, url: url, group: group))
                    } else {
                        FavoritesStore.removeFrom(folder.id, kind, streamId)
                    }
                    membership = FavoritesStore.foldersContaining(kind, streamId)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: membership.contains(folder.id) ? "checkmark.square.fill" : "square")
                            .foregroundStyle(membership.contains(folder.id) ? Color.hotRed : Color.textSecondary)
                        Text(folder.name).foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
            HStack {
                TextField("New folder", text: $newFolder)
                    .padding(8).background(Color.darkSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 8)).foregroundStyle(.white)
                Button("Create") {
                    if !newFolder.trimmingCharacters(in: .whitespaces).isEmpty {
                        _ = FavoritesStore.createFolder(newFolder.trimmingCharacters(in: .whitespaces))
                        folders = FavoritesStore.folders()
                        newFolder = ""
                    }
                }
                .foregroundStyle(Color.hotRed)
            }
        }
        .onAppear {
            folders = FavoritesStore.folders()
            membership = FavoritesStore.foldersContaining(kind, streamId)
        }
    }
}
