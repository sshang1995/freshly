import SwiftUI
import SwiftData

@Observable
final class ItemFormViewModel {
    var name = ""
    var category: Category = .other
    var location: Location = .fridge
    var customLocationName = ""
    var expirationDate = Date().adding(days: 7)
    var purchaseDate: Date? = nil
    var hasPurchaseDate = false
    var quantity = ""
    var notes = ""
    var reminderOffsetDays = 3

    var isEditing: Bool { editingItem != nil }
    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private var editingItem: Item?

    init(item: Item? = nil) {
        if let item {
            self.editingItem = item
            self.name = item.name
            self.category = item.category
            self.location = item.location
            if case .custom(let n) = item.location {
                self.customLocationName = n
            }
            self.expirationDate = item.expirationDate
            self.purchaseDate = item.purchaseDate
            self.hasPurchaseDate = item.purchaseDate != nil
            self.quantity = item.quantity ?? ""
            self.notes = item.notes ?? ""
            self.reminderOffsetDays = item.reminderOffsetDays
        } else {
            let settings = AppSettings.shared
            self.category = settings.defaultCategory
            self.location = settings.defaultLocation
            self.reminderOffsetDays = settings.defaultReminderDays
        }
    }

    func apply(scannedProduct: ScannedProduct) {
        name = scannedProduct.name
        category = scannedProduct.category
    }

    func save(context: ModelContext) async {
        let resolvedLocation: Location
        if case .custom = location {
            resolvedLocation = .custom(customLocationName)
        } else {
            resolvedLocation = location
        }

        if let item = editingItem {
            // Cancel old notifications before updating
            NotificationService.shared.cancel(ids: item.notificationIDs)

            item.name = name
            item.category = category
            item.location = resolvedLocation
            item.expirationDate = expirationDate
            item.purchaseDate = hasPurchaseDate ? purchaseDate : nil
            item.quantity = quantity.isEmpty ? nil : quantity
            item.notes = notes.isEmpty ? nil : notes
            item.reminderOffsetDays = reminderOffsetDays
            item.updatedAt = Date()

            let newIDs = await NotificationService.shared.schedule(for: item)
            item.notificationIDs = newIDs
            try? context.save()
        } else {
            let item = Item(
                name: name,
                category: category,
                location: resolvedLocation,
                expirationDate: expirationDate,
                purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                quantity: quantity.isEmpty ? nil : quantity,
                notes: notes.isEmpty ? nil : notes,
                reminderOffsetDays: reminderOffsetDays
            )
            context.insert(item)
            try? context.save()

            let newIDs = await NotificationService.shared.schedule(for: item)
            item.notificationIDs = newIDs
            try? context.save()
        }
    }

    func delete(item: Item, context: ModelContext) {
        NotificationService.shared.cancel(ids: item.notificationIDs)
        context.delete(item)
        try? context.save()
    }

    func markComplete(item: Item, state: CompletionState, context: ModelContext) {
        NotificationService.shared.cancel(ids: item.notificationIDs)
        item.notificationIDs = []
        item.completionState = state
        item.completionDate = Date()
        item.updatedAt = Date()
        try? context.save()
    }
}
