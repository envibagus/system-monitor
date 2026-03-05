import Foundation

enum Formatters {
    /// Format bytes to human-readable string (e.g., "4.2 GB", "128 MB")
    static func bytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(bytes) / 1_048_576
        if mb >= 1.0 {
            return String(format: "%.0f MB", mb)
        }
        let kb = Double(bytes) / 1024
        return String(format: "%.0f KB", kb)
    }

    /// Format bytes to GB with specified decimal places
    static func gigabytes(_ bytes: UInt64, decimals: Int = 1) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.\(decimals)f GB", gb)
    }

    /// Format temperature in Celsius
    static func temperature(_ celsius: Double) -> String {
        String(format: "%.0f°C", celsius)
    }

    /// Format percentage (0.0-1.0 input)
    static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    /// Format percentage (0-100 input)
    static func percentRaw(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    /// Format fan RPM
    static func rpm(_ value: Double) -> String {
        String(format: "%.0f RPM", value)
    }

    /// Format network speed (bytes per second)
    static func networkSpeed(_ bytesPerSecond: UInt64) -> String {
        if bytesPerSecond >= 1_073_741_824 {
            return String(format: "%.1f GB/s", Double(bytesPerSecond) / 1_073_741_824)
        }
        if bytesPerSecond >= 1_048_576 {
            return String(format: "%.1f MB/s", Double(bytesPerSecond) / 1_048_576)
        }
        if bytesPerSecond >= 1024 {
            return String(format: "%.1f KB/s", Double(bytesPerSecond) / 1024)
        }
        return String(format: "%llu B/s", bytesPerSecond)
    }

    /// Format uptime duration
    static func uptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
