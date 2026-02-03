import Foundation

class SimulatorManager {
    static func getAllBootedSimulators() throws -> [SimulatorDevice] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        task.arguments = ["simctl", "list", "devices", "-j"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let list = try JSONDecoder().decode(SimulatorList.self, from: data)
        
        var bootedDevices: [SimulatorDevice] = []
        
        for (runtimeKey, devices) in list.devices {
            let booted = devices.filter { $0.state == "Booted" }
            let osVersion = parseOSVersion(from: runtimeKey)
            
            for b in booted {
                bootedDevices.append(SimulatorDevice(
                    name: b.name,
                    udid: b.udid,
                    state: b.state,
                    osVersion: osVersion
                ))
            }
        }
        
        return bootedDevices
    }
    
    private static func parseOSVersion(from key: String) -> String {
        let components = key.components(separatedBy: ".")
        guard let last = components.last else { return key }
        let parts = last.components(separatedBy: "-")
        if parts.count >= 2 {
            let osName = parts[0]
            let version = parts.dropFirst().joined(separator: ".")
            return "\(osName) \(version)"
        }
        return last
    }
}
