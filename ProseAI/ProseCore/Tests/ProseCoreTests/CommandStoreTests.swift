import XCTest
@testable import ProseCore

final class CommandStoreTests: XCTestCase {
    func testUpsertAndDelete() {
        let defaults = UserDefaults(suiteName: "testSuite")!
        defaults.removePersistentDomain(forName: "testSuite")
        let store = CommandStore(userDefaults: defaults)
        var command = Command(name: "Test", template: "Do it", type: .custom, isUserGenerated: true)
        store.upsert(command)
        XCTAssertTrue(store.commands().contains(where: { $0.name == "Test" }))
        command = Command(id: command.id, name: "Updated", template: "Do it", type: .custom, isUserGenerated: true)
        store.upsert(command)
        let updated = store.commands().first(where: { $0.id == command.id })
        XCTAssertEqual(updated?.name, "Updated")
        store.delete(command)
        XCTAssertFalse(store.commands().contains(where: { $0.id == command.id }))
    }
}
