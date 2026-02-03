import ArgumentParser
import Foundation
import AppKit
import ApplicationServices

struct Manuscript: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A zero-dependency tool to automate UI testing on iOS Simulator.",
        version: "1.0.0",
        subcommands: [Run.self]
    )

    struct Run: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Run a UI test scenario from a YAML config."
        )

        @Argument(help: "Path to the YAML configuration file to run.")
        var configPath: String

        @Flag(name: .long, help: "Print the full accessibility hierarchy dump of the active window.")
        var debug: Bool = false

        func run() throws {
            // Parse Config
            log("Reading config: \(configPath)...")
            let config: ManuscriptConfig
            do {
                config = try ConfigParser.parse(path: configPath)
            } catch {
                logError("Failed to parse YAML: \(error)")
                return // logError exits, but just in case
            }
            
            log("\n📜 Manuscript: \(ANSI.bold)\(config.name)\(ANSI.reset)", color: ANSI.yellow)
            log("   \(config.description)", color: ANSI.gray)
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
            
            var successCount = 0
            var failCount = 0
            
            for step in config.steps {
                var foundElement: AXUIElement?
                var strategyUsed = ""
                
                // Try all strategies to find the target
                
                // Strategy 1: ID
                if foundElement == nil {
                    foundElement = AccessibilityScanner.findElementByID(root: window, id: step.target)
                    if foundElement != nil { strategyUsed = "ID" }
                }
                
                // Strategy 2: Label (Anchor)
                if foundElement == nil {
                    foundElement = AccessibilityScanner.findFieldByLabel(root: window, label: step.target)
                    if foundElement != nil { strategyUsed = "Label Anchor" }
                }
                
                // Strategy 3: Placeholder
                if foundElement == nil {
                    foundElement = AccessibilityScanner.findFieldByPlaceholder(root: window, placeholder: step.target)
                    if foundElement != nil { strategyUsed = "Placeholder" }
                }
                
                // Strategy 4: Value Match (Pre-filled content)
                if foundElement == nil {
                    foundElement = AccessibilityScanner.findFieldByValue(root: window, value: step.target)
                    if foundElement != nil { strategyUsed = "Value Match" }
                }
                
                if let element = foundElement {
                    successCount += 1
                    print("\(ANSI.green)[OK]\(ANSI.reset) Found '\(step.target)' via \(strategyUsed)")
                    
                    switch step.type {
                    case .input:
                        if let valueToEnter = step.value {
                            if AccessibilityScanner.enterText(element: element, text: valueToEnter) {
                                print("     Action: Entered \"\(valueToEnter)\"")
                            } else {
                                print("     Action: \(ANSI.red)Failed to enter text\(ANSI.reset)")
                                failCount += 1 // Count partial failure as fail? Or warning? Let's count logic errors.
                            }
                        } else {
                             // Read mode if no value provided (optional feature)
                             let val = AccessibilityScanner.getValueOrDesc(element)
                             print("     Value: \"\(val)\"")
                        }
                    case .tap:
                        // Future implementation
                        print("     Action: Tap (Not implemented)")
                    }
                    
                } else {
                    failCount += 1
                    print("\(ANSI.red)[MISSING]\(ANSI.reset) Target '\(step.target)' not found")
                }
            }
            
            print("\n-----------------------")
            print("Total Steps: \(config.steps.count) | Success: \(successCount) | Failed: \(failCount)")
            
            if failCount > 0 {
                throw ExitCode(1)
            }
        }
    }
}
