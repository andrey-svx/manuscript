import Foundation

enum ResolutionScope: String, CaseIterable {
    case project
    case local
    case global
}

struct PathResolver {
    enum ResolverError: Error, LocalizedError {
        case missingExtension(filename: String)
        case fileNotFound(path: String)
        
        var errorDescription: String? {
            switch self {
            case .missingExtension(let filename):
                return "Please provide the full filename including extension (e.g., \(filename).yaml)"
            case .fileNotFound(let path):
                return "File not found at: \(path)"
            }
        }
    }
    
    static func resolve(filename: String, scope: ResolutionScope) throws -> URL {
        // 1. Enforce extension
        if (filename as NSString).pathExtension.isEmpty {
            throw ResolverError.missingExtension(filename: filename)
        }
        
        let fileManager = FileManager.default
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        
        var targetURL: URL
        
        switch scope {
        case .project:
            // ./.manuscript/<filename>
            targetURL = currentDirectory
                .appendingPathComponent(".manuscript")
                .appendingPathComponent(filename)
            
        case .local:
            // ./<filename>
            targetURL = currentDirectory
                .appendingPathComponent(filename)
            
        case .global:
            // <executable_dir>/../templates/<filename>
            let executablePath = ProcessInfo.processInfo.arguments[0]
            let executableURL = URL(fileURLWithPath: executablePath)
            // executableURL is .../manuscript (the file)
            // deletingLastPathComponent gets the directory containing the executable
            // appending ".." or resolving parent to get to sibling folder "templates" if it's strictly adjacent to bin?
            // User requested: "<executable_dir>/../templates/"
            // If executable is in "bin", then ".." goes to root, then "templates".
            targetURL = executableURL
                .deletingLastPathComponent() // Directory of executable
                .deletingLastPathComponent() // Parent of directory (e.g. root of install)
                .appendingPathComponent("templates")
                .appendingPathComponent(filename)
        }
        
        // 2. Check existence
        if !fileManager.fileExists(atPath: targetURL.path) {
            throw ResolverError.fileNotFound(path: targetURL.path)
        }
        
        return targetURL
    }
}
