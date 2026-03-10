import SwiftUI

struct StatusBadgeView: View {
    let status: ItemStatus

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: status.icon)
                .font(.system(size: 9, weight: .bold))
            Text(status.cardLabel)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(status.gradient)
        .clipShape(Capsule())
        .shadow(color: status.glowColor, radius: 4, y: 2)
    }
}

#Preview {
    HStack {
        StatusBadgeView(status: .fresh)
        StatusBadgeView(status: .expiringSoon)
        StatusBadgeView(status: .expired)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
