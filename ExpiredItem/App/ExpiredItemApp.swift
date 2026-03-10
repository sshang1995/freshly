import SwiftUI
import SwiftData

@main
struct ExpiredItemApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingContainerView()
            }
        }
        .modelContainer(ModelContainerFactory.shared.container)
        .environment(settings)
    }
}
