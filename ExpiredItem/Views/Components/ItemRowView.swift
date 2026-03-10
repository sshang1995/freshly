import SwiftUI

struct ItemRowView: View {
    let item: Item

    var body: some View {
        HStack(spacing: 14) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(item.status.gradient)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            CategoryIconView(category: item.category, size: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: item.location.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Text(item.location.displayName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                StatusBadgeView(status: item.status)

                Text(daysLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(item.status.color)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 12)
        .padding(.trailing, 14)
        .padding(.leading, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var daysLabel: String {
        let days = item.daysUntilExpiration
        switch days {
        case ..<0: return "\(abs(days))d ago"
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "\(days)d left"
        }
    }
}
