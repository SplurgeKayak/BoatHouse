import SwiftUI

/// Custom text field style for the app
struct BoathouseTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Secure field with visibility toggle
struct SecureInputField: View {
    let placeholder: String
    @Binding var text: String
    @State private var isSecured = true

    var body: some View {
        HStack {
            Group {
                if isSecured {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textContentType(.password)

            Button {
                isSecured.toggle()
            } label: {
                Image(systemName: isSecured ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
        .textFieldStyle(BoathouseTextFieldStyle())
    }
}
