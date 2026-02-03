import ArgumentParser
import Foundation
import AppKit
import ApplicationServices

struct Manuscript: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A zero-dependency tool to automate UI testing on iOS Simulator.",
        version: "1.0.0"
    )

    @Option(name: .shortAndLong, help: "Path to the YAML configuration file to run.")
    var screen: String

    @Flag(name: .long, help: "Print the full accessibility hierarchy dump of the active window.")
    var debug: Bool = false

    func run() throws {
        // Parse Config
        log("Reading config: \(screen)...")
        let config: ManuscriptConfig
        do {
            config = try ConfigParser.parse(path: screen)
        } catch {
            logError("Failed to parse YAML: \(error)")
            return // logError exits, but just in case
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
        guard let axApp = AccessibilityScanner.findSimulatorApp(pid: simApp.processIdentifier) else {
            logError("Could not create AXUIElement for Simulator app")
            return
        }
        
        // 3. Find ACTIVE window
        log("Looking for active simulator window...")
        guard let result = AccessibilityScanner.findActiveSimulatorWindow(app: axApp, candidates: bootedDevices) else {
            logError("Could not find any active window matching a booted simulator.")
            return
        }
        
        let (window, device) = result
        
        log("Target: \(device.name) (\(device.osVersion)) (\(device.udid))", color: ANSI.green)
        
        if debug {
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
            throw ExitCode(1)
        }
    }
}
