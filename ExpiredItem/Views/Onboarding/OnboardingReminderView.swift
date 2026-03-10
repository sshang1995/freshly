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
                    Text("Set Your Default Reminder")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("How many days before expiry would you like to be reminded by default?")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 16) {
                    Text("\(defaultReminderDays) day\(defaultReminderDays == 1 ? "" : "s") before expiry")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Stepper("", value: $defaultReminderDays, in: 1...14)
                        .labelsHidden()

                    Text("You can customize this per-item when adding it.")
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
