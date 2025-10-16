import Foundation

extension CommandStore {
    public static let shared: CommandStore = {
        // Shared defaults live in the App Group so both the host app and keyboard read the same data.
        let defaults = UserDefaults(suiteName: "group.com.yourcompany.proseai") ?? .standard
        defaults.register(defaults: [
            "quickProofreadEnabled": true,
            "defaultTone": Tone.professional.rawValue
        ])
        return CommandStore(userDefaults: defaults)
    }()
}
