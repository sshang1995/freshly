import SwiftUI

extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func sectionHeaderStyle() -> some View {
        self
            .font(.headline)
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
