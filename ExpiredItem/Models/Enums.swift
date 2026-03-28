import SwiftUI

enum Category: String, CaseIterable, Identifiable {
    case produce = "produce"
    case dairy = "dairy"
    case meat = "meat"
    case bakery = "bakery"
    case frozen = "frozen"
    case beverages = "beverages"
    case condiments = "condiments"
    case snacks = "snacks"
    case medicine = "medicine"
    case cosmetics = "cosmetics"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        L("category.\(rawValue)")
    }

    var icon: String {
        switch self {
        case .produce: return "leaf.fill"
        case .dairy: return "drop.fill"
        case .meat: return "fork.knife"
        case .bakery: return "birthday.cake.fill"
        case .frozen: return "snowflake"
        case .beverages: return "cup.and.saucer.fill"
        case .condiments: return "takeoutbag.and.cup.and.straw.fill"
        case .snacks: return "popcorn.fill"
        case .medicine: return "pill.fill"
        case .cosmetics: return "sparkles"
        case .other: return "archivebox.fill"
        }
    }
}

enum Location: Equatable, Hashable {
    case fridge
    case freezer
    case pantry
    case cabinet
    case counter
    case custom(String)

    static let knownCases: [Location] = [.fridge, .freezer, .pantry, .cabinet, .counter, .custom("")]

    var rawValue: String {
        switch self {
        case .fridge: return "fridge"
        case .freezer: return "freezer"
        case .pantry: return "pantry"
        case .cabinet: return "cabinet"
        case .counter: return "counter"
        case .custom: return "custom"
        }
    }

    var displayName: String {
        switch self {
        case .fridge: return L("location.fridge")
        case .freezer: return L("location.freezer")
        case .pantry: return L("location.pantry")
        case .cabinet: return L("location.cabinet")
        case .counter: return L("location.counter")
        case .custom(let name): return name.isEmpty ? L("location.custom") : name
        }
    }

    var icon: String {
        switch self {
        case .fridge: return "refrigerator.fill"
        case .freezer: return "snowflake"
        case .pantry: return "cabinet.fill"
        case .cabinet: return "cabinet.fill"
        case .counter: return "menubar.rectangle"
        case .custom: return "mappin.circle.fill"
        }
    }

    static func from(rawValue: String, customName: String?) -> Location {
        switch rawValue {
        case "fridge": return .fridge
        case "freezer": return .freezer
        case "pantry": return .pantry
        case "cabinet": return .cabinet
        case "counter": return .counter
        case "custom": return .custom(customName ?? "")
        default: return .fridge
        }
    }
}

enum CompletionState: String, CaseIterable {
    case active = "active"
    case consumed = "consumed"
    case discarded = "discarded"

    var displayName: String {
        L("state.\(rawValue)")
    }
}

enum ItemStatus {
    case fresh
    case expiringSoon
    case expired

    var displayName: String {
        switch self {
        case .fresh: return L("status.fresh")
        case .expiringSoon: return L("status.expiringSoon")
        case .expired: return L("status.expired")
        }
    }

    var cardLabel: String {
        switch self {
        case .fresh: return L("status.fresh")
        case .expiringSoon: return L("status.soon")
        case .expired: return L("status.expired")
        }
    }

    var icon: String {
        switch self {
        case .fresh: return "checkmark.circle.fill"
        case .expiringSoon: return "exclamationmark.circle.fill"
        case .expired: return "xmark.circle.fill"
        }
    }
}
