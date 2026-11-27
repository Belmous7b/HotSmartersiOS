import Foundation

/// In-app update check. The panel exposes an app-version/url. On iOS there is no
/// sideload, so the UI shows an "Update available" prompt linking to the download
/// / App Store URL (mirrors the intent of the Android `AppUpdater`).
enum AppUpdater {
    struct Info {
        let versionCode: Int64
        let versionName: String
        let url: String
        let notes: String
        let mandatory: Bool
    }

    /// The current app's build number.
    static func currentCode() -> Int64 {
        let v = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return Int64(v) ?? 0
    }

    /// Returns update info only when the server has a NEWER version with a valid URL.
    static func check() async -> Info? {
        if ApiKeys.panel.isEmpty { return nil }
        let base = ApiKeys.panel.hasSuffix("/") ? String(ApiKeys.panel.dropLast()) : ApiKeys.panel
        guard let body = await Http.getString("\(base)/api/app-version"), let o = JSON.object(body) else { return nil }
        let code = o.optLong("versionCode")
        // Prefer an iOS/App Store URL; fall back to apkUrl field used by Android.
        let url = (o.optString("iosUrl").nonBlank ?? o.optString("appStoreUrl").nonBlank ?? o.optString("apkUrl")).trimmingCharacters(in: .whitespaces)
        if url.isEmpty || code <= currentCode() { return nil }
        return Info(versionCode: code, versionName: o.optString("versionName").trimmingCharacters(in: .whitespaces),
                    url: url, notes: o.optString("notes").trimmingCharacters(in: .whitespaces),
                    mandatory: o.optBool("mandatory"))
    }
}
