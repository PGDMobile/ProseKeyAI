import Foundation

public actor TransformService {
    private let client: AIClient
    private let chunker: TextChunker

    public init(client: AIClient, maxCharacters: Int = 2048) {
        self.client = client
        // Chunking keeps prompts under the per-request token limit without clipping text.
        self.chunker = TextChunker(maxCharacters: maxCharacters)
    }

    public func transform(text: String, using command: Command, tonePreference: Tone?) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProseAIError.emptyInput
        }

        switch command.type {
        case .proofread:
            return try await processChunks(text) { try await client.proofread($0) }
        case .rewriteProfessional:
            return try await processChunks(text) { try await client.rewrite($0, tone: .professional) }
        case .rewriteFriendly:
            return try await processChunks(text) { try await client.rewrite($0, tone: .friendly) }
        case .rewriteConcise:
            return try await processChunks(text) { try await client.rewrite($0, tone: .concise) }
        case .summarize:
            return try await client.summarize(text)
        case .table:
            return try await client.tableify(text)
        case .custom:
            let resolved = try resolveTemplate(command.template, variables: command.variables, text: text)
            return try await client.runCustomCommand(resolved.template, variables: resolved.variables)
        }
    }

    private func processChunks(_ text: String, handler: (String) async throws -> String) async throws -> String {
        let chunks = chunker.chunks(for: text)
        guard !chunks.isEmpty else { throw ProseAIError.emptyInput }
        var results: [String] = []
        for chunk in chunks {
            try Task.checkCancellation()
            let transformed = try await handler(chunk.text)
            results.append(transformed)
        }
        return results.joined(separator: "\n\n")
    }

    private func resolveTemplate(_ template: String, variables: [String], text: String) throws -> (template: String, variables: [String: String]) {
        var resolved = template
        var mapping: [String: String] = [:]
        let baseVariables: [String: String] = [
            "selection": text,
            "clipboard": UIPasteboardBridge.shared.string ?? ""
        ]

        let placeholders = variables.isEmpty ? Self.placeholders(in: template) : variables

        for variable in placeholders {
            let value = baseVariables[variable] ?? ""
            mapping[variable] = value
            resolved = resolved.replacingOccurrences(of: "{\(variable)}", with: value)
        }
        // Return the filled template plus a dictionary so the client can expose variable provenance.
        return (resolved, mapping)
    }

    private static func placeholders(in template: String) -> [String] {
        var results: [String] = []
        let pattern = #"\{([^\}]+)\}"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: template, range: NSRange(template.startIndex..., in: template))
            for match in matches {
                if let range = Range(match.range(at: 1), in: template) {
                    results.append(String(template[range]))
                }
            }
        }
        return results
    }
}
