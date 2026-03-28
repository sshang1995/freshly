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
                    Text(L("onboarding.welcome.title"))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(L("onboarding.welcome.subtitle"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 14) {
                    featureRow(icon: "plus.circle.fill", color: .blue,
                               title: L("onboarding.feature.track"),
                               description: L("onboarding.feature.track.desc"))
                    featureRow(icon: "bell.fill", color: .orange,
                               title: L("onboarding.feature.remind"),
                               description: L("onboarding.feature.remind.desc"))
                    featureRow(icon: "chart.bar.fill", color: .green,
                               title: L("onboarding.feature.organize"),
                               description: L("onboarding.feature.organize.desc"))
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
