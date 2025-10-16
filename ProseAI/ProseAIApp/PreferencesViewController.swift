import UIKit
import ProseCore

final class PreferencesViewController: UITableViewController {
    private enum Preference: Int, CaseIterable {
        case defaultTone
        case quickProofread
    }

    private let defaults = UserDefaults(suiteName: "group.com.yourcompany.proseai") ?? .standard

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Preferencias", comment: "")
        tabBarItem = UITabBarItem(title: NSLocalizedString("Preferencias", comment: ""), image: UIImage(systemName: "slider.horizontal.3"), selectedImage: nil)
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int { Preference.allCases.count }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let preference = Preference(rawValue: section) else { return nil }
        switch preference {
        case .defaultTone:
            return NSLocalizedString("Tono predeterminado", comment: "")
        case .quickProofread:
            return NSLocalizedString("Corrección rápida", comment: "")
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        guard let preference = Preference(rawValue: indexPath.section) else { return cell }
        cell.selectionStyle = .none
        switch preference {
        case .defaultTone:
            var content = UIListContentConfiguration.valueCell()
            content.text = NSLocalizedString("Tono", comment: "")
            content.secondaryText = defaults.string(forKey: "defaultTone") ?? Tone.professional.rawValue
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
        case .quickProofread:
            var configuration = UIListContentConfiguration.valueCell()
            configuration.text = NSLocalizedString("Habilitar cuando <= 200 caracteres", comment: "")
            cell.contentConfiguration = configuration
            let toggle = UISwitch()
            toggle.isOn = defaults.bool(forKey: "quickProofreadEnabled")
            toggle.addTarget(self, action: #selector(toggleQuickProofread(_:)), for: .valueChanged)
            cell.accessoryView = toggle
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let preference = Preference(rawValue: indexPath.section) else { return }
        switch preference {
        case .defaultTone:
            presentToneSelection()
        case .quickProofread:
            break
        }
    }

    private func presentToneSelection() {
        let alert = UIAlertController(title: NSLocalizedString("Selecciona un tono", comment: ""), message: nil, preferredStyle: .actionSheet)
        Tone.allCases.forEach { tone in
            alert.addAction(UIAlertAction(title: tone.rawValue.capitalized, style: .default, handler: { [weak self] _ in
                self?.defaults.set(tone.rawValue, forKey: "defaultTone")
                self?.tableView.reloadData()
            }))
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancelar", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    @objc private func toggleQuickProofread(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: "quickProofreadEnabled")
    }
}
