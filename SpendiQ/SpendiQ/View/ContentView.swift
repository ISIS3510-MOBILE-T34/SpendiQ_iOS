import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: String = "Home"
    
    var body: some View {
        NavigationView {
            VStack {
                Header(viewModel: UserViewModel(mockData: true))
                
                switch selectedTab {
                case "Home":
                    HomePage()
                case "Promos":
                    PromosPage()
                case "Accounts":
                    AccountsPage()
                case "Profile":
                    ProfilePage()
                default:
                    EmptyView()
                }
                
                Spacer()
                
                TabBar(selectedTab: $selectedTab)
            }
            .navigationBarItems(trailing: Button("Log Out") {
                do {
                    try Auth.auth().signOut()
                    appState.isAuthenticated = false
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            })
        }
    }
}
