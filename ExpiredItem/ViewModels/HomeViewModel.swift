import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    private(set) var expired: [Item] = []
    private(set) var expiringSoon: [Item] = []
    private(set) var fresh: [Item] = []
    private(set) var recipeRecommendation: RecipeRecommendation?
    private(set) var isLoadingRecommendation = false
    private(set) var recommendationErrorMessage: String?

    private let recipeService = AIRecipeService()
    private var recipeTask: Task<Void, Never>?
    private var recommendationSeed = 0

    var totalActive: Int { expired.count + expiringSoon.count + fresh.count }
    var urgentCount: Int { expired.count + expiringSoon.count }
    var shouldShowRecipeSection: Bool {
        !recipeInputItems.isEmpty || isLoadingRecommendation || recipeRecommendation != nil
    }

    func update(items: [Item]) {
        let activeItems = items.filter { $0.completionState == .active }
        expired = activeItems.filter { $0.status == .expired }
            .sorted { $0.expirationDate < $1.expirationDate }
        expiringSoon = activeItems.filter { $0.status == .expiringSoon }
            .sorted { $0.expirationDate < $1.expirationDate }
        fresh = activeItems.filter { $0.status == .fresh }
            .sorted { $0.expirationDate < $1.expirationDate }

        if recipeInputItems.isEmpty {
            recipeTask?.cancel()
            isLoadingRecommendation = false
            recipeRecommendation = nil
            recommendationErrorMessage = nil
            return
        }

        fetchRecipeRecommendation()
    }

    func refreshRecipeRecommendation() {
        recommendationSeed += 1
        fetchRecipeRecommendation(force: true)
    }

    private var recipeInputItems: [Item] {
        expiringSoon.filter { ![Category.medicine, .cosmetics].contains($0.category) }
    }

    private func fetchRecipeRecommendation(force: Bool = false) {
        if !force, recipeRecommendation != nil, recommendationErrorMessage == nil {
            return
        }

        recipeTask?.cancel()
        isLoadingRecommendation = true
        recommendationErrorMessage = nil

        let items = recipeInputItems
        let seed = recommendationSeed

        recipeTask = Task { [weak self] in
            guard let self else { return }
            do {
                let recommendation = try await recipeService.generateRecipe(from: items, seed: seed)
                guard !Task.isCancelled else { return }
                self.recipeRecommendation = recommendation
                self.isLoadingRecommendation = false
            } catch {
                guard !Task.isCancelled else { return }
                self.recipeRecommendation = nil
                self.isLoadingRecommendation = false
                self.recommendationErrorMessage = error.localizedDescription
            }
        }
    }
}

struct RecipeRecommendation: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let ingredients: [String]
    let timeText: String
    let steps: [String]

    static func == (lhs: RecipeRecommendation, rhs: RecipeRecommendation) -> Bool {
        lhs.title == rhs.title && lhs.subtitle == rhs.subtitle
    }
}
