import Foundation

struct AIRecipeService {
    func generateRecipe(from items: [Item], seed: Int) async throws -> RecipeRecommendation {
        let endpoint = try AppConfig.recipeProxyURL()

        let ingredientNames = items
            .map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !ingredientNames.isEmpty else {
            throw AIRecipeServiceError.noIngredients
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AppConfig.recipeProxyToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 30

        let payload = RecipeProxyRequest(
            ingredients: Array(ingredientNames.prefix(6)),
            seed: seed
        )

        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIRecipeServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AIRecipeServiceError.httpError(httpResponse.statusCode)
        }

        let parsed = try JSONDecoder().decode(RecipeProxyResponse.self, from: data)

        let cleanedIngredients = parsed.ingredients
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let cleanedSteps = parsed.steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return RecipeRecommendation(
            title: parsed.title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: parsed.subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            ingredients: cleanedIngredients.isEmpty ? Array(ingredientNames.prefix(3)) : cleanedIngredients,
            timeText: parsed.timeText.trimmingCharacters(in: .whitespacesAndNewlines),
            steps: cleanedSteps
        )
    }
}

enum AIRecipeServiceError: LocalizedError {
    case missingProxyURL
    case invalidProxyURL
    case noIngredients
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .missingProxyURL:
            return "Missing RECIPE_PROXY_URL in app configuration."
        case .invalidProxyURL:
            return "Invalid RECIPE_PROXY_URL."
        case .noIngredients:
            return "No eligible expiring ingredients found."
        case .invalidResponse:
            return "Proxy returned an invalid recipe response."
        case .httpError(let statusCode):
            return "AI request failed (HTTP \(statusCode))."
        }
    }
}

private enum AppConfig {
    static func recipeProxyURL() throws -> URL {
        let rawURL = infoString(for: "RECIPE_PROXY_URL")
            ?? ProcessInfo.processInfo.environment["RECIPE_PROXY_URL"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        guard !rawURL.isEmpty else {
            throw AIRecipeServiceError.missingProxyURL
        }

        guard let url = URL(string: rawURL) else {
            throw AIRecipeServiceError.invalidProxyURL
        }

        return url
    }

    static var recipeProxyToken: String? {
        let token = infoString(for: "RECIPE_PROXY_TOKEN")
            ?? ProcessInfo.processInfo.environment["RECIPE_PROXY_TOKEN"]?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        return token.isEmpty ? nil : token
    }

    private static func infoString(for key: String) -> String? {
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return nil
    }
}

private struct RecipeProxyRequest: Encodable {
    let ingredients: [String]
    let seed: Int
}

private struct RecipeProxyResponse: Decodable {
    let title: String
    let subtitle: String
    let timeText: String
    let ingredients: [String]
    let steps: [String]
}
