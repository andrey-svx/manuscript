import SwiftUI

// MARK: - Educational Components

/// A custom SwiftUI view demonstrating the "Search by Label" strategy.
///
/// Hierarchy:
/// VStack
///  ├── Text ("The Label")  <-- 1. Scanner finds this Anchor
///  └── TextField           <-- 2. Scanner returns the next TextField in hierarchy
///
/// This mimics the UIKit layout where a UILabel precedes a UITextField.
/// Manuscript finds the Text element first, sets a "foundLabel" flag,
/// and then grabs the very next TextField it encounters.
struct SearchByLabelView: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                // CRITICAL: We intentionally do NOT set accessibilityIdentifier here.
                // The tool must rely solely on the sibling Text label above.
        }
    }
}

struct SwiftUITransferView: View {
    @State private var recipient: String = ""
    @State private var iban: String = ""
    @State private var amount: String = ""
    @State private var reference: String = "Invoice Payment"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    // MARK: 1. Strategy: Accessibility ID
                    // The most robust method. We attach an explicit ID to the view.
                    // Manuscript searches for `transfer_recipient`.
                    VStack(alignment: .leading) {
                        Header("1. Search by ID")
                        TextField("Recipient Name", text: $recipient)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .accessibilityIdentifier("transfer_recipient") // <--- The Target
                    }

                    // MARK: 2. Strategy: Label Anchor
                    // Uses a container View that places a Text label immediately before the TextField.
                    // Manuscript searches for "Beneficiary IBAN".
                    VStack(alignment: .leading) {
                        Header("2. Search by Label")
                        SearchByLabelView(label: "Beneficiary IBAN", placeholder: "IBAN", text: $iban)
                    }

                    // MARK: 3. Strategy: Placeholder
                    // No ID, no external Label. Manuscript searches the placeholder attribute directly.
                    // Manuscript searches for "0.00".
                    VStack(alignment: .leading) {
                        Header("3. Search by Placeholder")
                        TextField("0.00", text: $amount) // <--- The Target
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            // No ID. No external Label.
                    }

                    // MARK: 4. Strategy: Value Match
                    // Pre-filled field. Manuscript searches for a field containing specific text value.
                    // Manuscript searches for "Invoice Payment".
                    VStack(alignment: .leading) {
                        Header("4. Search by Value")
                        TextField("Reference", text: $reference) // <--- The Target (Pre-filled)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            // No ID. No external Label.
                    }

                    Button(action: {}) {
                        Text("Send Transfer")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("SwiftUI Strategies")
        }
    }
    
    private func Header(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.gray)
    }
}
