import SwiftUI

struct CategoryIconView: View {
    let category: Category
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(category.gradient)
                .frame(width: size, height: size)
            Image(systemName: category.icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(color: category.color.opacity(0.3), radius: 4, y: 2)
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))]) {
        ForEach(Category.allCases) { cat in
            VStack(spacing: 6) {
                CategoryIconView(category: cat, size: 48)
                Text(cat.displayName).font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
    .padding()
}
