import SwiftUI

struct OnboardingNotifView: View {
    @Binding var notificationsEnabled: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                    .padding(20)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Circle())
                    .padding(.top, 32)

                VStack(spacing: 10) {
                    Text(L("onboarding.notif.title"))
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text(L("onboarding.notif.subtitle"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 12) {
                    notifExample(
                        icon: "bell.fill", color: .orange,
                        title: L("onboarding.notif.example1.title"),
                        body: L("onboarding.notif.example1.body")
                    )
                    notifExample(
                        icon: "exclamationmark.triangle.fill", color: .red,
                        title: L("onboarding.notif.example2.title"),
                        body: L("onboarding.notif.example2.body")
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .padding(.horizontal)
        }
    }

    private func notifExample(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Text(body).font(.caption).foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
