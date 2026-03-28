import SwiftUI
import SwiftData

@main
struct ExpiredItemApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var settings = AppSettings.shared
    @State private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingContainerView()
                }
            }
            .id(languageManager.selectedLanguage)
            .environment(settings)
            .environment(languageManager)
        }
        .modelContainer(ModelContainerFactory.shared.container)
    }
}
