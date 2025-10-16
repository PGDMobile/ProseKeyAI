import UIKit
import ProseCore

final class CommandEditorViewController: UITableViewController {
    private var command: Command?
    private let completion: (Command) -> Void

    var onDelete: ((Command) -> Void)?

    private lazy var nameField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("Nombre", comment: "")
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        return textField
    }()

    private lazy var templateView: UITextView = {
        let view = UITextView()
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true
        return view
    }()

    private lazy var variablesField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "selection, clipboard"
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        return textField
    }()

    private lazy var exampleField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("Ejemplo (opcional)", comment: "")
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        return textField
    }()

    init(command: Command?, completion: @escaping (Command) -> Void) {
        self.command = command
        self.completion = completion
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = command == nil ? NSLocalizedString("Nuevo comando", comment: "") : NSLocalizedString("Editar comando", comment: "")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        tableView.keyboardDismissMode = .interactive
        populateFields()
    }

    private func populateFields() {
        guard let command else { return }
        nameField.text = command.name
        templateView.text = command.template
        variablesField.text = command.variables.joined(separator: ", ")
        exampleField.text = command.example
        if command.isUserGenerated {
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save)),
                UIBarButtonItem(title: NSLocalizedString("Eliminar", comment: ""), style: .destructive, target: self, action: #selector(deleteCommand))
            ]
        }
    }

    @objc private func cancel() {
        dismiss(animated: true)
    }

    @objc private func save() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return }
        let template = templateView.text ?? ""
        let variables = variablesField.text?
            .split(separator: ',')
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
        let example = exampleField.text?.isEmpty == true ? nil : exampleField.text
        let existing = command ?? Command(name: name, template: template, type: .custom, isUserGenerated: true)
        let updated = Command(id: existing.id, name: name, template: template, type: .custom, isUserGenerated: true, example: example, variables: variables)
        completion(updated)
        dismiss(animated: true)
    }

    @objc private func deleteCommand() {
        guard let command else { return }
        onDelete?(command)
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 1 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return NSLocalizedString("Nombre", comment: "")
        case 1: return NSLocalizedString("Instrucciones", comment: "")
        default: return NSLocalizedString("Variables", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        switch indexPath.section {
        case 0: cell.contentView.addPinnedSubview(nameField)
        case 1:
            let stack = UIStackView(arrangedSubviews: [templateView, exampleField])
            stack.axis = .vertical
            stack.spacing = 12
            cell.contentView.addPinnedSubview(stack)
        default:
            cell.contentView.addPinnedSubview(variablesField)
        }
        return cell
    }
}

private extension UIView {
    func addPinnedSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            view.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0)
        ])
    }
}
