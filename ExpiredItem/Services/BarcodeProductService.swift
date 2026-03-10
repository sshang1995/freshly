import Foundation

struct ScannedProduct {
    let name: String
    let category: Category
}

enum BarcodeProductError: LocalizedError {
    case notFound
    case networkError

    var errorDescription: String? {
        switch self {
        case .notFound: return "Product not found. Please enter details manually."
        case .networkError: return "Couldn't reach the product database. Check your connection."
        }
    }
}

struct BarcodeProductService {
    func lookup(barcode: String) async throws -> ScannedProduct {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else { throw BarcodeProductError.notFound }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("Freshly iOS App", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BarcodeProductError.networkError
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw BarcodeProductError.networkError
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = json["status"] as? Int, status == 1,
            let product = json["product"] as? [String: Any]
        else {
            throw BarcodeProductError.notFound
        }

        let name = (product["product_name_en"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? (product["product_name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""

        guard !name.isEmpty else { throw BarcodeProductError.notFound }

        let tags = product["categories_tags"] as? [String] ?? []
        let category = inferCategory(from: tags)

        return ScannedProduct(name: name, category: category)
    }

    // MARK: - Category inference

    private func inferCategory(from tags: [String]) -> Category {
        let joined = tags.joined(separator: " ")

        if matches(joined, any: ["dairies", "dairy", "cheeses", "yogurts", "milks", "butters", "creams"]) {
            return .dairy
        }
        if matches(joined, any: ["meats", "poultry", "fish", "seafoods", "sausages", "deli", "charcuterie"]) {
            return .meat
        }
        if matches(joined, any: ["frozen"]) {
            return .frozen
        }
        if matches(joined, any: ["fruits", "vegetables", "fresh", "produce", "salads", "herbs"]) {
            return .produce
        }
        if matches(joined, any: ["beverages", "drinks", "waters", "juices", "sodas", "coffees", "teas", "wines", "beers"]) {
            return .beverages
        }
        if matches(joined, any: ["breads", "bakery", "pastries", "cakes", "biscuits", "cereals", "crackers"]) {
            return .bakery
        }
        if matches(joined, any: ["snacks", "chips", "popcorn", "nuts", "candy", "chocolates", "sweets"]) {
            return .snacks
        }
        if matches(joined, any: ["sauces", "condiments", "dressings", "vinegars", "oils", "spreads", "jams"]) {
            return .condiments
        }
        if matches(joined, any: ["medicines", "drugs", "supplements", "vitamins", "pharmacy"]) {
            return .medicine
        }
        if matches(joined, any: ["beauty", "cosmetics", "skincare", "haircare", "hygiene"]) {
            return .cosmetics
        }
        return .other
    }

    private func matches(_ text: String, any keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
