import Foundation

struct FanReading: Identifiable, Sendable {
    let id: Int
    let fanIndex: Int
    let currentRPM: Double
    let minRPM: Double
    let maxRPM: Double

    var percentOfMax: Double {
        guard maxRPM > 0 else { return 0 }
        return currentRPM / maxRPM
    }

    var label: String {
        "Fan \(fanIndex + 1)"
    }
}
