import ArgumentParser
import Foundation

extension Manuscript {
    struct Deintegrate: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove the Manuscript configuration from the current project."
        )

        func run() throws {
            let fileManager = FileManager.default
            let currentPath = fileManager.currentDirectoryPath
            let manuscriptDir = URL(fileURLWithPath: currentPath).appendingPathComponent(".manuscript")
            
            // Check if folder exists
            var isDir: ObjCBool = false
            if !fileManager.fileExists(atPath: manuscriptDir.path, isDirectory: &isDir) || !isDir.boolValue {
                print("\(ANSI.yellow)Manuscript is not initialized in this directory.\(ANSI.reset)")
                return
            }
            
            // Ask for confirmation
            print("Are you sure you want to delete .manuscript folder? (y/n)", terminator: " ")
            guard let input = readLine(), input.lowercased() == "y" else {
                print("Operation aborted.")
                return
            }
            
            do {
                try fileManager.removeItem(at: manuscriptDir)
                print("\(ANSI.green)Manuscript configuration removed.\(ANSI.reset)")
            } catch {
                print("\(ANSI.red)Failed to remove configuration: \(error.localizedDescription)\(ANSI.reset)")
                throw ExitCode(1)
            }
        }
    }
}
