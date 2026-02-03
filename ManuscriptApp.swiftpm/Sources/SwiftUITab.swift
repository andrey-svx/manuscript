import SwiftUI

struct FormField: View {
    let label: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isSecure {
                SecureField("Enter \(label)", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                TextField("Enter \(label)", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(5)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SwiftUIFormView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var query = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SwiftUI Complex Tab")
                .font(.title)
                .bold()
            
            // Complex Container 1
            FormField(label: "Username", text: $username)
                .accessibilityIdentifier("swiftui_username")
            
            // Complex Container 2
            FormField(label: "Password", text: $password, isSecure: true)
                .accessibilityIdentifier("swiftui_password")
            
            // Complex Container 3
            FormField(label: "Email", text: $email)
                .accessibilityIdentifier("swiftui_email")
            
            // Search Field (NO ID)
            TextField("Search SwiftUI...", text: $query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                // No accessibilityIdentifier!
            
            Spacer()
        }
        .padding()
    }
}

class SwiftUIHostViewController: UIHostingController<SwiftUIFormView> {
    init() {
        super.init(rootView: SwiftUIFormView())
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
