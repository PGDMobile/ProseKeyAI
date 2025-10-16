import UIKit
import ProseCore

final class CommandsViewController: UITableViewController {
    private let store: CommandStore
    private var commands: [Command] = []

    init(store: CommandStore) {
        self.store = store
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Comandos", comment: "")
        tabBarItem = UITabBarItem(title: NSLocalizedString("Comandos", comment: ""), image: UIImage(systemName: "text.badge.plus"), selectedImage: nil)
        tableView.register(CommandCell.self, forCellReuseIdentifier: CommandCell.reuseIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCommand))
        reload()
    }

    private func reload() {
        commands = store.commands()
        tableView.reloadData()
    }

    @objc private func addCommand() {
        let editor = CommandEditorViewController(command: nil) { [weak self] command in
            guard let self else { return }
            store.upsert(command)
            reload()
        }
        let navigation = UINavigationController(rootViewController: editor)
        present(navigation, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        commands.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommandCell.reuseIdentifier, for: indexPath) as! CommandCell
        cell.configure(with: commands[indexPath.row])
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let command = commands[indexPath.row]
        let editor = CommandEditorViewController(command: command) { [weak self] updated in
            guard let self else { return }
            store.upsert(updated)
            reload()
        }
        editor.onDelete = { [weak self] command in
            self?.store.delete(command)
            self?.reload()
        }
        let navigation = UINavigationController(rootViewController: editor)
        present(navigation, animated: true)
    }
}

private final class CommandCell: UITableViewCell {
    static let reuseIdentifier = "command"

    func configure(with command: Command) {
        var content = defaultContentConfiguration()
        content.text = command.name
        content.secondaryText = command.isUserGenerated ? NSLocalizedString("Personalizado", comment: "") : NSLocalizedString("Predeterminado", comment: "")
        content.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
        content.secondaryTextProperties.color = .secondaryLabel
        contentConfiguration = content
    }
}
