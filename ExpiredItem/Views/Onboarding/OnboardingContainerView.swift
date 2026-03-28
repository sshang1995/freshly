import SwiftUI

struct OnboardingContainerView: View {
    @Environment(AppSettings.self) private var settings
    @State private var currentPage = 0
    @State private var notificationsEnabled = true
    @State private var defaultReminderDays = 3

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingWelcomeView()
                    .tag(0)

                OnboardingNotifView(notificationsEnabled: $notificationsEnabled)
                    .tag(1)

                OnboardingReminderView(defaultReminderDays: $defaultReminderDays)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            VStack(spacing: 20) {
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.4))
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }

                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(L("onboarding.back")) {
                            withAnimation { currentPage -= 1 }
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }

                    Button(currentPage < totalPages - 1 ? L("onboarding.next") : L("onboarding.getStarted")) {
                        if currentPage < totalPages - 1 {
                            if currentPage == 1 {
                                Task { await requestNotifications() }
                            }
                            withAnimation { currentPage += 1 }
                        } else {
                            finishOnboarding()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
            .padding(.top, 16)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func requestNotifications() async {
        if notificationsEnabled {
            let granted = await NotificationService.shared.requestPermission()
            settings.notificationsEnabled = granted
        }
    }

    private func finishOnboarding() {
        settings.defaultReminderDays = defaultReminderDays
        settings.hasCompletedOnboarding = true
    }
}
