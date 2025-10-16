import UIKit

final class PrivacyViewController: UIViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Privacidad", comment: "")
        tabBarItem = UITabBarItem(title: NSLocalizedString("Privacidad", comment: ""), image: UIImage(systemName: "lock.shield"), selectedImage: nil)
        view.backgroundColor = .systemBackground
        configureTextView()
    }

    private func configureTextView() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.adjustsFontForContentSizeCategory = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.text = NSLocalizedString("ProseKeyAI procesa todo el contenido en el dispositivo usando Apple Intelligence. No recopilamos texto, métricas ni registros. Los comandos personalizados se almacenan en tu App Group y se sincronizan únicamente entre la app y el teclado.", comment: "")
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
