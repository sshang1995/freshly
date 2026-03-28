import Foundation

@Observable
final class LanguageManager {
    static let shared = LanguageManager()

    var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }

    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: selectedLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return .main }
        return bundle
    }

    func localized(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    struct Language {
        let code: String
        let nativeName: String
    }

    static let supported: [Language] = [
        Language(code: "en", nativeName: "English"),
        Language(code: "zh-Hans", nativeName: "中文"),
        Language(code: "es", nativeName: "Español"),
        Language(code: "fr", nativeName: "Français")
    ]

    private init() {
        selectedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "en"
    }
}

// MARK: - Convenience global helpers

func L(_ key: String) -> String {
    LanguageManager.shared.localized(key)
}

func Lf(_ key: String, _ args: CVarArg...) -> String {
    String(format: LanguageManager.shared.localized(key), arguments: args)
}
