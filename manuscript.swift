#!/usr/bin/swift

import Foundation
import Cocoa
import ApplicationServices

// MARK: - Models

struct ManuscriptConfig {
    struct Field {
        let id: String?
        let value: String?
        let label: String?
        let placeholder: String?
        
        var displayName: String {
            if let id = id { return id }
            if let label = label { return "Label: \(label)" }
            if let placeholder = placeholder { return "Placeholder: \(placeholder)" }
            return "Unnamed Field"
        }
    }
    let title: String
    let fields: [Field]
}

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

// MARK: - Helpers

enum ANSI {
    static let reset = "\u{001B}[0m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let bold = "\u{001B}[1m"
    static let gray = "\u{001B}[90m"
}

func log(_ message: String, color: String = ANSI.reset) {
    print("\(color)\(message)\(ANSI.reset)")
}

func logError(_ message: String) {
    print("\(ANSI.red)Error: \(message)\(ANSI.reset)")
    exit(1)
}

func printHelp() {
    print("""
    \(ANSI.bold)📜 Manuscript - iOS Simulator UI Inspector\(ANSI.reset)
    
    A zero-dependency tool to automate UI testing on iOS Simulator.
    
    \(ANSI.bold)USAGE:\(ANSI.reset)
      ./manuscript.swift [options]
    
    \(ANSI.bold)OPTIONS:\(ANSI.reset)
      \(ANSI.green)--screen <path>\(ANSI.reset)   Path to the YAML configuration file to run.
      \(ANSI.green)--debug\(ANSI.reset)           Print the full accessibility hierarchy dump of the active window.
      \(ANSI.green)--help, -h\(ANSI.reset)        Show this help message.
    
    \(ANSI.bold)EXAMPLES:\(ANSI.reset)
      ./manuscript.swift --screen login.yaml
      ./manuscript.swift --screen login.yaml --debug
    
    \(ANSI.bold)YAML FORMAT EXAMPLE:\(ANSI.reset)
      \(ANSI.gray)title: "Login Screen"
      fields:
        - id: "username"
          value: "user"
        - label: "Password"
          value: "secret"\(ANSI.reset)
    """)
    exit(0)
}

// MARK: - Config Parser

class ConfigParser {
    static func parse(path: String) throws -> ManuscriptConfig {
        let url = URL(fileURLWithPath: path)
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines)
        
        var fields: [ManuscriptConfig.Field] = []
        var title: String = "Unknown Screen"
        
        var currentId: String?
        var currentValue: String?
        var currentLabel: String?
        var currentPlaceholder: String?
        var hasContent = false
        
        func flush() {
            if hasContent {
                fields.append(ManuscriptConfig.Field(
                    id: currentId,
                    value: currentValue,
                    label: currentLabel,
                    placeholder: currentPlaceholder
                ))
                currentId = nil
                currentValue = nil
                currentLabel = nil
                currentPlaceholder = nil
                hasContent = false
            }
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            if trimmed.starts(with: "title:") {
                if let range = trimmed.range(of: "title:") {
                    title = extractValue(from: trimmed, after: range)
                }
                continue
            }
            
            if trimmed.starts(with: "-") {
                flush()
                hasContent = true 
            }
            
            if let range = trimmed.range(of: "id:") {
                currentId = extractValue(from: trimmed, after: range)
            }
            if let range = trimmed.range(of: "value:") {
                currentValue = extractValue(from: trimmed, after: range)
            }
            if let range = trimmed.range(of: "label:") {
                currentLabel = extractValue(from: trimmed, after: range)
            }
            if let range = trimmed.range(of: "placeholder:") {
                currentPlaceholder = extractValue(from: trimmed, after: range)
            }
        }
        flush()
        
        return ManuscriptConfig(title: title, fields: fields)
    }
    
    private static func extractValue(from line: String, after range: Range<String.Index>) -> String {
        let val = String(line[range.upperBound...])
        return extractQuotedOrPlain(val)
    }
    
    private static func extractQuotedOrPlain(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }
        if trimmed.hasPrefix("'") && trimmed.hasSuffix("'") {
            return String(trimmed.dropFirst().dropLast())
        }
        return trimmed
    }
}

// MARK: - Simulator Manager

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

// MARK: - Accessibility Scanner

class AccessibilityScanner {
    
    static func findSimulatorApp(pid: pid_t) -> AXUIElement? {
        return AXUIElementCreateApplication(pid)
    }
    
    static func findActiveSimulatorWindow(app: AXUIElement, candidates: [SimulatorDevice]) -> (AXUIElement, SimulatorDevice)? {
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)
        guard result == .success, let windows = windowsRef as? [AXUIElement] else { return nil }
        
        for window in windows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            guard let title = titleRef as? String else { continue }
            
            for device in candidates {
                if title.contains(device.name) {
                    return (window, device)
                }
            }
        }
        return nil
    }
    
    // MARK: - Search Strategies
    
    static func findElementByID(root: AXUIElement, id: String) -> AXUIElement? {
        var idRef: CFTypeRef?
        AXUIElementCopyAttributeValue(root, kAXIdentifierAttribute as CFString, &idRef)
        if let currentId = idRef as? String, currentId == id {
            if isTextField(root) { return root }
            return findFirstTextField(root: root)
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findElementByID(root: child, id: id) {
                    return found
                }
            }
        }
        return nil
    }
    
    static func findFieldByLabel(root: AXUIElement, label: String) -> AXUIElement? {
        var foundLabel = false
        return scanForLabelAndNextField(root: root, label: label, foundLabel: &foundLabel)
    }
    
    private static func scanForLabelAndNextField(root: AXUIElement, label: String, foundLabel: inout Bool) -> AXUIElement? {
        if !foundLabel {
            if isStaticText(root) {
                if getValueOrDesc(root) == label {
                    foundLabel = true
                }
            }
        } else {
            if isTextField(root) {
                return root
            }
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = scanForLabelAndNextField(root: child, label: label, foundLabel: &foundLabel) {
                    return found
                }
            }
        }
        return nil
    }
    
    static func findFieldByPlaceholder(root: AXUIElement, placeholder: String) -> AXUIElement? {
        if isTextField(root) {
            if getValueOrDesc(root) == placeholder {
                return root
            }
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findFieldByPlaceholder(root: child, placeholder: placeholder) {
                    return found
                }
            }
        }
        return nil
    }
    
    static func findFieldByValue(root: AXUIElement, value: String) -> AXUIElement? {
        if isTextField(root) {
            if getValueOrDesc(root) == value {
                return root
            }
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findFieldByValue(root: child, value: value) {
                    return found
                }
            }
        }
        return nil
    }

    // MARK: - Utilities
    
    static func isTextField(_ element: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        guard let role = roleRef as? String else { return false }
        return role == kAXTextFieldRole as String || role == kAXTextAreaRole as String
    }
    
    static func isStaticText(_ element: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        guard let role = roleRef as? String else { return false }
        return role == kAXStaticTextRole as String
    }
    
    static func getValueOrDesc(_ element: AXUIElement) -> String {
        var valRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valRef)
        if let val = valRef as? String, !val.isEmpty { return val }
        
        var descRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        if let desc = descRef as? String, !desc.isEmpty { return desc }
        
        return ""
    }
    
    static func findFirstTextField(root: AXUIElement) -> AXUIElement? {
        if isTextField(root) { return root }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findFirstTextField(root: child) { return found }
            }
        }
        return nil
    }
    
    static func enterText(element: AXUIElement, text: String) -> Bool {
        let error = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, text as CFTypeRef)
        return error == .success
    }
    
    static func dumpHierarchy(element: AXUIElement, depth: Int = 0) {
        let indent = String(repeating: "  ", count: depth)
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = (roleRef as? String) ?? "Unknown"
        var idRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &idRef)
        let id = (idRef as? String) ?? ""
        var descRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        let desc = (descRef as? String) ?? ""
        var valueRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)
        var value = (valueRef as? String) ?? ""
        if value.count > 20 { value = String(value.prefix(17)) + "..." }
        let idStr = id.isEmpty ? "" : " id='\(ANSI.green)\(id)\(ANSI.reset)'"
        let descStr = desc.isEmpty ? "" : " desc='\(desc)'"
        let valStr = value.isEmpty ? "" : " val='\(value)'"
        print("\(indent)- [\(role)]\(idStr)\(descStr)\(valStr)")
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                dumpHierarchy(element: child, depth: depth + 1)
            }
        }
    }
}

// MARK: - Main

func main() {
    let args = CommandLine.arguments
    
    // Help Command
    if args.contains("--help") || args.contains("-h") {
        printHelp()
    }
    
    let debugMode = args.contains("--debug")
    
    guard let screenIndex = args.firstIndex(of: "--screen"), screenIndex + 1 < args.count else {
        // Only error if not asking for help
        if !args.contains("--help") && !args.contains("-h") {
            logError("Usage: manuscript.swift --screen <path_to_yaml> [--debug]\nTry --help for more info.")
        }
        return
    }
    
    let yamlPath = args[screenIndex + 1]
    
    // Parse Config
    log("Reading config: \(yamlPath)...")
    let config: ManuscriptConfig
    do {
        config = try ConfigParser.parse(path: yamlPath)
    } catch {
        logError("Failed to parse YAML: \(error)")
        return
    }
    
    log("\n📜 Manuscript: \(ANSI.bold)\(config.title)\(ANSI.reset)", color: ANSI.yellow)
    log("-----------------------------------------")
    
    // 1. Get all booted simulators
    log("Scanning booted simulators...")
    let bootedDevices: [SimulatorDevice]
    do {
        bootedDevices = try SimulatorManager.getAllBootedSimulators()
        log("Found \(bootedDevices.count) booted simulator(s).", color: ANSI.gray)
    } catch {
        logError(error.localizedDescription)
        return
    }
    
    if bootedDevices.isEmpty {
        logError("No booted simulators found.")
        return
    }
    
    // 2. Connect to Simulator.app
    let apps = NSWorkspace.shared.runningApplications
    guard let simApp = apps.first(where: { $0.bundleIdentifier == "com.apple.iphonesimulator" }) else {
        logError("Simulator.app is not running")
        return
    }
    let axApp = AccessibilityScanner.findSimulatorApp(pid: simApp.processIdentifier)!
    
    // 3. Find ACTIVE window
    log("Looking for active simulator window...")
    guard let result = AccessibilityScanner.findActiveSimulatorWindow(app: axApp, candidates: bootedDevices) else {
        logError("Could not find any active window matching a booted simulator.")
        return
    }
    
    let (window, device) = result
    
    log("Target: \(device.name) (\(device.osVersion)) (\(device.udid))", color: ANSI.green)
    
    if debugMode {
        log("\n--- Hierarchy Dump ---", color: ANSI.gray)
        AccessibilityScanner.dumpHierarchy(element: window)
        log("----------------------\n", color: ANSI.gray)
    }
    
    log("\n--- Execution Report ---\n", color: ANSI.bold)
    
    var foundCount = 0
    var missingCount = 0
    
    for expected in config.fields {
        var foundElement: AXUIElement?
        var strategyUsed = ""
        
        // Strategy 1: ID
        if foundElement == nil, let id = expected.id {
            foundElement = AccessibilityScanner.findElementByID(root: window, id: id)
            if foundElement != nil { strategyUsed = "ID" }
        }
        
        // Strategy 2: Label (Anchor)
        if foundElement == nil, let label = expected.label {
            foundElement = AccessibilityScanner.findFieldByLabel(root: window, label: label)
            if foundElement != nil { strategyUsed = "Label Anchor" }
        }
        
        // Strategy 3: Placeholder
        if foundElement == nil, let placeholder = expected.placeholder {
            foundElement = AccessibilityScanner.findFieldByPlaceholder(root: window, placeholder: placeholder)
            if foundElement != nil { strategyUsed = "Placeholder" }
        }
        
        // Strategy 4: Value Match
        if foundElement == nil, let val = expected.value {
            foundElement = AccessibilityScanner.findFieldByValue(root: window, value: val)
            if foundElement != nil { strategyUsed = "Value Match (Already Filled)" }
        }
        
        if let element = foundElement {
            foundCount += 1
            print("\(ANSI.green)[OK]\(ANSI.reset) Found '\(expected.displayName)' via \(strategyUsed)")
            
            if let valueToEnter = expected.value {
                if strategyUsed == "Value Match (Already Filled)" {
                    print("     Action: Skipped (Already contains \"\(valueToEnter)\")")
                } else {
                    if AccessibilityScanner.enterText(element: element, text: valueToEnter) {
                        print("     Action: Entered \"\(valueToEnter)\"")
                    } else {
                        print("     Action: \(ANSI.red)Failed to enter text\(ANSI.reset)")
                    }
                }
            } else {
                let val = AccessibilityScanner.getValueOrDesc(element)
                print("     Value: \"\(val)\"")
            }
        } else {
            missingCount += 1
            print("\(ANSI.red)[MISSING]\(ANSI.reset) '\(expected.displayName)' not found")
        }
    }
    
    print("\n-----------------------")
    print("Total: \(config.fields.count) | Found: \(foundCount) | Missing: \(missingCount)")
    
    if missingCount > 0 {
        exit(1)
    } else {
        exit(0)
    }
}

main()
