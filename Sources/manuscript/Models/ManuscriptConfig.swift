import Foundation

struct ManuscriptConfig: Decodable {
    struct Field: Decodable {
        let id: String?
        let value: String?
        let label: String?
        let placeholder: String?
        
        var displayName: String {
            if let id = id { return id }
            if let label = label { return "Label: \(label)" }
            if let placeholder = placeholder { return "Placeholder: \(placeholder)" }
            return "Unnamed Field"
        }
    }
    let title: String
    let fields: [Field]
}
