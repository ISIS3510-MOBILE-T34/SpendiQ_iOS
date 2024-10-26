import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: String = "Home"
    @State private var showOffersList: Bool = false
    
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        NavigationView {
            VStack {
                Header(viewModel: UserViewModel(mockData: true))

                switch selectedTab {
                case "Home":
                    HomePage()
                        .onAppear {
                            NotificationManager.shared.requestNotificationPermission()
                            NotificationManager.shared.scheduleTestMessage()
                        }
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
            // Add a hidden NavigationLink for navigation when notification is tapped
            .background(
                NavigationLink(
                    destination: PromosPage(),
                    isActive: $showOffersList,
                    label: {
                        EmptyView()
                    }
                )
                .hidden()
            )
            // Listen for the notification
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowOffersList"))) { _ in
                self.showOffersList = true
            }
        }
    }
}
