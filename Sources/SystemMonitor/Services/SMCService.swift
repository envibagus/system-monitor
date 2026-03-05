import Foundation
import IOKit

// MARK: - SMCService (Apple Silicon — reads via AppleSMC with little-endian keys)

@Observable
final class SMCService: @unchecked Sendable {
    private(set) var temperatures: [ThermalReading] = []
    private(set) var fans: [FanReading] = []
    private(set) var isConnected: Bool = false

    private let queue = DispatchQueue(label: "com.systemmonitor.smc", qos: .utility)
    private var smcConnection: io_connect_t = 0

    /// Apple Silicon temperature SMC keys
    private static let temperatureKeys: [(key: String, name: String)] = [
        ("Tp01", "CPU P-Core 1"), ("Tp05", "CPU P-Core 2"),
        ("Tp0D", "CPU P-Core 3"), ("Tp0H", "CPU P-Core 4"),
        ("Tp0L", "CPU P-Core 5"), ("Tp0P", "CPU P-Core 6"),
        ("Tp0X", "CPU P-Core 7"), ("Tp0b", "CPU P-Core 8"),
        ("Tp09", "CPU E-Core 1"), ("Tp0T", "CPU E-Core 2"),
        ("Tg05", "GPU Core 1"), ("Tg0D", "GPU Core 2"),
        ("Tg0L", "GPU Core 3"), ("Tg0T", "GPU Core 4"),
        ("Ts0P", "SoC Package"), ("Ts0S", "SoC Package 2"),
        ("TaLP", "Airflow Left"), ("TaRP", "Airflow Right"),
        ("TH0a", "SSD"), ("TB0T", "Battery"),
        /* Intel fallback */
        ("TC0P", "CPU Package"), ("TG0P", "GPU"),
    ]

    init() {
        openSMCConnection()
    }

    deinit {
        if smcConnection != 0 { IOServiceClose(smcConnection) }
    }

    // MARK: - Public Refresh

    func refresh() {
        queue.async { [weak self] in
            guard let self, self.isConnected else { return }

            let temps = self.readTemperatures()
            let fanData = self.readFans()

            DispatchQueue.main.async {
                self.temperatures = temps
                self.fans = fanData
            }
        }
    }

    // MARK: - Temperature Reading (direct SMC)

    private func readTemperatures() -> [ThermalReading] {
        var results: [ThermalReading] = []
        for (key, name) in Self.temperatureKeys {
            if let temp = smcReadFloat(key), temp > 0, temp < 150 {
                results.append(ThermalReading(
                    id: key, sensorName: name, smcKey: key, temperature: temp
                ))
            }
        }
        return results
    }

    private static func sortOrder(_ name: String) -> Int {
        if name.hasPrefix("CPU") { return 0 }
        if name.hasPrefix("GPU") { return 1 }
        if name.hasPrefix("SoC") { return 2 }
        return 3
    }

    // MARK: - SMC Connection

    private func openSMCConnection() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return }
        let kr = IOServiceOpen(service, mach_task_self_, 0, &smcConnection)
        IOObjectRelease(service)
        isConnected = (kr == kIOReturnSuccess)
    }

    // MARK: - Fan Reading (real SMC data)

    private func readFans() -> [FanReading] {
        guard isConnected else { return [] }

        guard let fanCountByte = smcReadUInt8("FNum"), fanCountByte > 0 else { return [] }
        var results: [FanReading] = []

        for i in 0..<Int(fanCountByte) {
            let actual = smcReadFloat("F\(i)Ac") ?? 0
            let minRPM = smcReadFloat("F\(i)Mn") ?? 0
            let maxRPM = smcReadFloat("F\(i)Mx") ?? 6500

            results.append(FanReading(
                id: i,
                fanIndex: i,
                currentRPM: actual,
                minRPM: minRPM,
                maxRPM: maxRPM
            ))
        }
        return results
    }

    // MARK: - Low-Level SMC Access (Apple Silicon: little-endian keys, 80-byte struct)

    /// 80-byte SMC struct for Apple Silicon IOConnectCallStructMethod
    private struct AppleSiliconSMCData {
        var bytes: (
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 0-7   (key at 0-3)
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 8-15
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 16-23
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 24-31 (dataSize at 28-31)
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 32-39 (dataType at 32-35)
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 40-47 (result at 40, cmd at 42)
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 48-55 (data starts at 48)
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 56-63
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8, // 64-71
            UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8  // 72-79
        ) = (
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
            0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
        )
    }

    /// Encode 4-char SMC key as little-endian UInt32
    private func smcKeyLE(_ key: String) -> UInt32 {
        var code: UInt32 = 0
        for (i, c) in key.utf8.enumerated() where i < 4 {
            code = code | (UInt32(c) << (8 * UInt32(3 - i)))
        }
        return code.littleEndian
    }

    private func smcSetByte(_ data: inout AppleSiliconSMCData, offset: Int, value: UInt8) {
        withUnsafeMutableBytes(of: &data.bytes) { buf in buf[offset] = value }
    }

    private func smcSetUInt32(_ data: inout AppleSiliconSMCData, offset: Int, value: UInt32) {
        withUnsafeMutableBytes(of: &data.bytes) { buf in
            buf[offset] = UInt8(value & 0xFF)
            buf[offset+1] = UInt8((value >> 8) & 0xFF)
            buf[offset+2] = UInt8((value >> 16) & 0xFF)
            buf[offset+3] = UInt8((value >> 24) & 0xFF)
        }
    }

    private func smcGetByte(_ data: AppleSiliconSMCData, offset: Int) -> UInt8 {
        withUnsafeBytes(of: data.bytes) { buf in buf[offset] }
    }

    private func smcGetUInt32(_ data: AppleSiliconSMCData, offset: Int) -> UInt32 {
        withUnsafeBytes(of: data.bytes) { buf in
            UInt32(buf[offset]) | (UInt32(buf[offset+1]) << 8) |
            (UInt32(buf[offset+2]) << 16) | (UInt32(buf[offset+3]) << 24)
        }
    }

    private func smcCall(_ input: inout AppleSiliconSMCData) -> AppleSiliconSMCData? {
        var output = AppleSiliconSMCData()
        var outputSize = MemoryLayout<AppleSiliconSMCData>.stride
        let kr = withUnsafeMutablePointer(to: &input) { ip in
            withUnsafeMutablePointer(to: &output) { op in
                IOConnectCallStructMethod(smcConnection, 2, ip,
                    MemoryLayout<AppleSiliconSMCData>.stride, op, &outputSize)
            }
        }
        guard kr == kIOReturnSuccess else { return nil }
        guard smcGetByte(output, offset: 40) == 0 else { return nil }
        return output
    }

    private func smcReadUInt8(_ key: String) -> UInt8? {
        /* getKeyInfo */
        var info = AppleSiliconSMCData()
        smcSetUInt32(&info, offset: 0, value: smcKeyLE(key))
        smcSetByte(&info, offset: 42, value: 9)
        guard let infoOut = smcCall(&info) else { return nil }

        let dataSize = smcGetUInt32(infoOut, offset: 28)

        /* readKey */
        var read = AppleSiliconSMCData()
        smcSetUInt32(&read, offset: 0, value: smcKeyLE(key))
        smcSetByte(&read, offset: 42, value: 5)
        smcSetUInt32(&read, offset: 28, value: dataSize)
        guard let readOut = smcCall(&read) else { return nil }

        return smcGetByte(readOut, offset: 48)
    }

    private func smcReadFloat(_ key: String) -> Double? {
        /* getKeyInfo */
        var info = AppleSiliconSMCData()
        smcSetUInt32(&info, offset: 0, value: smcKeyLE(key))
        smcSetByte(&info, offset: 42, value: 9)
        guard let infoOut = smcCall(&info) else { return nil }

        let dataSize = smcGetUInt32(infoOut, offset: 28)
        let dataType = smcGetUInt32(infoOut, offset: 32)

        /* readKey */
        var read = AppleSiliconSMCData()
        smcSetUInt32(&read, offset: 0, value: smcKeyLE(key))
        smcSetByte(&read, offset: 42, value: 5)
        smcSetUInt32(&read, offset: 28, value: dataSize)
        guard let readOut = smcCall(&read) else { return nil }

        /* Parse based on data type */
        let b0 = smcGetByte(readOut, offset: 48)
        let b1 = smcGetByte(readOut, offset: 49)
        let b2 = smcGetByte(readOut, offset: 50)
        let b3 = smcGetByte(readOut, offset: 51)

        /* flt (IEEE 754 float, little-endian on Apple Silicon) */
        let fltType = UInt32(0x666C7420)  // "flt "
        if dataType == fltType || dataType == fltType.littleEndian {
            let raw = UInt32(b0) | (UInt32(b1) << 8) | (UInt32(b2) << 16) | (UInt32(b3) << 24)
            return Double(Float(bitPattern: raw))
        }
        /* fpe2 (fixed point 14.2) */
        let fpe2Type = UInt32(0x66706532)  // "fpe2"
        if dataType == fpe2Type || dataType == fpe2Type.littleEndian {
            let raw = (UInt16(b0) << 8) | UInt16(b1)
            return Double(raw) / 4.0
        }
        return nil
    }

    // MARK: - Computed Properties

    /// Best CPU temperature reading (max of all CPU/SoC sensors)
    var cpuTemperature: Double? {
        let cpuReadings = temperatures.filter {
            $0.smcKey.hasPrefix("Tp") || $0.smcKey.hasPrefix("Ts") || $0.smcKey.hasPrefix("TC")
        }
        guard !cpuReadings.isEmpty else { return nil }
        return cpuReadings.map(\.temperature).max()
    }

    /// Best GPU temperature reading (max of all GPU sensors)
    var gpuTemperature: Double? {
        let gpuReadings = temperatures.filter {
            $0.smcKey.hasPrefix("Tg") || $0.smcKey.hasPrefix("TG")
        }
        guard !gpuReadings.isEmpty else { return nil }
        return gpuReadings.map(\.temperature).max()
    }
}
