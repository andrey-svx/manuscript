import ArgumentParser
import Foundation

extension Manuscript {
    struct Init: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Initialize a new Manuscript project configuration."
        )

        func run() throws {
            let fileManager = FileManager.default
            let currentPath = fileManager.currentDirectoryPath
            let manuscriptDir = URL(fileURLWithPath: currentPath).appendingPathComponent(".manuscript")
            
            // Check if folder exists
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: manuscriptDir.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    print("\(ANSI.red)Error: Manuscript is already initialized in \(manuscriptDir.path)\(ANSI.reset)")
                    throw ExitCode(1)
                }
            }
            
            do {
                // Create .manuscript folder
                try fileManager.createDirectory(at: manuscriptDir, withIntermediateDirectories: true, attributes: nil)
                
                // Example content
                let exampleContent = """
                title: "Login Example"
                steps:
                  # 1. Search by Accessibility ID
                  # The most reliable method. Set .accessibilityIdentifier in your Swift code.
                  - target: "username_field" 
                    value: "my_user"

                  # 2. Search by Label (Anchor)
                  # Useful for finding fields next to a static text label (e.g. "Password").
                  - target: "Password"       
                    value: "secret123"

                  # 3. Search by Placeholder
                  # Finds a text field displaying this placeholder text.
                  - target: "Enter your email"
                    value: "test@example.com"
                  
                  # 4. Search by Value
                  # Finds a field that already contains this specific text value.
                  - target: "Existing Value"
                    value: "New Value"
                """
                
                let exampleFile = manuscriptDir.appendingPathComponent("example.yaml")
                try exampleContent.write(to: exampleFile, atomically: true, encoding: .utf8)
                
                print("\(ANSI.green)Initialized empty Manuscript repository in .manuscript/\(ANSI.reset)")
                print("Created example configuration at: .manuscript/example.yaml")
                
            } catch {
                print("\(ANSI.red)Failed to initialize: \(error.localizedDescription)\(ANSI.reset)")
                throw ExitCode(1)
            }
        }
    }
}
