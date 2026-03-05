# System Monitor

Native macOS system monitor app. Beautiful, fast, transparent.

## Platform & Stack

- **Target:** macOS 26 Tahoe, Apple Silicon + Intel Universal
- **Language:** Swift 6.2, SwiftUI
- **Design:** macOS 26 Liquid Glass design language
- **Build:** SPM executable (`swift build`), no .xcodeproj
- **Dependencies:** Zero third-party. IOKit, Mach APIs, libproc, Swift Charts only.

## Architecture — MVVM

```
Sources/SystemMonitor/
├── App/           # @main entry point
├── Views/         # SwiftUI views (one per page)
├── ViewModels/    # @Observable state managers
├── Services/      # Low-level system data collection
├── Models/        # Data structs (Sendable, Identifiable)
└── Utilities/     # Theme, Formatters, ElectronDetector, SystemProcessCategorizer
```

## Sidebar Pages (9 total)

| Section  | Page             | SF Symbol              |
|----------|------------------|------------------------|
| Overview | Dashboard        | `square.grid.2x2`     |
| Monitor  | CPU              | `cpu`                  |
| Monitor  | Memory           | `memorychip`           |
| Monitor  | Storage          | `internaldrive`        |
| Monitor  | Fans & Thermal   | `thermometer.medium`   |
| Monitor  | Network          | `network`              |
| System   | Battery          | `battery.75percent`    |
| System   | Startup Items    | `power`                |
| System   | Settings         | `gearshape`            |

## Services & Data Sources

| Service         | Data Source                        | Refresh  |
|-----------------|------------------------------------|----------|
| SMCService      | IOKit `AppleSMC` (temp, fans)      | 2s       |
| CPUService      | Mach `host_processor_info()`       | 2s       |
| MemoryService   | Mach `host_statistics64()`         | 2s       |
| ProcessService  | libproc `proc_listallpids()`       | 3s       |
| NetworkService  | `getifaddrs()` AF_LINK counters    | 1s       |
| BatteryService  | IOKit `AppleSmartBattery`          | 10s      |
| StorageService  | `URL.resourceValues`, FileManager  | 30s      |

**MonitorManager** owns all services, drives timers, injected via `.environment()`.

## Color System (Dark Mode Primary)

| Token           | Hex       | Usage                              |
|-----------------|-----------|------------------------------------|
| windowBg        | `#0F1219` | Base surface                       |
| sidebarBg       | `#111622` | Sidebar                            |
| cardBg          | `#141825` | Widget cards                       |
| cardBorder      | `#1E2433` | Default card border                |
| cardBorderHover | `#2A3548` | Hover state                        |
| primaryText     | `#E8ECF4` | Headings, values                   |
| secondaryText   | `#6B7A90` | Labels, metadata                   |
| accentBlue      | `#5E9EFF` | CPU, P-cores, primary actions      |
| accentOrange    | `#FFB84D` | Memory, warnings, wired RAM        |
| accentGreen     | `#7BEB7B` | Healthy, E-cores, network download |
| accentPink      | `#FF6B8A` | Critical alerts, high values       |
| accentPurple    | `#C084FC` | Electron badges, system memory     |
| accentTeal      | `#38BDF8` | Compressed memory                  |

## Typography

- **UI text:** SF Pro (system default)
- **Numeric values:** SF Mono (monospaced)
- **Scale:** Title 22pt semibold, card headers 13pt semibold, body 12-13pt, captions 10-11pt

## Key Differentiators

- **Electron-aware memory grouping:** Scans app bundles for `Electron Framework.framework`, groups child processes, sums memory
- **System process categorization:** Maps ~40 system processes to human-readable categories (Kernel, Display & UI, Search & Indexing, Cloud, Security, Networking, etc.)

## Animation Specs

- Page transitions: fade + scale (0.9→1.0), 0.3s easeInOut
- Gauge changes: animated stroke-dashoffset, 0.8s ease
- Sparkline updates: smooth interpolation, 0.5s
- Card hover: border color shift, 0.15s

## Non-Functional Requirements

- Memory: <50MB resident
- CPU idle: <1%
- Bundle size: <50MB
- Launch: <1s to dashboard
- Charts: 60fps sustained

## Keyboard Shortcut

- Toggle window: Opt+Cmd+M (configurable)

## Out of Scope (v1.0)

- Fan speed control
- GPU monitoring
- SQLite history/trends
- WidgetKit widgets
- Localization

## Sprint Roadmap

1. **Scaffold & Core Services** — project structure, models, all services ✅
2. **Navigation & Dashboard** — sidebar, dashboard widgets, alert banners
3. **Detail Pages** — CPU, Memory, Storage, Thermal, Network, Battery views
4. **Secondary Features** — menu bar widget, startup items, settings, notifications
5. **Final Pass** — testing, performance, polish, signing
