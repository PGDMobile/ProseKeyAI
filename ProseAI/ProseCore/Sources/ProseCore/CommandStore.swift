import Foundation

public final class CommandStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storageKey = "commands"

    public init(userDefaults: UserDefaults) {
        self.defaults = userDefaults
        registerDefaults()
    }

    private func registerDefaults() {
        guard defaults.object(forKey: storageKey) == nil else { return }
        let defaults = Self.defaultCommands()
        if let data = try? encoder.encode(defaults) {
            self.defaults.set(data, forKey: storageKey)
        }
    }

    public func commands() -> [Command] {
        guard let data = defaults.data(forKey: storageKey),
              let items = try? decoder.decode([Command].self, from: data) else {
            return []
        }
        return items
    }

    public func save(_ commands: [Command]) {
        if let data = try? encoder.encode(commands) {
            defaults.set(data, forKey: storageKey)
        }
    }

    public func upsert(_ command: Command) {
        var existing = commands()
        if let index = existing.firstIndex(where: { $0.id == command.id }) {
            existing[index] = command
        } else {
            existing.append(command)
        }
        save(existing)
    }

    public func delete(_ command: Command) {
        let filtered = commands().filter { $0.id != command.id }
        save(filtered)
    }

    public static func defaultCommands() -> [Command] {
        return [
            Command(name: NSLocalizedString("Proofread", comment: ""), template: "Proofread the text for grammar and clarity while keeping a neutral tone.", type: .proofread, isUserGenerated: false),
            Command(name: NSLocalizedString("Rewrite · Professional", comment: ""), template: "Rewrite the text using a professional tone.", type: .rewriteProfessional, isUserGenerated: false),
            Command(name: NSLocalizedString("Rewrite · Friendly", comment: ""), template: "Rewrite the text using a friendly tone.", type: .rewriteFriendly, isUserGenerated: false),
            Command(name: NSLocalizedString("Rewrite · Concise", comment: ""), template: "Rewrite the text making it concise and direct.", type: .rewriteConcise, isUserGenerated: false),
            Command(name: NSLocalizedString("Summarize", comment: ""), template: "Summarize the text using clear bullet points.", type: .summarize, isUserGenerated: false),
            Command(name: NSLocalizedString("Convert to Table", comment: ""), template: "Convert the text into a markdown table with headers inferred from the content.", type: .table, isUserGenerated: false),
            Command(name: "Product Feature Highlights", template: "Rewrite {selection} as a product update with bullet points for features and impact.", type: .custom, isUserGenerated: true, example: "We've shipped faster sync and better sharing.", variables: ["selection"]),
            Command(name: "Customer Reply", template: "Respond to {selection} with a friendly acknowledgement and next steps.", type: .custom, isUserGenerated: true, variables: ["selection"])
        ]
    }
}
