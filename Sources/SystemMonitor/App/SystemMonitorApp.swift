import SwiftUI

@main
struct SystemMonitorApp: App {
    @State private var monitorManager = MonitorManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(monitorManager)
                .onAppear {
                    monitorManager.startMonitoring()
                }
        }
        .defaultSize(width: 1000, height: 700)
    }
}
