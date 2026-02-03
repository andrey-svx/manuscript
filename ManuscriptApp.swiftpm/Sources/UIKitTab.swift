import UIKit

// MARK: - Components

class BorderedTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        borderStyle = .line
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.cornerRadius = 8
    }
}

class LabeledInputView: UIView {
    private let label = UILabel()
    private let textField = UITextField()
    
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }
    
    var isSecureTextEntry: Bool {
        get { textField.isSecureTextEntry }
        set { textField.isSecureTextEntry = newValue }
    }
    
    var keyboardType: UIKeyboardType {
        get { textField.keyboardType }
        set { textField.keyboardType = newValue }
    }
    
    init(title: String) {
        super.init(frame: .zero)
        setup(title: title)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(title: String) {
        self.isAccessibilityElement = false 
        
        label.text = title
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        
        textField.borderStyle = .roundedRect
        
        let stack = UIStackView(arrangedSubviews: [label, textField])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - View Controller

class UIKitViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -40)
        ])
        
        // Title
        let label = UILabel()
        label.text = "UIKit Complex Tab"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        stack.addArrangedSubview(label)
        
        // Field 1: Subclass
        let tf1 = BorderedTextField()
        tf1.placeholder = "Username (Subclass)"
        tf1.accessibilityIdentifier = "uikit_username"
        stack.addArrangedSubview(tf1)
        
        // Field 2: Container
        let tf2 = LabeledInputView(title: "Password (Container)")
        tf2.placeholder = "Enter Password"
        tf2.isSecureTextEntry = true
        tf2.accessibilityIdentifier = "uikit_password"
        // Transparent container
        stack.addArrangedSubview(tf2)
        
        // Field 3: Container
        let tf3 = LabeledInputView(title: "Email (Container)")
        tf3.placeholder = "Email Address"
        tf3.keyboardType = .emailAddress
        tf3.accessibilityIdentifier = "uikit_email"
        // Transparent container
        stack.addArrangedSubview(tf3)
        
        // Field 4: Search (NO ID, PURE VISUAL)
        let tf4 = UITextField()
        tf4.borderStyle = .roundedRect
        tf4.placeholder = "Search anything..."
        // No ID assigned!
        stack.addArrangedSubview(tf4)
    }
}
