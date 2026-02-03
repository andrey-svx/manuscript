import Foundation

struct SimulatorDevice {
    let name: String
    let udid: String
    let state: String
    let osVersion: String
}

struct SimctlDevice: Decodable {
    let name: String
    let udid: String
    let state: String
}

struct SimulatorList: Decodable {
    let devices: [String: [SimctlDevice]]
}
