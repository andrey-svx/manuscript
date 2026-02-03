import Foundation

struct ManuscriptConfig: Decodable {
    let name: String
    let description: String?
    let steps: [Step]

    private enum CodingKeys: String, CodingKey {
        case name
        case title
        case description
        case steps
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Support both 'name' and 'title' keys
        if let nameValue = try? container.decode(String.self, forKey: .name) {
            self.name = nameValue
        } else if let titleValue = try? container.decode(String.self, forKey: .title) {
            self.name = titleValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.name, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Expected key 'name' or 'title'"))
        }
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.steps = try container.decode([Step].self, forKey: .steps)
    }

    struct Step: Decodable {
        let target: String
        let value: String?
    }
}
