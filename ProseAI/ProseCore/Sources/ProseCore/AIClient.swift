import Foundation

public enum Tone: String, Codable, CaseIterable {
    case professional
    case friendly
    case concise
}

public protocol AIClient {
    func proofread(_ text: String) async throws -> String
    func rewrite(_ text: String, tone: Tone) async throws -> String
    func summarize(_ text: String) async throws -> String
    func tableify(_ text: String) async throws -> String
    func runCustomCommand(_ template: String, variables: [String: String]) async throws -> String
}
