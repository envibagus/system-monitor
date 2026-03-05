import Foundation

struct DataPoint: Identifiable, Sendable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

struct HistoryBuffer: Sendable {
    private var points: [DataPoint] = []
    let maxPoints: Int

    init(maxPoints: Int = 30) {
        self.maxPoints = maxPoints
    }

    var data: [DataPoint] { points }
    var latest: Double? { points.last?.value }
    var isEmpty: Bool { points.isEmpty }

    mutating func append(_ value: Double) {
        points.append(DataPoint(timestamp: Date(), value: value))
        if points.count > maxPoints {
            points.removeFirst(points.count - maxPoints)
        }
    }

    mutating func clear() {
        points.removeAll()
    }
}
