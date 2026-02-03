import Foundation
import Yams

class ConfigParser {
    static func parse(path: String) throws -> ManuscriptConfig {
        let url = URL(fileURLWithPath: path)
        let content = try String(contentsOf: url, encoding: .utf8)
        let decoder = YAMLDecoder()
        return try decoder.decode(ManuscriptConfig.self, from: content)
    }
}
