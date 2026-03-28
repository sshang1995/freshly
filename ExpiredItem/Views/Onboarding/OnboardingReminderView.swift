import SwiftUI

struct OnboardingReminderView: View {
    @Binding var defaultReminderDays: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(20)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Circle())
                    .padding(.top, 32)

                VStack(spacing: 10) {
                    Text(L("onboarding.reminder.title"))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(L("onboarding.reminder.subtitle"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 16) {
                    let days = defaultReminderDays
                    Text(Lf(days == 1 ? "form.reminder.dayBefore" : "form.reminder.daysBefore", days))
                        .font(.title2)
                        .fontWeight(.semibold)

                    Stepper("", value: $defaultReminderDays, in: 1...14)
                        .labelsHidden()

                    Text(L("onboarding.reminder.customizeNote"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
    }
}
