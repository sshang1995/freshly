import SwiftUI

struct OnboardingWelcomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .padding(20)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Circle())
                    .padding(.top, 32)

                VStack(spacing: 10) {
                    Text("Welcome to Freshly")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Never let food expire again. Track your items and get reminded before they go bad.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 14) {
                    featureRow(icon: "plus.circle.fill", color: .blue, title: "Track Items", description: "Add items with expiration dates")
                    featureRow(icon: "bell.fill", color: .orange, title: "Get Reminded", description: "Notifications before items expire")
                    featureRow(icon: "chart.bar.fill", color: .green, title: "Stay Organized", description: "Browse by status and category")
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}
