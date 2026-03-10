import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var name: String
    var categoryRaw: String
    var locationRaw: String
    var customLocationName: String?
    var expirationDate: Date
    var purchaseDate: Date?
    var quantity: String?
    var notes: String?
    var reminderOffsetDays: Int
    var createdAt: Date
    var updatedAt: Date
    var completionStateRaw: String
    var completionDate: Date?
    var notificationIDs: [String]

    init(
        name: String,
        category: Category = .other,
        location: Location = .fridge,
        expirationDate: Date,
        purchaseDate: Date? = nil,
        quantity: String? = nil,
        notes: String? = nil,
        reminderOffsetDays: Int = 3
    ) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.locationRaw = location.rawValue
        if case .custom(let name) = location {
            self.customLocationName = name
        }
        self.expirationDate = expirationDate
        self.purchaseDate = purchaseDate
        self.quantity = quantity
        self.notes = notes
        self.reminderOffsetDays = reminderOffsetDays
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completionStateRaw = CompletionState.active.rawValue
        self.notificationIDs = []
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var location: Location {
        get { Location.from(rawValue: locationRaw, customName: customLocationName) }
        set {
            locationRaw = newValue.rawValue
            if case .custom(let name) = newValue {
                customLocationName = name
            } else {
                customLocationName = nil
            }
        }
    }

    var completionState: CompletionState {
        get { CompletionState(rawValue: completionStateRaw) ?? .active }
        set { completionStateRaw = newValue.rawValue }
    }

    var status: ItemStatus {
        let days = Date().daysUntil(expirationDate)
        if days < 0 {
            return .expired
        } else if days <= 3 {
            return .expiringSoon
        } else {
            return .fresh
        }
    }

    var daysUntilExpiration: Int {
        Date().daysUntil(expirationDate)
    }
}
