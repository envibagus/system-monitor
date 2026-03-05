import Foundation
import Darwin

@Observable
final class ProcessService: @unchecked Sendable {
    private(set) var processes: [MonitoredProcess] = []
    private(set) var totalProcessCount: Int = 0

    private let queue = DispatchQueue(label: "com.systemmonitor.process", qos: .utility)

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let result = self.enumerateProcesses()
            DispatchQueue.main.async {
                self.processes = result
                self.totalProcessCount = result.count
            }
        }
    }

    private func enumerateProcesses() -> [MonitoredProcess] {
        // Get all PIDs
        let bufferSize = proc_listallpids(nil, 0)
        guard bufferSize > 0 else { return [] }

        var pids = [pid_t](repeating: 0, count: Int(bufferSize))
        let actualCount = proc_listallpids(&pids, Int32(MemoryLayout<pid_t>.stride * pids.count))
        guard actualCount > 0 else { return [] }

        var results: [MonitoredProcess] = []

        for i in 0..<Int(actualCount) {
            let pid = pids[i]
            guard pid > 0 else { continue }

            // Get task info for memory and parent PID
            var taskInfo = proc_taskallinfo()
            let taskInfoSize = Int32(MemoryLayout<proc_taskallinfo>.stride)
            let infoResult = proc_pidinfo(
                pid,
                PROC_PIDTASKALLINFO,
                0,
                &taskInfo,
                taskInfoSize
            )
            guard infoResult == taskInfoSize else { continue }

            // Get executable path
            var pathBuffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            let pathResult = proc_pidpath(pid, &pathBuffer, UInt32(MAXPATHLEN))

            let path = pathResult > 0 ? String(cString: pathBuffer) : ""
            let name = Self.processName(from: path, fallback: taskInfo)
            let parentPid = taskInfo.pbsd.pbi_ppid
            let residentMemory = UInt64(taskInfo.ptinfo.pti_resident_size)

            results.append(MonitoredProcess(
                id: pid,
                pid: pid,
                parentPid: pid_t(parentPid),
                name: name,
                executablePath: path,
                residentMemory: residentMemory,
                cpuUsage: 0,
                isElectron: false,
                bundlePath: nil
            ))
        }

        // Sort by resident memory descending
        results.sort { $0.residentMemory > $1.residentMemory }
        return results
    }

    private static func processName(from path: String, fallback info: proc_taskallinfo) -> String {
        if !path.isEmpty {
            return (path as NSString).lastPathComponent
        }
        // Fallback to comm name from bsd info
        let comm = info.pbsd.pbi_comm
        return withUnsafePointer(to: comm) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) { cPtr in
                String(cString: cPtr)
            }
        }
    }
}
