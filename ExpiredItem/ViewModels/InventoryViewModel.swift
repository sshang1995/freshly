import SwiftUI

enum SortOption: String, CaseIterable {
    case expirationDate = "Expiration Date"
    case name = "Name"
    case category = "Category"
    case dateAdded = "Date Added"
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

    func update(items: [Item]) {
        var result = items

        // Filter by completion state
        result = result.filter { $0.completionState == selectedCompletionState }

        // Search
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.displayName.localizedCaseInsensitiveContains(searchText) ||
                $0.location.displayName.localizedCaseInsensitiveContains(searchText) ||
                ($0.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Category filter
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }

        // Location filter
        if let loc = selectedLocation {
            result = result.filter { $0.locationRaw == loc }
        }

        // Sort
        result = result.sorted {
            switch sortOption {
            case .expirationDate:
                return isAscending ? $0.expirationDate < $1.expirationDate : $0.expirationDate > $1.expirationDate
            case .name:
                return isAscending ? $0.name < $1.name : $0.name > $1.name
            case .category:
                return isAscending ? $0.categoryRaw < $1.categoryRaw : $0.categoryRaw > $1.categoryRaw
            case .dateAdded:
                return isAscending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
            }
        }

        filteredItems = result
    }

    func clearFilters() {
        selectedCategory = nil
        selectedLocation = nil
    }
}
