import SwiftUI

/// View for flagging a suspicious session
struct FlagSessionView: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FlagSessionViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                reasonSelection

                notesSection

                Spacer()

                submitButton
            }
            .padding(24)
            .navigationTitle("Flag Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Session Flagged", isPresented: $viewModel.showingSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("Thank you for helping keep races fair. The session will be reviewed if it receives multiple flags.")
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Report Suspicious Session")
                .font(.title3)
                .fontWeight(.bold)

            Text("Help maintain fair competition by flagging sessions that may violate race rules.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var reasonSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reason for Flagging")
                .font(.headline)

            ForEach(FlagReason.allCases, id: \.self) { reason in
                FlagReasonRow(
                    reason: reason,
                    isSelected: viewModel.selectedReason == reason,
                    action: { viewModel.selectedReason = reason }
                )
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Notes (Optional)")
                .font(.headline)

            TextEditor(text: $viewModel.notes)
                .frame(height: 100)
                .padding(8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                await viewModel.submitFlag(sessionId: session.id)
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Submit Flag")
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(viewModel.selectedReason != nil ? Color.orange : Color(.systemGray4))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(viewModel.selectedReason == nil || viewModel.isLoading)
    }
}

struct FlagReasonRow: View {
    let reason: FlagReason
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .orange : .secondary)

                Text(reason.displayName)
                    .font(.subheadline)

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.orange : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ViewModel

final class FlagSessionViewModel: ObservableObject {
    @Published var selectedReason: FlagReason?
    @Published var notes: String = ""
    @Published var isLoading: Bool = false
    @Published var showingSuccess: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String?

    private let moderationService: ModerationServiceProtocol

    init(moderationService: ModerationServiceProtocol = ModerationService.shared) {
        self.moderationService = moderationService
    }

    @MainActor
    func submitFlag(sessionId: String) async {
        guard let reason = selectedReason else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            try await moderationService.flagSession(
                sessionId: sessionId,
                userId: AppState.shared?.currentUser?.id ?? "",
                reason: reason
            )
            showingSuccess = true
        } catch {
            errorMessage = "Failed to submit flag"
            showingError = true
        }
    }
}

#Preview {
    FlagSessionView(session: MockData.sessions[0])
}
