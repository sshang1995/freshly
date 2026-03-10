import SwiftData

final class ModelContainerFactory {
    static let shared = ModelContainerFactory()

    let container: ModelContainer

    private init() {
        let schema = Schema([Item.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
