import SwiftUI

enum SortOption: String, CaseIterable {
    case expirationDate = "expirationDate"
    case name = "name"
    case category = "category"
    case dateAdded = "dateAdded"

    var displayName: String {
        L("sort.\(rawValue)")
    }
}

@Observable
final class InventoryViewModel {
    var searchText = ""
    var selectedCategory: Category? = nil
    var selectedLocation: String? = nil
    var selectedCompletionState: CompletionState = .active
    var sortOption: SortOption = .expirationDate
    var isAscending = true
    var showFilterSheet = false

    private(set) var filteredItems: [Item] = []

    var hasActiveFilters: Bool {
        selectedCategory != nil || selectedLocation != nil
    }

    func clearFilters() {
        selectedCategory = nil
        selectedLocation = nil
    }

    func update(items: [Item]) {
        var result = items.filter { $0.completionStateRaw == selectedCompletionState.rawValue }

        if let cat = selectedCategory {
            result = result.filter { $0.categoryRaw == cat.rawValue }
        }
        if let loc = selectedLocation {
            result = result.filter { $0.locationRaw == loc }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        result.sort { (a: Item, b: Item) -> Bool in
            switch sortOption {
            case .expirationDate:
                return isAscending ? a.expirationDate < b.expirationDate : a.expirationDate > b.expirationDate
            case .name:
                return isAscending ? a.name < b.name : a.name > b.name
            case .category:
                return isAscending ? a.categoryRaw < b.categoryRaw : a.categoryRaw > b.categoryRaw
            case .dateAdded:
                return isAscending ? a.createdAt < b.createdAt : a.createdAt > b.createdAt
            }
        }

        filteredItems = result
    }
}
