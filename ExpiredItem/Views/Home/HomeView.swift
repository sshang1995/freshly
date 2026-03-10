import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Item.expirationDate) private var items: [Item]
    @State private var viewModel = HomeViewModel()
    @State private var selectedStatus: ItemStatus? = nil
    @State private var showAddSheet = false
    @State private var selectedRecipe: RecipeRecommendation? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 20)

                    summaryCards
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)

                    recipeRecommendationSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    itemsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddSheet) {
                AddItemView()
            }
            .sheet(item: $selectedRecipe) { recipe in
                NavigationStack {
                    RecipeDetailView(recipe: recipe)
                }
            }
            .onChange(of: items) { _, newItems in
                viewModel.update(items: newItems)
            }
            .onAppear {
                viewModel.update(items: items)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Freshly")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Button {
                showAddSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
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

    // MARK: - Summary Cards
    private var summaryCards: some View {
        HStack(spacing: 12) {
            cardButton(for: .expired, count: viewModel.expired.count)
            cardButton(for: .expiringSoon, count: viewModel.expiringSoon.count)
            cardButton(for: .fresh, count: viewModel.fresh.count)
        }
    }

    private func cardButton(for status: ItemStatus, count: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                selectedStatus = selectedStatus == status ? nil : status
            }
        } label: {
            ItemSummaryCard(
                status: status,
                count: count,
                isSelected: selectedStatus == status
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recipe Recommendation
    @ViewBuilder
    private var recipeRecommendationSection: some View {
        if viewModel.shouldShowRecipeSection {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("AI Recipe Idea", systemImage: "sparkles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.refreshRecipeRecommendation()
                        }
                    } label: {
                        if viewModel.isLoadingRecommendation {
                            ProgressView()
                                .tint(.white)
                                .frame(width: 18, height: 18)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.18))
                                .clipShape(Capsule())
                        } else {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.95))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.18))
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoadingRecommendation)
                }

                if let recommendation = viewModel.recipeRecommendation {
                    Button {
                        selectedRecipe = recommendation
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recommendation.title)
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text(recommendation.subtitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.92))
                            HStack(spacing: 8) {
                                Label(recommendation.timeText, systemImage: "clock.fill")
                                Label("\(recommendation.ingredients.count) expiring items", systemImage: "tray.full.fill")
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))

                            Label("Tap for full recipe", systemImage: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else if viewModel.isLoadingRecommendation {
                    Text("Generating recipe recommendation...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                } else if let errorMessage = viewModel.recommendationErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                } else {
                    Text("No eligible expiring ingredients yet.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color(hex: "ff9966"), Color(hex: "ff5e62")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: Color(hex: "ff5e62").opacity(0.35), radius: 12, y: 4)
        }
    }

    // MARK: - Items Section
    @ViewBuilder
    private var itemsSection: some View {
        let displayItems = filteredItems

        if displayItems.isEmpty {
            if viewModel.totalActive == 0 {
                emptyHome
            } else {
                EmptyStateView(
                    icon: selectedStatus?.icon ?? "tray",
                    title: "No \(selectedStatus?.displayName ?? "") Items",
                    message: "Nothing in this category right now."
                )
                .frame(minHeight: 200)
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(sectionTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                    if selectedStatus != nil {
                        Button("Show all") {
                            withAnimation { selectedStatus = nil }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "667eea"))
                    }
                }

                LazyVStack(spacing: 10) {
                    ForEach(displayItems) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            ItemRowView(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyHome: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "667eea").opacity(0.15), Color(hex: "764ba2").opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: "leaf.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "11998e"), Color(hex: "38ef7d")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 8) {
                Text("Nothing here yet")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Add your first item to start\ntracking expirations.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Add First Item")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 10, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers
    private var filteredItems: [Item] {
        switch selectedStatus {
        case .expired: return viewModel.expired
        case .expiringSoon: return viewModel.expiringSoon
        case .fresh: return viewModel.fresh
        case nil: return viewModel.expired + viewModel.expiringSoon + viewModel.fresh
        }
    }

    private var sectionTitle: String {
        switch selectedStatus {
        case .expired: return "Expired"
        case .expiringSoon: return "Expiring Soon"
        case .fresh: return "Fresh"
        case nil: return "All Items"
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning ☀️"
        case 12..<17: return "Good afternoon 👋"
        default: return "Good evening 🌙"
        }
    }
}
