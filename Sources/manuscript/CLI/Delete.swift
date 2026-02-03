import ArgumentParser
import Foundation

extension Manuscript {
    struct Delete: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Delete a Manuscript configuration file."
        )

        @Argument(help: "The filename of the configuration to delete (including extension).")
        var filename: String

        @Flag(help: "The scope where to search for the file.")
        var scope: ResolutionScope = .project

        func run() throws {
            let targetURL: URL
            do {
                targetURL = try PathResolver.resolve(filename: filename, scope: scope)
            } catch {
                print("\(ANSI.red)Error: \(error.localizedDescription)\(ANSI.reset)")
                throw ExitCode(1)
            }

            let fileManager = FileManager.default
            
            do {
                try fileManager.removeItem(at: targetURL)
                print("\(ANSI.green)Deleted \(filename) from \(scope) scope.\(ANSI.reset)")
            } catch {
                print("\(ANSI.red)Failed to delete file: \(error.localizedDescription)\(ANSI.reset)")
                throw ExitCode(1)
            }
        }
    }
}
