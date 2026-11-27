import Foundation
import Combine

/// One selectable app language. `rtl` marks right-to-left scripts (Arabic).
struct AppLang: Identifiable, Hashable {
    var id: String { code }
    let display: String
    let code: String
    var rtl = false
}

/// App-wide language / translation engine. Mirrors the Android `I18n`.
/// `current` is observable, so changing the language flips the whole UI (the root
/// re-renders via `.id(current)`), falling back to English for missing strings.
final class I18n: ObservableObject {
    static let shared = I18n()
    private init() { current = Prefs.language() }

    /// The 14 most widely used world languages. Arabic is right-to-left.
    static let languages: [AppLang] = [
        AppLang(display: "English", code: "en"),
        AppLang(display: "Français", code: "fr"),
        AppLang(display: "العربية", code: "ar", rtl: true),
        AppLang(display: "Español", code: "es"),
        AppLang(display: "Deutsch", code: "de"),
        AppLang(display: "Italiano", code: "it"),
        AppLang(display: "Português", code: "pt"),
        AppLang(display: "Türkçe", code: "tr"),
        AppLang(display: "Русский", code: "ru"),
        AppLang(display: "हिन्दी", code: "hi"),
        AppLang(display: "中文", code: "zh"),
        AppLang(display: "日本語", code: "ja"),
        AppLang(display: "Nederlands", code: "nl"),
        AppLang(display: "Polski", code: "pl"),
    ]

    @Published var current: String = "English"

    var currentLang: AppLang {
        I18n.languages.first { $0.display == current } ?? I18n.languages[0]
    }

    var isRtl: Bool { currentLang.rtl }

    func set(_ display: String) {
        current = display
        Prefs.setLanguage(display)
    }

    /// Translate an English source string into the current language.
    func t(_ en: String) -> String {
        let code = currentLang.code
        if code == "en" { return en }
        return Translations.map[en]?[code] ?? en
    }
}

/// Short alias so call sites read `tr("Settings")`.
func tr(_ en: String) -> String { I18n.shared.t(en) }
