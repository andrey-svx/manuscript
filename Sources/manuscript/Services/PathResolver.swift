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
    
    static func getDirectory(for scope: ResolutionScope) -> URL {
        let fileManager = FileManager.default
        let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        
        switch scope {
        case .project:
            return currentDirectory.appendingPathComponent(".manuscript")
        case .local:
            return currentDirectory
        case .global:
            let executablePath = ProcessInfo.processInfo.arguments[0]
            let executableURL = URL(fileURLWithPath: executablePath)
            return executableURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("templates")
        }
    }

    static func getFileURL(filename: String, scope: ResolutionScope) throws -> URL {
        if (filename as NSString).pathExtension.isEmpty {
            throw ResolverError.missingExtension(filename: filename)
        }
        return getDirectory(for: scope).appendingPathComponent(filename)
    }
    
    static func resolve(filename: String, scope: ResolutionScope) throws -> URL {
        let targetURL = try getFileURL(filename: filename, scope: scope)
        
        if !FileManager.default.fileExists(atPath: targetURL.path) {
            throw ResolverError.fileNotFound(path: targetURL.path)
        }
        
        return targetURL
    }
}
