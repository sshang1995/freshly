import SwiftUI

struct FilterView: View {
    @Bindable var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Category chips
                    filterSection(title: "Category") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                            chipButton(label: "All", icon: "square.grid.2x2", isSelected: viewModel.selectedCategory == nil) {
                                viewModel.selectedCategory = nil
                            }
                            ForEach(Category.allCases) { cat in
                                chipButton(label: cat.displayName, icon: cat.icon, isSelected: viewModel.selectedCategory == cat, color: cat.color) {
                                    viewModel.selectedCategory = cat
                                }
                            }
                        }
                    }

                    // Location chips
                    filterSection(title: "Location") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                            chipButton(label: "All", icon: "mappin.and.ellipse", isSelected: viewModel.selectedLocation == nil) {
                                viewModel.selectedLocation = nil
                            }
                            ForEach([Location.fridge, .freezer, .pantry, .cabinet, .counter], id: \.self) { loc in
                                chipButton(label: loc.displayName, icon: loc.icon, isSelected: viewModel.selectedLocation == loc.rawValue) {
                                    viewModel.selectedLocation = loc.rawValue
                                }
                            }
                        }
                    }

                    // Sort options
                    filterSection(title: "Sort By") {
                        VStack(spacing: 8) {
                            let options = SortOption.allCases
                            ForEach(options, id: \.self) { option in
                                sortRow(option: option)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        viewModel.clearFilters()
                        viewModel.sortOption = .expirationDate
                        viewModel.isAscending = true
                    }
                    .foregroundStyle(.red)
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(hex: "667eea"))
                }
            }
        }
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
        }
    }

    private func chipButton(label: String, icon: String, isSelected: Bool, color: Color = Color(hex: "667eea"), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [color, color.opacity(0.75)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(.secondarySystemGroupedBackground), Color(.secondarySystemGroupedBackground)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: isSelected ? color.opacity(0.35) : .clear, radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }

    private func sortRow(option: SortOption) -> some View {
        let isSelected = viewModel.sortOption == option
        return Button {
            if isSelected {
                viewModel.isAscending.toggle()
            } else {
                viewModel.sortOption = option
                viewModel.isAscending = true
            }
        } label: {
            HStack {
                Text(option.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color(hex: "667eea") : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: viewModel.isAscending ? "arrow.up" : "arrow.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "667eea"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}
