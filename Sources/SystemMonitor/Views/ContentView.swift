import SwiftUI

/// Main app layout — NavigationSplitView with native Liquid Glass sidebar
struct ContentView: View {
    @Environment(MonitorManager.self) private var monitor
    @State private var selectedPage: NavigationPage = .dashboard

    var body: some View {
        NavigationSplitView {
            /* Sidebar — native Liquid Glass material */
            SidebarView(selectedPage: $selectedPage)
                .navigationSplitViewColumnWidth(min: 220, ideal: 220, max: 240)
        } detail: {
            /* Main Content */
            Group {
                switch selectedPage {
                case .dashboard:
                    DashboardView(selectedPage: $selectedPage)
                case .cpu:
                    CPUDetailView(selectedPage: $selectedPage)
                case .memory:
                    MemoryDetailView(selectedPage: $selectedPage)
                case .storage:
                    StorageDetailView(selectedPage: $selectedPage)
                case .thermal:
                    ThermalDetailView(selectedPage: $selectedPage)
                case .network:
                    NetworkDetailView(selectedPage: $selectedPage)
                case .battery:
                    BatteryDetailView(selectedPage: $selectedPage)
                case .startupItems:
                    StartupItemsView(selectedPage: $selectedPage)
                case .settings:
                    SettingsView(selectedPage: $selectedPage)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.windowBackground)
            .animation(Theme.pageTransition, value: selectedPage)
        }
        .frame(minWidth: Theme.windowMinWidth, minHeight: Theme.windowMinHeight)
    }
}
