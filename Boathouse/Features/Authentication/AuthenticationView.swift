import SwiftUI

/// Main authentication view with login/register options
struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedUserType: User.UserType = .spectator

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    headerSection

                    authModeToggle

                    formSection

                    if authViewModel.authMode == .register {
                        userTypeSelector
                    }

                    if let error = authViewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    actionButton

                    Spacer(minLength: 32)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .disabled(authViewModel.isLoading)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.rowing")
                .font(.system(size: 64))
                .foregroundStyle(.accent)
                .padding(.top, 32)

            Text("Boathouse")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Digital Canoe & Kayak Racing")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var authModeToggle: some View {
        Picker("Auth Mode", selection: $authViewModel.authMode) {
            Text("Login").tag(AuthViewModel.AuthMode.login)
            Text("Register").tag(AuthViewModel.AuthMode.register)
        }
        .pickerStyle(.segmented)
        .onChange(of: authViewModel.authMode) { _, _ in
            authViewModel.clearForm()
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            TextField("Email", text: $authViewModel.email)
                .textFieldStyle(BoathouseTextFieldStyle())
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Password", text: $authViewModel.password)
                .textFieldStyle(BoathouseTextFieldStyle())
                .textContentType(authViewModel.authMode == .login ? .password : .newPassword)

            if authViewModel.authMode == .register {
                SecureField("Confirm Password", text: $authViewModel.confirmPassword)
                    .textFieldStyle(BoathouseTextFieldStyle())
                    .textContentType(.newPassword)
            }
        }
    }

    private var userTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Account Type")
                .font(.headline)

            VStack(spacing: 12) {
                UserTypeCard(
                    type: .spectator,
                    isSelected: selectedUserType == .spectator,
                    action: { selectedUserType = .spectator }
                )

                UserTypeCard(
                    type: .racer,
                    isSelected: selectedUserType == .racer,
                    action: { selectedUserType = .racer }
                )
            }
        }
    }

    private var actionButton: some View {
        Button {
            Task {
                if authViewModel.authMode == .login {
                    await authViewModel.login()
                } else {
                    await authViewModel.register(as: selectedUserType)
                }
            }
        } label: {
            Group {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(authViewModel.authMode == .login ? "Login" : "Create Account")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!authViewModel.isFormValid || authViewModel.isLoading)
    }
}

struct UserTypeCard: View {
    let type: User.UserType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: type == .spectator ? "eye.fill" : "figure.rowing")
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(type == .spectator ? "Spectator" : "Racer")
                        .font(.headline)

                    Text(type == .spectator
                         ? "View races and leaderboards"
                         : "Enter races and win prizes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.red)

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
}
