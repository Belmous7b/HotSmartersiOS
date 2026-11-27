import SwiftUI
import UIKit

@main
struct HotSmartersApp: App {
    @StateObject private var router = Router()
    @StateObject private var i18n = I18n.shared
    @StateObject private var repo = ContentRepository.shared
    @StateObject private var activation = ActivationStore.shared

    init() {
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
                // Changing the language flips the WHOLE UI instantly (re-renders the tree).
                .id(i18n.current)
        }
    }
}

/// Wraps the app in the activation gate + the navigation stack, on the app's
/// near-black background.
struct RootView: View {
    var body: some View {
        ZStack {
            Color.darkBg.ignoresSafeArea()
            ActivationGate {
                RootNavigationView()
            }
        }
    }
}
