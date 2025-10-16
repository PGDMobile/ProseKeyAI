import UIKit
import ProseCore

final class KeyboardViewController: UIInputViewController {
    private enum State {
        case idle
        case loading(command: Command)
        case preview(original: String, transformed: String)
        case error(String)
    }

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let shadowView = UIView()
    private let stackView = UIStackView()
    private let commandScroll = UIScrollView()
    private let commandStack = UIStackView()
    private let statusContainer = UIStackView()
    private let statusLabel = UILabel()
    private let previewTextView = UITextView()
    private let actionStack = UIStackView()
    private let progressIndicator = UIActivityIndicatorView(style: .medium)
    private let menuButton = UIButton(type: .system)
    private let customCommandsButton = UIButton(type: .system)

    private var state: State = .idle { didSet { updateState() } }
    private var tasks: Set<Task<Void, Never>> = []
    private var commands: [Command] = []
    private var transformService: TransformService?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        loadCommands()
        configureActions()
        Task { await prepareClientIfNeeded() }
        updateState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadCommands()
        configureActions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelOperations()
    }

    private func configureAppearance() {
        view.backgroundColor = .clear
        blurView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.layer.cornerRadius = 24
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 16
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 8)

        blurView.layer.cornerRadius = 24
        blurView.clipsToBounds = true

        view.addSubview(shadowView)
        shadowView.addSubview(blurView)

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(stackView)

        commandScroll.translatesAutoresizingMaskIntoConstraints = false
        commandScroll.showsHorizontalScrollIndicator = false
        commandScroll.heightAnchor.constraint(equalToConstant: 48).isActive = true
        commandStack.axis = .horizontal
        commandStack.spacing = 8
        commandStack.translatesAutoresizingMaskIntoConstraints = false
        commandScroll.addSubview(commandStack)

        statusContainer.axis = .horizontal
        statusContainer.alignment = .center
        statusContainer.spacing = 8
        statusContainer.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .left
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.text = NSLocalizedString("Selecciona una acción", comment: "")
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        previewTextView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.6)
        previewTextView.layer.cornerRadius = 16
        previewTextView.isEditable = false
        previewTextView.isScrollEnabled = true
        previewTextView.font = UIFont.preferredFont(forTextStyle: .body)
        previewTextView.adjustsFontForContentSizeCategory = true
        previewTextView.alpha = 0
        previewTextView.accessibilityLabel = NSLocalizedString("Vista previa del resultado", comment: "")

        actionStack.axis = .horizontal
        actionStack.spacing = 12
        actionStack.distribution = .fillEqually
        actionStack.translatesAutoresizingMaskIntoConstraints = false

        progressIndicator.hidesWhenStopped = true

        menuButton.setTitle(NSLocalizedString("Acciones", comment: ""), for: .normal)
        menuButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        menuButton.titleLabel?.adjustsFontForContentSizeCategory = true
        menuButton.addTarget(self, action: #selector(showMenu), for: .touchUpInside)
        menuButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        customCommandsButton.setTitle(NSLocalizedString("Comandos", comment: ""), for: .normal)
        customCommandsButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        customCommandsButton.titleLabel?.adjustsFontForContentSizeCategory = true
        customCommandsButton.addTarget(self, action: #selector(showCustomCommands), for: .touchUpInside)
        customCommandsButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        stackView.addArrangedSubview(menuButton)
        stackView.addArrangedSubview(commandScroll)
        statusContainer.addArrangedSubview(progressIndicator)
        statusContainer.addArrangedSubview(statusLabel)
        stackView.addArrangedSubview(statusContainer)
        stackView.addArrangedSubview(previewTextView)
        stackView.addArrangedSubview(actionStack)
        stackView.setCustomSpacing(4, after: statusLabel)

        progressIndicator.widthAnchor.constraint(equalToConstant: 20).isActive = true
        actionStack.addArrangedSubview(makeActionButton(title: NSLocalizedString("Reemplazar", comment: ""), selector: #selector(replaceText)))
        actionStack.addArrangedSubview(makeActionButton(title: NSLocalizedString("Copiar", comment: ""), selector: #selector(copyResult)))
        actionStack.addArrangedSubview(makeActionButton(title: NSLocalizedString("Cancelar", comment: ""), selector: #selector(cancelTapped)))

        NSLayoutConstraint.activate([
            shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            shadowView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            shadowView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            shadowView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),

            blurView.leadingAnchor.constraint(equalTo: shadowView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: shadowView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: shadowView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: shadowView.bottomAnchor),

            stackView.leadingAnchor.constraint(equalTo: blurView.contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: blurView.contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: blurView.contentView.layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: blurView.contentView.layoutMarginsGuide.bottomAnchor),

            commandStack.leadingAnchor.constraint(equalTo: commandScroll.contentLayoutGuide.leadingAnchor),
            commandStack.trailingAnchor.constraint(equalTo: commandScroll.contentLayoutGuide.trailingAnchor),
            commandStack.topAnchor.constraint(equalTo: commandScroll.contentLayoutGuide.topAnchor),
            commandStack.bottomAnchor.constraint(equalTo: commandScroll.contentLayoutGuide.bottomAnchor),
            commandStack.heightAnchor.constraint(equalTo: commandScroll.frameLayoutGuide.heightAnchor)
        ])
    }

    private func configureActions() {
        commands = CommandStore.shared.commands()
        commandStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for command in commands {
            let button = ActionButton(command: command)
            button.isEnabled = transformService != nil
            button.addTarget(self, action: #selector(commandButtonTapped(_:)), for: .touchUpInside)
            commandStack.addArrangedSubview(button)
        }
        commandStack.addArrangedSubview(customCommandsButton)
        customCommandsButton.isEnabled = transformService != nil
    }

    private func loadCommands() {
        commands = CommandStore.shared.commands()
    }

    private func prepareClientIfNeeded() async {
        guard transformService == nil else { return }
        do {
            let client = try AppleIntelligenceClient()
            transformService = TransformService(client: client)
            await MainActor.run {
                statusLabel.text = NSLocalizedString("Listo", comment: "")
                self.updateButtonsEnabled(true)
            }
        } catch {
            await MainActor.run {
                statusLabel.text = error.localizedDescription
                self.updateButtonsEnabled(false)
            }
        }
    }

    @objc private func commandButtonTapped(_ sender: ActionButton) {
        guard case .idle = state else { return }
        perform(command: sender.command)
    }

    private func perform(command: Command) {
        guard let proxyText = currentText() else {
            statusLabel.text = NSLocalizedString("No hay texto para transformar", comment: "")
            return
        }
        guard let transformService else {
            statusLabel.text = NSLocalizedString("Apple Intelligence no disponible", comment: "")
            return
        }

        state = .loading(command: command)
        progressIndicator.startAnimating()
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await transformService.transform(text: proxyText, using: command, tonePreference: preferredTone())
                await MainActor.run {
                    UIPasteboardBridge.shared.string = result
                    self.state = .preview(original: proxyText, transformed: result)
                    self.statusLabel.text = NSLocalizedString("Listo", comment: "")
                }
            } catch {
                await MainActor.run {
                    if let error = error as? ProseAIError {
                        self.state = .error(error.localizedDescription)
                    } else {
                        self.state = .error(error.localizedDescription)
                    }
                }
            }
        }
        tasks.insert(task)
    }

    private func preferredTone() -> Tone? {
        let stored = UserDefaults(suiteName: "group.com.yourcompany.proseai")?.string(forKey: "defaultTone")
        if let stored, let tone = Tone(rawValue: stored) {
            return tone
        }
        return nil
    }

    private func updateState() {
        UIView.animate(withDuration: 0.18) {
            switch self.state {
            case .idle:
                self.previewTextView.alpha = 0
                self.progressIndicator.stopAnimating()
            case .loading(let command):
                self.statusLabel.text = String(format: NSLocalizedString("Procesando %@…", comment: ""), command.name)
                self.progressIndicator.startAnimating()
                self.previewTextView.alpha = 0
            case .preview(let original, let transformed):
                self.progressIndicator.stopAnimating()
                self.previewTextView.attributedText = self.diffAttributedString(original: original, transformed: transformed)
                self.previewTextView.alpha = 1
            case .error(let message):
                self.progressIndicator.stopAnimating()
                self.previewTextView.text = message
                self.previewTextView.alpha = 1
            }
        }
    }

    private func diffAttributedString(original: String, transformed: String) -> NSAttributedString {
        let attributed = NSMutableAttributedString()
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .headline)
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.preferredFont(forTextStyle: .body)
        ]
        attributed.append(NSAttributedString(string: NSLocalizedString("Original\n", comment: ""), attributes: titleAttributes))
        attributed.append(NSAttributedString(string: original + "\n\n", attributes: bodyAttributes))
        attributed.append(NSAttributedString(string: NSLocalizedString("Transformado\n", comment: ""), attributes: titleAttributes))
        attributed.append(NSAttributedString(string: transformed, attributes: bodyAttributes))
        return attributed
    }

    private func currentText() -> String? {
        let selection = textDocumentProxy.selectedText ?? ""
        if !selection.isEmpty {
            return selection
        }
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let combined = before + after
        if combined.isEmpty {
            return UIPasteboardBridge.shared.string
        }
        let quick = UserDefaults(suiteName: "group.com.yourcompany.proseai")?.bool(forKey: "quickProofreadEnabled") ?? true
        if quick && combined.count <= 200 {
            statusLabel.text = NSLocalizedString("Corrección rápida disponible", comment: "")
        }
        return combined
    }

    @objc private func replaceText() {
        guard case .preview(_, let transformed) = state else { return }
        if let selection = textDocumentProxy.selectedText, !selection.isEmpty {
            // Remove the highlighted range before inserting so we stay in sync with the host document proxy.
            for _ in 0..<selection.count {
                textDocumentProxy.deleteBackward()
            }
            textDocumentProxy.insertText(transformed)
            state = .idle
        } else {
            textDocumentProxy.insertText(transformed)
            state = .idle
            statusLabel.text = NSLocalizedString("Insertado al cursor (selecciona texto para reemplazar)", comment: "")
        }
    }

    @objc private func copyResult() {
        guard case .preview(_, let transformed) = state else { return }
        UIPasteboardBridge.shared.string = transformed
        statusLabel.text = NSLocalizedString("Copiado", comment: "")
    }

    @objc private func cancelTapped() {
        cancelOperations()
        state = .idle
    }

    private func cancelOperations() {
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
    }

    private func updateButtonsEnabled(_ enabled: Bool) {
        for case let button as UIButton in commandStack.arrangedSubviews {
            button.isEnabled = enabled
        }
        customCommandsButton.isEnabled = enabled
    }

    @objc private func showMenu() {
        let controller = UIAlertController(title: NSLocalizedString("Acciones", comment: ""), message: nil, preferredStyle: .actionSheet)
        for command in commands {
            controller.addAction(UIAlertAction(title: command.name, style: .default, handler: { [weak self] _ in
                self?.perform(command: command)
            }))
        }
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancelar", comment: ""), style: .cancel))
        present(controller, animated: true)
    }

    @objc private func showCustomCommands() {
        let items = commands.filter { $0.isUserGenerated }
        let controller = UIAlertController(title: NSLocalizedString("Comandos personalizados", comment: ""), message: nil, preferredStyle: .actionSheet)
        for command in items {
            controller.addAction(UIAlertAction(title: command.name, style: .default, handler: { [weak self] _ in
                self?.perform(command: command)
            }))
        }
        controller.addAction(UIAlertAction(title: NSLocalizedString("Cancelar", comment: ""), style: .cancel))
        present(controller, animated: true)
    }

    private func makeActionButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.layer.cornerRadius = 12
        button.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.accessibilityLabel = title
        return button
    }
}

private final class ActionButton: UIButton {
    let command: Command

    init(command: Command) {
        self.command = command
        super.init(frame: .zero)
        setTitle(command.name, for: .normal)
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .callout)
        titleLabel?.adjustsFontForContentSizeCategory = true
        backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.cgColor
        heightAnchor.constraint(equalToConstant: 44).isActive = true
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        accessibilityLabel = command.name
        accessibilityHint = NSLocalizedString("Ejecuta la acción de escritura", comment: "")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
