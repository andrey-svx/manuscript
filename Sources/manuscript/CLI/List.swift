import ArgumentParser
import Foundation

extension Manuscript {
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List available Manuscript configurations."
        )

        @Flag(help: "The scope where to search for files.")
        var scope: ResolutionScope = .project

        func run() throws {
            let directory = PathResolver.getDirectory(for: scope)
            let fileManager = FileManager.default
            
            // Check if directory exists
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDir), isDir.boolValue else {
                print("\(ANSI.yellow)No configurations found in \(scope) scope (\(directory.path)).\(ANSI.reset)")
                return
            }
            
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                let yamlFiles = fileURLs.filter { $0.pathExtension == "yaml" }
                
                if yamlFiles.isEmpty {
                    print("No .yaml configurations found in \(directory.path)")
                    return
                }
                
                print("Configurations in \(scope) scope:")
                for fileURL in yamlFiles {
                    let filename = fileURL.lastPathComponent
                    do {
                        let config = try ConfigParser.parse(path: fileURL.path)
                        print("  - \(filename) (\(config.name))")
                    } catch {
                        print("  - \(filename) \(ANSI.red)[INVALID]\(ANSI.reset)")
                    }
                }
            } catch {
                print("\(ANSI.red)Failed to list files: \(error.localizedDescription)\(ANSI.reset)")
                throw ExitCode(1)
            }
        }
    }
}
