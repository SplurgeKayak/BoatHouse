import SwiftUI

/// Main tab bar navigation following Instagram-style layout
struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(AppState.Tab.home.title, systemImage: AppState.Tab.home.icon)
                }
                .tag(AppState.Tab.home)

            RacesView()
                .tabItem {
                    Label(AppState.Tab.races.title, systemImage: AppState.Tab.races.icon)
                }
                .tag(AppState.Tab.races)

            EntryView()
                .tabItem {
                    Label(AppState.Tab.entry.title, systemImage: AppState.Tab.entry.icon)
                }
                .tag(AppState.Tab.entry)

            AccountView()
                .tabItem {
                    Label(AppState.Tab.account.title, systemImage: AppState.Tab.account.icon)
                }
                .tag(AppState.Tab.account)
        }
        .tint(.accentColor)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
