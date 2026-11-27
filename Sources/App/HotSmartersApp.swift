import SwiftUI
import UIKit

@main
struct HotSmartersApp: App {
    @StateObject private var router = Router()
    @StateObject private var i18n = I18n.shared
    @StateObject private var repo = ContentRepository.shared
    @StateObject private var activation = ActivationStore.shared

    init() {
        // Big on-disk HTTP cache so posters/logos load once and come back instantly
        // afterwards (AsyncImage/URLSession re-download every time without this).
        URLCache.shared = URLCache(memoryCapacity: 64 * 1024 * 1024,
                                   diskCapacity: 512 * 1024 * 1024)
        // Lock adult categories by default (PIN "0000") on first run.
        Prefs.ensureDefaultParental()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .environmentObject(i18n)
                .environmentObject(repo)
                .environmentObject(activation)
                .environment(\.layoutDirection, i18n.isRtl ? .rightToLeft : .leftToRight)
                .preferredColorScheme(.dark)
                // Keep the dense TV-style layout at its design size on every device:
                // a large system / accessibility text size must not inflate the UI.
                .dynamicTypeSize(.large)
                // Changing the language flips the WHOLE UI instantly (re-renders the tree).
                .id(i18n.current)
        }
    }
}

/// Wraps the app in the activation gate + the navigation stack, on the app's
/// near-black background.
struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()
            ActivationGate {
                RootNavigationView()
            }
        }
        // Re-sync with the panel each time the app comes back to the foreground, so
        // changes made on the panel (playlists added/removed) show up in the app.
        .onChange(of: scenePhase) { phase in
            if phase == .active { Task { await ActivationStore.shared.refresh() } }
        }
    }
}
