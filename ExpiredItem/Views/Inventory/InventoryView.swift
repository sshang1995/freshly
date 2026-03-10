import SwiftUI
import SwiftData

struct InventoryView: View {
    @Query(sort: \Item.expirationDate) private var allItems: [Item]
    @Environment(\.modelContext) private var context
    @State private var viewModel = InventoryViewModel()
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Segmented state picker
                statePicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Content
                if viewModel.filteredItems.isEmpty {
                    EmptyStateView(
                        icon: allItems.isEmpty ? "leaf.fill" : "magnifyingglass",
                        title: allItems.isEmpty ? "Nothing here yet" : "No Results",
                        message: allItems.isEmpty
                            ? "Add items to start tracking expirations."
                            : "Try adjusting your search or filters.",
                        actionTitle: allItems.isEmpty ? "Add Item" : nil,
                        action: allItems.isEmpty ? { showAddSheet = true } : nil
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.filteredItems) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    ItemRowView(item: item)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    if item.completionState == .active {
                                        Button { markConsumed(item) } label: {
                                            Label("Consumed", systemImage: "checkmark.circle")
                                        }
                                        .tint(.green)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.showFilterSheet) {
                FilterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddSheet) {
                AddItemView()
            }
            .onChange(of: allItems) { _, v in viewModel.update(items: v) }
            .onChange(of: viewModel.searchText) { _, _ in viewModel.update(items: allItems) }
            .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.update(items: allItems) }
            .onChange(of: viewModel.selectedLocation) { _, _ in viewModel.update(items: allItems) }
            .onChange(of: viewModel.selectedCompletionState) { _, _ in viewModel.update(items: allItems) }
            .onChange(of: viewModel.sortOption) { _, _ in viewModel.update(items: allItems) }
            .onChange(of: viewModel.isAscending) { _, _ in viewModel.update(items: allItems) }
            .onAppear { viewModel.update(items: allItems) }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 10) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 15))
                TextField("Search items...", text: $viewModel.searchText)
                    .font(.system(size: 15))
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Filter button
            Button { viewModel.showFilterSheet = true } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(viewModel.hasActiveFilters
                            ? LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color(.secondarySystemGroupedBackground), Color(.secondarySystemGroupedBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(viewModel.hasActiveFilters ? .white : .primary)
                }
            }

            // Add button
            Button { showAddSheet = true } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 8, y: 3)
            }
        }
    }

    // MARK: - Segmented Picker
    private var statePicker: some View {
        HStack(spacing: 0) {
            ForEach(CompletionState.allCases, id: \.self) { state in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectedCompletionState = state
                    }
                } label: {
                    Text(state.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(viewModel.selectedCompletionState == state ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if viewModel.selectedCompletionState == state {
                                    LinearGradient(
                                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                    .clipShape(Capsule())
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }

    private func deleteItem(_ item: Item) {
        ItemFormViewModel(item: item).delete(item: item, context: context)
    }

    private func markConsumed(_ item: Item) {
        ItemFormViewModel(item: item).markComplete(item: item, state: .consumed, context: context)
    }
}
