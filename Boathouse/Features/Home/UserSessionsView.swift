import SwiftUI

// MARK: - User Sessions View

struct UserSessionsView: View {
    let userId: String
    let userName: String
    @StateObject private var viewModel = UserSessionsViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSession: Session? = nil

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.water.fitness")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Sessions")
                            .font(.headline)
                        Text("\(userName) hasn't recorded any sessions yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.sessions) { session in
                        SessionRow(
                            session: session,
                            userName: userName,
                            userAvatarURL: nil
                        ) {
                            selectedSession = session
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(userName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailSheet(
                    session: session,
                    userName: userName,
                    userAvatarURL: nil
                )
                .environmentObject(appState)
            }
        }
        .task {
            await viewModel.load(userId: userId)
        }
    }
}

// MARK: - User Sessions ViewModel

@MainActor
final class UserSessionsViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var isLoading: Bool = false

    private let sessionService: SessionServiceProtocol

    init(sessionService: SessionServiceProtocol = SessionService.shared) {
        self.sessionService = sessionService
    }

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await sessionService.fetchUserSessions(userId: userId, page: 1)
            sessions = fetched.sorted { $0.startDate > $1.startDate }
        } catch {
            sessions = []
        }
    }
}
