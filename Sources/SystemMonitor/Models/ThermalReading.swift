import Foundation

struct ThermalReading: Identifiable, Sendable {
    let id: String
    let sensorName: String
    let smcKey: String
    let temperature: Double

    var isValid: Bool {
        temperature > 0 && temperature < 150
    }
}
