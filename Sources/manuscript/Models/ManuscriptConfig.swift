import Foundation

struct ManuscriptConfig: Decodable {
    let name: String
    let description: String
    let steps: [Step]

    struct Step: Decodable {
        let type: StepType
        let target: String
        let value: String?
    }

    enum StepType: String, Decodable {
        case input
        case tap // Reserved for future use
    }
}
