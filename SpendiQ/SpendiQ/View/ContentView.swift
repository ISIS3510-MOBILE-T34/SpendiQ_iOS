import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: String = "Home"
    @State private var showOffersList: Bool = false

    // Initialize LocationManager and UserViewModel once and share them across the app
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
                    // Pass the shared LocationManager to PromosPage
                    PromosPage(locationManager: locationManager)
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
            // Hidden NavigationLink for navigation when notification is tapped
            .background(
                NavigationLink(
                    destination: PromosPage(locationManager: locationManager),
                    isActive: $showOffersList,
                    label: {
                        EmptyView()
                    }
                )
                .hidden()
            )
            // Listen for the "ShowOffersList" notification to navigate to PromosPage
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowOffersList"))) { _ in
                self.showOffersList = true
            }
        }
        .environmentObject(locationManager) // <-- Inject LocationManager here
        .environmentObject(userViewModel)   // Existing injection
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
            .environmentObject(UserViewModel(mockData: true))
            .environmentObject(LocationManager()) // Add for preview
    }
}
