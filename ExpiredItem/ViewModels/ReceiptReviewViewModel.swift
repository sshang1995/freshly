import SwiftUI
import SwiftData

@Observable
final class ReceiptReviewViewModel {

    struct ReviewItem: Identifiable {
        let id = UUID()
        var isIncluded = true
        var name: String
        var quantity: String
        var category: Category
        var expirationDate: Date
        var location: Location
        var reminderOffsetDays: Int
    }

    var reviewItems: [ReviewItem] = []
    var isProcessing = false
    var processingError: String?
    var isSaving = false

    var includedCount: Int { reviewItems.filter(\.isIncluded).count }

    private let service = ReceiptParseService()

    func process(image: UIImage) async {
        isProcessing = true
        processingError = nil
        reviewItems = []

        do {
            let ocrText = try await service.extractText(from: image)
            let parsed = try await service.parseItems(from: ocrText)

            let settings = AppSettings.shared
            let defaultLocation = settings.defaultLocation
            let defaultReminderDays = settings.defaultReminderDays

            reviewItems = parsed.map { item in
                ReviewItem(
                    name: item.name,
                    quantity: item.quantity,
                    category: item.category,
                    expirationDate: Date().adding(days: 7),
                    location: defaultLocation,
                    reminderOffsetDays: defaultReminderDays
                )
            }
        } catch {
            processingError = error.localizedDescription
        }

        isProcessing = false
    }

    func saveAll(context: ModelContext) async {
        isSaving = true
        let included = reviewItems.filter(\.isIncluded)

        for reviewItem in included {
            let item = Item(
                name: reviewItem.name,
                category: reviewItem.category,
                location: reviewItem.location,
                expirationDate: reviewItem.expirationDate,
                purchaseDate: nil,
                quantity: reviewItem.quantity.isEmpty ? nil : reviewItem.quantity,
                notes: nil,
                reminderOffsetDays: reviewItem.reminderOffsetDays
            )
            context.insert(item)
            try? context.save()

            let newIDs = await NotificationService.shared.schedule(for: item)
            item.notificationIDs = newIDs
            try? context.save()
        }

        isSaving = false
    }
}
