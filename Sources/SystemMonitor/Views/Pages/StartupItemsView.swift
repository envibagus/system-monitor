import SwiftUI

/// Startup Items page — lists login items (read-only for now)
struct StartupItemsView: View {
    @Binding var selectedPage: NavigationPage
    @State private var loginItems: [LoginItemInfo] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader(title: "Startup Items", sfSymbol: "power") { selectedPage = .dashboard }

                /* Info Banner */
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Theme.accentBlue)
                    Text("Login items that launch when you sign in. Manage them in System Settings > General > Login Items.")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.secondaryText)
                }
                .padding(12)
                .background(Theme.accentBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.accentBlue.opacity(0.2), lineWidth: 1))

                /* Items List */
                WidgetCardView(title: "Login Items", sfSymbol: "list.bullet", symbolColor: Theme.accentBlue) {
                    if isLoading {
                        loadingView
                    } else if loginItems.isEmpty {
                        emptyView
                    } else {
                        itemsList
                    }
                }

                /* Launch Agents */
                WidgetCardView(title: "Launch Agents", sfSymbol: "gearshape.2", symbolColor: Theme.accentPurple) {
                    launchAgentsList
                }
            }
            .padding(24)
        }
        .onAppear { loadLoginItems() }
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Scanning startup items...")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.vertical, 12)
    }

    private var emptyView: some View {
        Text("No login items found")
            .font(Theme.captionFont)
            .foregroundStyle(Theme.secondaryText)
            .padding(.vertical, 12)
    }

    private var itemsList: some View {
        VStack(spacing: 0) {
            ForEach(loginItems) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.isAgent ? "gearshape" : "app")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.primaryText)
                        Text(item.path)
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text(item.isAgent ? "Agent" : "App")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.cardBorder)
                        .clipShape(Capsule())
                }
                .padding(.vertical, 6)

                if item.id != loginItems.last?.id {
                    Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                }
            }
        }
    }

    private var launchAgentsList: some View {
        VStack(spacing: 0) {
            let agents = scanLaunchAgents()
            if agents.isEmpty {
                Text("No user launch agents found")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.secondaryText)
                    .padding(.vertical, 12)
            } else {
                ForEach(agents) { agent in
                    HStack {
                        Text(agent.name)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.primaryText)
                            .lineLimit(1)
                        Spacer()
                        Text(agent.path)
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                            .frame(maxWidth: 300, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Data Loading

    private func loadLoginItems() {
        let agentDir = NSHomeDirectory() + "/Library/LaunchAgents"
        Task.detached {
            let items = Self.scanLoginItems(agentDir: agentDir)
            await MainActor.run {
                loginItems = items
                isLoading = false
            }
        }
    }

    @Sendable
    private static nonisolated func scanLoginItems(agentDir: String) -> [LoginItemInfo] {
        var items: [LoginItemInfo] = []
        let agentDir = NSHomeDirectory() + "/Library/LaunchAgents"
        let fm = FileManager.default

        if let contents = try? fm.contentsOfDirectory(atPath: agentDir) {
            for file in contents where file.hasSuffix(".plist") {
                let path = (agentDir as NSString).appendingPathComponent(file)
                let name = (file as NSString).deletingPathExtension
                items.append(LoginItemInfo(name: name, path: path, isAgent: true))
            }
        }
        return items.sorted { $0.name < $1.name }
    }

    private func scanLaunchAgents() -> [LoginItemInfo] {
        let dirs = ["/Library/LaunchAgents", "/Library/LaunchDaemons"]
        var agents: [LoginItemInfo] = []
        let fm = FileManager.default

        for dir in dirs {
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for file in contents.prefix(20) where file.hasSuffix(".plist") {
                let name = (file as NSString).deletingPathExtension
                agents.append(LoginItemInfo(name: name, path: dir + "/" + file, isAgent: true))
            }
        }
        return agents.sorted { $0.name < $1.name }
    }
}

struct LoginItemInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isAgent: Bool
}
