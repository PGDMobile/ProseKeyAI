import Foundation
import AppleIntelligence

/// Concrete client that delegates to Apple Intelligence foundation models running fully on-device.
/// The implementation assumes the existence of iOS 26 public APIs for text generation.
public final class AppleIntelligenceClient: AIClient {
    private let modelIdentifier: String
    private let session: AITextGenerationSession
    private let availability: AppleIntelligenceAvailabilityProviding

    public init(modelIdentifier: String = "foundation.small", availability: AppleIntelligenceAvailabilityProviding = AppleIntelligenceAvailability.shared) throws {
        self.modelIdentifier = modelIdentifier
        self.availability = availability
        guard availability.isAvailable else {
            throw ProseAIError.unavailable
        }
        // Session spins up the local Apple Intelligence foundation model without any network traffic.
        self.session = try AITextGenerationSession(model: modelIdentifier, options: .init(mode: .onDeviceOnly))
    }

    public func proofread(_ text: String) async throws -> String {
        try await generate(
            prompt: "Proofread the following text. Fix grammar, spelling, and clarity while keeping a neutral tone.\n\n\(text)",
            system: "You are a meticulous proofreader that provides corrected text only."
        )
    }

    public func rewrite(_ text: String, tone: Tone) async throws -> String {
        let descriptor: String
        switch tone {
        case .professional: descriptor = "professional"
        case .friendly: descriptor = "friendly and warm"
        case .concise: descriptor = "concise and direct"
        }
        return try await generate(
            prompt: "Rewrite the following text using a \(descriptor) tone. Preserve meaning.\n\n\(text)",
            system: "You are a writing assistant that only returns the rewritten text."
        )
    }

    public func summarize(_ text: String) async throws -> String {
        return try await generate(
            prompt: "Summarize the following content using short bullet points with key takeaways.\n\n\(text)",
            system: "You produce concise markdown bullet summaries."
        )
    }

    public func tableify(_ text: String) async throws -> String {
        let hint = headerHint(for: text)
        return try await generate(
            prompt: "Convert the following content into a markdown table. Use these header hints if helpful: \(hint). Ensure valid markdown syntax.\n\n\(text)",
            system: "Return only markdown table text."
        )
    }

    public func runCustomCommand(_ template: String, variables: [String : String]) async throws -> String {
        let variableDescription = variables.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
        return try await generate(
            prompt: "Use the following instructions to transform the text.\nInstruction:\n\(template)\n\nVariables:\n\(variableDescription)",
            system: "Respond with transformed text only."
        )
    }

    // Offer simple heuristics so the model can build markdown headers even without explicit structure.
    private func headerHint(for text: String) -> String {
        let lines = text.split(separator: "\n").map { String($0) }
        if let first = lines.first, first.contains(":") {
            let headers = first.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if headers.count > 1 {
                return headers.joined(separator: ", ")
            }
        }
        if lines.count > 1 {
            let tokens = lines[0].split(separator: " ").prefix(3).map(String.init)
            if !tokens.isEmpty {
                return tokens.joined(separator: ", ")
            }
        }
        let words = text.split(separator: " ").prefix(3).map(String.init)
        return words.joined(separator: ", ")
    }

    private func generate(prompt: String, system: String) async throws -> String {
        try Task.checkCancellation()
        guard availability.isAvailable else { throw ProseAIError.unavailable }
        // Single generation request keeps everything on-device and respects token budget.
        let request = AITextGenerationRequest(prompt: prompt, systemPrompt: system, maxTokens: 1024)
        do {
            var collected: [String] = []
            for try await event in session.generate(request) {
                try Task.checkCancellation()
                switch event {
                case .text(let text):
                    collected.append(text)
                case .completed:
                    break
                case .progress:
                    continue
                }
            }
            return collected.joined()
        } catch is CancellationError {
            throw ProseAIError.cancelled
        } catch let error as AppleIntelligenceError {
            switch error {
            case .modelUnavailable:
                throw ProseAIError.unavailable
            case .inputTooLong:
                throw ProseAIError.lengthLimit
            default:
                throw ProseAIError.underlying(error.localizedDescription)
            }
        } catch {
            throw ProseAIError.underlying(error.localizedDescription)
        }
    }
}

public protocol AppleIntelligenceAvailabilityProviding {
    var isAvailable: Bool { get }
}

public struct AppleIntelligenceAvailability: AppleIntelligenceAvailabilityProviding {
    public static let shared = AppleIntelligenceAvailability()
    private init() {}

    public var isAvailable: Bool {
        return AITextGenerationSession.isModelAvailable("foundation.small")
    }
}
