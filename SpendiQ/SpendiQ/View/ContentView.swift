import SwiftUI

struct ContentView: View {
    //@State actualiza la vista cada vez que selectedTab cambia
    @State private var selectedTab: String = "Home"
    
    var body: some View {
        VStack {
            
            if selectedTab == "Home" {
                HomePage()
            } else if selectedTab == "Promos" {
                PromosPage()
            } else if selectedTab == "Accounts" {
                AccountsPage()
            }else if selectedTab == "Profile" {
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
