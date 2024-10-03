import SwiftUI

struct ContentView: View {
    @State private var selectedTab: String = "Home"
    
    var body: some View {
        VStack {
            
            if selectedTab == "Home" {
                HomePage()
                    .onAppear {
//                        NotificationManager.shared.requestNotificationPermission()
//                        NotificationManager.shared.scheduleTestMessage()
                    }
                    
            } else if selectedTab == "Promos" {
                PromosPage()
            } else if selectedTab == "Accounts" {
                AccountsPage()
            } else if selectedTab == "Profile" {
                ProfilePage()
            }
            
        }
        Spacer()
        TabBar(selectedTab: $selectedTab)
        
    }
}

#Preview {
    ContentView()
}
