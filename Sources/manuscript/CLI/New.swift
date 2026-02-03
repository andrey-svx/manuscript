import ArgumentParser
import Foundation

extension Manuscript {
    struct New: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Create a new Manuscript configuration file."
        )

        @Argument(help: "The filename of the new configuration (must end with .yaml).")
        var filename: String

        @Flag(help: "The scope where to create the file.")
        var scope: ResolutionScope = .project

        func run() throws {
            // 1. Validate filename
            guard filename.hasSuffix(".yaml") else {
                print("\(ANSI.red)Error: Filename must end with .yaml\(ANSI.reset)")
                throw ExitCode(1)
            }

            // 2. Resolve Path
            let targetURL: URL
            do {
                targetURL = try PathResolver.getFileURL(filename: filename, scope: scope)
            } catch {
                print("\(ANSI.red)Error: \(error.localizedDescription)\(ANSI.reset)")
                throw ExitCode(1)
            }

            let fileManager = FileManager.default

            // 3. Check existence
            if fileManager.fileExists(atPath: targetURL.path) {
                print("\(ANSI.red)Error: File already exists at \(targetURL.path)\(ANSI.reset)")
                throw ExitCode(1)
            }

            // Ensure directory exists
            let directory = targetURL.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                do {
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                     print("\(ANSI.red)Error: Could not create directory \(directory.path)\(ANSI.reset)")
                     throw ExitCode(1)
                }
            }

            // 4. Create File
            let template = """
            title: "\(filename.replacingOccurrences(of: ".yaml", with: ""))"
            steps:
              - target: "example_element"
                value: "Hello World"
            """

            do {
                try template.write(to: targetURL, atomically: true, encoding: .utf8)
                print("\(ANSI.green)Created \(filename) in \(scope) scope.\(ANSI.reset)")
                print("Path: \(targetURL.path)")
            } catch {
                print("\(ANSI.red)Failed to write file: \(error.localizedDescription)\(ANSI.reset)")
                throw ExitCode(1)
            }
        }
    }
}
