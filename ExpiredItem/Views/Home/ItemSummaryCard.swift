import SwiftUI

struct ItemSummaryCard: View {
    let status: ItemStatus
    let count: Int
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: status.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
            }

            Spacer(minLength: 8)

            Text("\(count)")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text(status.cardLabel)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .background(status.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: status.glowColor, radius: isSelected ? 14 : 7, x: 0, y: isSelected ? 6 : 3)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: isSelected)
    }
}

#Preview {
    HStack {
        ItemSummaryCard(status: .expired, count: 1)
        ItemSummaryCard(status: .expiringSoon, count: 2, isSelected: true)
        ItemSummaryCard(status: .fresh, count: 5)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
