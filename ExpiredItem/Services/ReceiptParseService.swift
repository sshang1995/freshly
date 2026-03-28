import Foundation
import UIKit
import Vision

struct ParsedReceiptItem {
    var name: String
    var quantity: String
    var category: Category
}

enum ReceiptParseError: LocalizedError {
    case notConfigured
    case networkError(Error)
    case noItemsFound
    case httpError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Receipt parsing service is not configured. Add RECIPE_PROXY_URL to your app configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noItemsFound:
            return "No food items were detected in the receipt."
        case .httpError(let code):
            return "Server error (HTTP \(code))."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}

struct ReceiptParseService {

    // MARK: - Phase 1: OCR

    func extractText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { return "" }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Phase 2: AI Parsing

    func parseItems(from ocrText: String) async throws -> [ParsedReceiptItem] {
        let endpoint = try receiptParseURL()

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = proxyToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.timeoutInterval = 30

        request.httpBody = try JSONEncoder().encode(ReceiptParseRequest(ocrText: ocrText))

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ReceiptParseError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ReceiptParseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw ReceiptParseError.httpError(httpResponse.statusCode)
        }

        let parsed = try JSONDecoder().decode(ReceiptParseResponse.self, from: data)

        // Only include food-relevant categories
        let foodCategories: Set<String> = [
            "produce", "dairy", "meat", "bakery",
            "frozen", "beverages", "condiments", "snacks", "other"
        ]

        let items = parsed.items.compactMap { raw -> ParsedReceiptItem? in
            let name = raw.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }

            let categoryRaw = raw.category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard foodCategories.contains(categoryRaw) else { return nil }

            let category = Category(rawValue: categoryRaw) ?? .other
            return ParsedReceiptItem(
                name: name,
                quantity: raw.quantity.trimmingCharacters(in: .whitespacesAndNewlines),
                category: category
            )
        }

        guard !items.isEmpty else {
            throw ReceiptParseError.noItemsFound
        }

        return items
    }

    // MARK: - Helpers

    private func receiptParseURL() throws -> URL {
        let rawURL = (Bundle.main.object(forInfoDictionaryKey: "RECIPE_PROXY_URL") as? String)
            ?? ProcessInfo.processInfo.environment["RECIPE_PROXY_URL"]
            ?? ""
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty, var components = URLComponents(string: trimmed) else {
            throw ReceiptParseError.notConfigured
        }

        components.path = "/parse-receipt"
        components.query = nil

        guard let url = components.url else {
            throw ReceiptParseError.notConfigured
        }

        return url
    }

    private var proxyToken: String? {
        let token = (Bundle.main.object(forInfoDictionaryKey: "RECIPE_PROXY_TOKEN") as? String)
            ?? ProcessInfo.processInfo.environment["RECIPE_PROXY_TOKEN"]
            ?? ""
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Private Codable Types

private struct ReceiptParseRequest: Encodable {
    let ocrText: String
}

private struct ReceiptParseResponse: Decodable {
    let items: [RawReceiptItem]
}

private struct RawReceiptItem: Decodable {
    let name: String
    let quantity: String
    let category: String
}
