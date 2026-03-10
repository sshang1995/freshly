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
                    Text("Stay Ahead of Expiry")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Enable notifications to get timely reminders before your items expire.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 12) {
                    notifExample(icon: "bell.fill", color: .orange, title: "Expiring Soon", body: "Milk expires in 3 days")
                    notifExample(icon: "exclamationmark.triangle.fill", color: .red, title: "Expires Today", body: "Yogurt expires today!")
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
