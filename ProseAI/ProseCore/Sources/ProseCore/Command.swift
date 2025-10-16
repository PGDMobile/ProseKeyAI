import Foundation

public struct Command: Identifiable, Codable, Equatable {
    public enum CommandType: String, Codable {
        case proofread
        case rewriteProfessional
        case rewriteFriendly
        case rewriteConcise
        case summarize
        case table
        case custom
    }

    public let id: UUID
    public var name: String
    public var template: String
    public var type: CommandType
    public var isUserGenerated: Bool
    public var example: String?
    public var variables: [String]

    public init(id: UUID = UUID(), name: String, template: String, type: CommandType, isUserGenerated: Bool, example: String? = nil, variables: [String] = []) {
        self.id = id
        self.name = name
        self.template = template
        self.type = type
        self.isUserGenerated = isUserGenerated
        self.example = example
        self.variables = variables
    }
}
