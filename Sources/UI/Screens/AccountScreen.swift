import SwiftUI
import PhotosUI
import UIKit

/// Shows activation status/plan/expiry, device MAC + key, profile and stats.
/// Mirrors Android `AccountScreen`.
struct AccountScreen: View {
    let onBack: () -> Void

    @EnvironmentObject var repo: ContentRepository
    @EnvironmentObject var activation: ActivationStore

    @State private var name = ""
    @State private var avatarPath = ""
    @State private var editName = false
    @State private var tempName = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var screenTime = ""
    @State private var favCount = 0
    @State private var playlists: [Playlist] = []

    private var plan: String { activation.current?.plan ?? "" }
    private var planLabel: String {
        switch plan { case "half_year": return "6 Months"; case "year": return "1 Year"
        case "lifetime": return "Lifetime"; case "trial": return "Trial"; case "": return "—"; default: return plan }
    }
    private var expiry: String {
        if plan == "lifetime" { return "Lifetime" }
        if let e = activation.current?.expiresAt { return String(e.prefix(10)) }
        return "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Image(systemName: "arrow.left").foregroundStyle(.white) }
                Text("Account").font(.headline).foregroundStyle(.white)
                Spacer()
            }
            .padding()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            ZStack {
                                if !avatarPath.isEmpty, let img = loadAvatar(avatarPath) {
                                    Image(uiImage: img).resizable().scaledToFill()
                                } else {
                                    Text(String(name.prefix(1)).ifBlank("?").uppercased()).font(.title).foregroundStyle(Color.hotRed)
                                }
                            }
                            .frame(width: 84, height: 84).background(Color.darkSurface2).clipShape(Circle())
                        }
                        VStack(alignment: .leading) {
                            HStack {
                                Text(name.ifBlank("Guest")).font(.title2.bold()).foregroundStyle(.white)
                                Button { tempName = name; editName = true } label: { Image(systemName: "pencil").foregroundStyle(.white) }
                            }
                            Text("Tap the photo to change it").font(.caption).foregroundStyle(Color.textSecondary)
                        }
                    }

                    sectionTitle("Your stats")
                    statRow("Screen time", screenTime)
                    statRow("Playlists", "\(playlists.count)")
                    statRow("Favorites", "\(favCount)")
                    statRow("Current library", "\(repo.live.count) live • \(repo.movies.count) movies • \(repo.series.count) series")

                    sectionTitle("Device")
                    statRow("MAC", DeviceId.get())
                    statRow("Key", DeviceId.key())
                    statRow("Subscription", planLabel)
                    statRow("Expires", expiry)
                    statRow("Playlist", repo.sourceLabel.ifBlank("—"))

                    sectionTitle("Your playlists")
                    if playlists.isEmpty {
                        Text("None yet.").font(.footnote).foregroundStyle(Color.textSecondary)
                    } else {
                        ForEach(playlists) { p in statRow(p.name, p.type.rawValue.lowercased().capitalized) }
                    }
                }
                .padding(20)
            }
        }
        .background(Color.darkBg)
        .task { reload() }
        .onChange(of: photoItem) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    if let path = saveAvatar(data) { Prefs.setProfileAvatar(path); avatarPath = path }
                }
            }
        }
        .appDialog(isPresented: $editName) {
            AppDialogCard(title: "Your name", confirmText: "Save",
                          onConfirm: { Prefs.setProfileName(tempName.trimmingCharacters(in: .whitespaces)); name = tempName.trimmingCharacters(in: .whitespaces); editName = false },
                          dismissText: "Cancel", onDismiss: { editName = false }) {
                TextField("Name", text: $tempName).padding(12).background(Color.darkSurface2).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(.white)
            }
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(t).font(.headline).foregroundStyle(.white)
            Divider().background(Color.darkSurface2)
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.textSecondary).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundStyle(.white).lineLimit(1)
        }
        .padding(.vertical, 4)
    }

    private func reload() {
        name = Prefs.profileName()
        avatarPath = Prefs.profileAvatar()
        screenTime = StatsStore.formatted()
        favCount = FavoritesStore.items().count
        playlists = Prefs.playlists()
    }

    private func loadAvatar(_ path: String) -> UIImage? { UIImage(contentsOfFile: path) }

    private func saveAvatar(_ data: Data) -> String? {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("avatar_\(Int(Date().timeIntervalSince1970)).jpg")
        do { try data.write(to: file); return file.path } catch { return nil }
    }
}
