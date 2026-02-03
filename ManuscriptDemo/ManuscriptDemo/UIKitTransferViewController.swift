import UIKit

// MARK: - Educational Components

/// A custom container demonstrating the "Search by Label" strategy.
///
/// Hierarchy:
/// View
///  ├── UILabel ("The Label")
///  └── UITextField (No Accessibility ID)
///
/// Manuscript finds the UILabel by text first, then looks for the next UITextField in the hierarchy.
class SearchByLabelContainer: UIView {
    let label: UILabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    let textField: UITextField = {
        let t = UITextField()
        t.borderStyle = .roundedRect
        t.translatesAutoresizingMaskIntoConstraints = false
        // CRITICAL: We intentionally do NOT set accessibilityIdentifier here
        return t
    }()
    
    init(labelText: String, placeholder: String? = nil) {
        super.init(frame: .zero)
        label.text = labelText
        textField.placeholder = placeholder
        setupLayout()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupLayout() {
        addSubview(label)
        addSubview(textField)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

class UIKitTransferViewController: UIViewController {

    // MARK: - UI Elements mapping to Search Strategies

    // 1. Strategy: Accessibility ID
    // We explicitly set `.accessibilityIdentifier`
    private let recipientTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Recipient Name"
        textField.borderStyle = .roundedRect
        textField.accessibilityIdentifier = "transfer_recipient" // <--- The Target
        return textField
    }()

    // 2. Strategy: Label Anchor
    // We use a container where the Label is a sibling preceding the TextField.
    // The TextField has NO ID.
    private let ibanField: SearchByLabelContainer = {
        let field = SearchByLabelContainer(labelText: "Beneficiary IBAN", placeholder: "IBAN")
        return field
    }()

    // 3. Strategy: Placeholder
    // The TextField has NO ID and NO external Label to search for.
    // Manuscript must find it by matching the placeholder text.
    private let amountTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "0.00" // <--- The Target
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        return textField
    }()

    // 4. Strategy: Value Match
    // The TextField is pre-filled. We want to find the field that contains specific text.
    private let referenceTextField: UITextField = {
        let textField = UITextField()
        textField.text = "Invoice Payment" // <--- The Target
        textField.placeholder = "Reference"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    // MARK: - Layout & Logic
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Transfer", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "UIKit Strategies"
        
        setupLayout()
    }

    private func setupLayout() {
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 1. ID
        stackView.addArrangedSubview(createHeader("1. Search by ID"))
        stackView.addArrangedSubview(recipientTextField)
        
        // 2. Label
        stackView.addArrangedSubview(createHeader("2. Search by Label"))
        stackView.addArrangedSubview(ibanField)
        
        // 3. Placeholder
        stackView.addArrangedSubview(createHeader("3. Search by Placeholder"))
        stackView.addArrangedSubview(amountTextField)
        
        // 4. Value
        stackView.addArrangedSubview(createHeader("4. Search by Value"))
        stackView.addArrangedSubview(referenceTextField)
        
        // Button
        stackView.addArrangedSubview(UIView()) // Spacer
        stackView.addArrangedSubview(sendButton)
        sendButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }
    
    private func createHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.textColor = .systemGray
        return l
    }

    @objc private func sendTapped() {
        // Simple validation to confirm interaction
        let alert = UIAlertController(title: "Status", message: "Check logs for inputs", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
