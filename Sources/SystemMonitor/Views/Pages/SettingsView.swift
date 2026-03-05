import SwiftUI

/// Settings page — refresh rate, theme, about
struct SettingsView: View {
    @Environment(MonitorManager.self) private var monitor
    @Binding var selectedPage: NavigationPage
    @AppStorage("refreshInterval") private var refreshInterval: Double = 2.0
    @AppStorage("appearance") private var appearance: String = "system"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeader(title: "Settings", sfSymbol: "gearshape") { selectedPage = .dashboard }

                /* Refresh Rate */
                WidgetCardView(title: "Refresh Rate", sfSymbol: "clock.arrow.2.circlepath", symbolColor: Theme.accentBlue) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How often data is refreshed. Lower intervals use more CPU.")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.secondaryText)

                        Picker("Interval", selection: $refreshInterval) {
                            Text("1 second").tag(1.0)
                            Text("2 seconds").tag(2.0)
                            Text("5 seconds").tag(5.0)
                            Text("10 seconds").tag(10.0)
                        }
                        .pickerStyle(.segmented)
                    }
                }

                /* Appearance */
                WidgetCardView(title: "Appearance", sfSymbol: "paintbrush", symbolColor: Theme.accentPurple) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Theme", selection: $appearance) {
                            Text("System").tag("system")
                            Text("Dark").tag("dark")
                            Text("Light").tag("light")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                /* About */
                WidgetCardView(title: "About", sfSymbol: "info.circle", symbolColor: Theme.accentTeal) {
                    VStack(alignment: .leading, spacing: 8) {
                        aboutRow("App", "System Monitor")
                        Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                        aboutRow("Version", "1.0.0")
                        Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                        aboutRow("Platform", "macOS 26 Tahoe")
                        Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                        aboutRow("Framework", "SwiftUI + IOKit")
                        Divider().foregroundStyle(Theme.cardBorder.opacity(0.5))
                        aboutRow("License", "MIT")
                    }
                }

                /* Keyboard Shortcut */
                WidgetCardView(title: "Keyboard Shortcut", sfSymbol: "keyboard", symbolColor: Theme.accentOrange) {
                    HStack {
                        Text("Toggle Window")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        HStack(spacing: 4) {
                            keyBadge("⌥")
                            keyBadge("⌘")
                            keyBadge("M")
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(value)
                .font(Theme.monoFont)
                .foregroundStyle(Theme.primaryText)
        }
    }

    private func keyBadge(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.primaryText)
            .frame(width: 26, height: 26)
            .background(Theme.cardBorder)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
