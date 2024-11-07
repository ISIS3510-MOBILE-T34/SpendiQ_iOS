import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: String = "Home"
    @State private var showOffersList: Bool = false

    // Only instantiate LocationManager once for PromosPage
    @StateObject private var locationManager = LocationManager()
    @StateObject private var userViewModel = UserViewModel() // Initialize without mockData for production

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Conditionally display the Header
                if selectedTab != "Profile" {
                    Header(viewModel: userViewModel, selectedTab: $selectedTab)
                }

                // Switch between different tabs/pages
                switch selectedTab {
                case "Home":
                    HomePage()
                        .onAppear {
                            NotificationManager.shared.requestNotificationPermission()
                        }
                case "Promos":
                    PromosPage(locationManager: locationManager) // Pass directly to PromosPage
                case "Accounts":
                    AccountsPage()
                case "Profile":
                    ProfilePage(selectedTab: $selectedTab)
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
            // Listen for the "ShowOffersList" notification to navigate to PromosPage
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowOffersList"))) { _ in
                self.showOffersList = true
            }
        }
        .environmentObject(userViewModel)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
            .environmentObject(UserViewModel(mockData: true))
    }
}
