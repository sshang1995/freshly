import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)

            AddItemTabView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

/// Wrapper that presents AddItemView as a sheet when the Add tab is tapped
private struct AddItemTabView: View {
    @Binding var selectedTab: Int
    @State private var showSheet = false

    var body: some View {
        Color.clear
            .onAppear {
                showSheet = true
            }
            .sheet(isPresented: $showSheet, onDismiss: {
                selectedTab = 0
            }) {
                AddItemView()
            }
    }
}
