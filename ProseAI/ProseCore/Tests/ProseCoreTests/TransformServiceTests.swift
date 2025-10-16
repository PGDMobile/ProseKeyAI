import XCTest
@testable import ProseCore

final class TransformServiceTests: XCTestCase {
    func testTransformsUsingChunking() async throws {
        let client = StubClient()
        let service = TransformService(client: client, maxCharacters: 4)
        let command = Command(name: "Proofread", template: "", type: .proofread, isUserGenerated: false)
        let result = try await service.transform(text: "abcdabcd", using: command, tonePreference: nil)
        XCTAssertEqual(result, "proofread\n\nproofread")
        XCTAssertEqual(client.proofreadCalls, ["abcd", "abcd"])
    }

    func testCustomCommandResolvesSelection() async throws {
        let client = StubClient()
        let service = TransformService(client: client)
        UIPasteboardBridge.shared.string = "clipboard"
        let command = Command(name: "Custom", template: "Say {selection} and {clipboard}", type: .custom, isUserGenerated: true, variables: ["selection", "clipboard"])
        let result = try await service.transform(text: "selection text", using: command, tonePreference: nil)
        XCTAssertEqual(result, "custom")
        XCTAssertEqual(client.customTemplate, "Say selection text and clipboard")
    }
}

private final class StubClient: AIClient {
    var proofreadCalls: [String] = []
    var customTemplate: String?

    func proofread(_ text: String) async throws -> String {
        proofreadCalls.append(text)
        return "proofread"
    }

    func rewrite(_ text: String, tone: Tone) async throws -> String {
        return "rewrite-\(tone.rawValue)"
    }

    func summarize(_ text: String) async throws -> String {
        return "summary"
    }

    func tableify(_ text: String) async throws -> String {
        return "table"
    }

    func runCustomCommand(_ template: String, variables: [String : String]) async throws -> String {
        customTemplate = template
        return "custom"
    }
}
