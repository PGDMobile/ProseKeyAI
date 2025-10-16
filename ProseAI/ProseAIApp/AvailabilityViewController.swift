import UIKit
import ProseCore

final class AvailabilityViewController: UIViewController {
    private let statusLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Inicio", comment: "")
        tabBarItem = UITabBarItem(title: NSLocalizedString("Inicio", comment: ""), image: UIImage(systemName: "sparkles"), selectedImage: nil)
        view.backgroundColor = UIColor.systemBackground
        configureStack()
        updateAvailability()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAvailability()
    }

    private func configureStack() {
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center

        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .body)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.text = NSLocalizedString("ProseKeyAI usa Apple Intelligence completamente en el dispositivo. Sigue el tutorial para habilitar el teclado en Ajustes > General > Teclados.", comment: "")

        stackView.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(descriptionLabel)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func updateAvailability() {
        let availability = AppleIntelligenceAvailability.shared.isAvailable
        if availability {
            statusLabel.text = NSLocalizedString("Apple Intelligence disponible", comment: "")
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = NSLocalizedString("Apple Intelligence no disponible", comment: "")
            statusLabel.textColor = .systemRed
        }
    }
}
