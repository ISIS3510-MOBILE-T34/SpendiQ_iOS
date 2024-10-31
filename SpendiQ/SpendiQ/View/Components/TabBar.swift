import SwiftUI

struct TabBar: View {
    private let locationManager = LocationManager()
    //@Binding permite a esta clase modificar una variable declarada en otra vista
    @Binding var selectedTab: String
    @State private var showSheet = false
    
    var body: some View {
        ZStack {
            Color(.tabBar)
                .ignoresSafeArea(edges: .bottom)
            
            HStack(spacing: 35) {
                Icon(IconName: "house", IconText: "Home", isSelected: selectedTab == "Home")
                    .onTapGesture {
                        selectedTab = "Home"
                    }
                
                Icon(IconName: "gift", IconText: "Promos", isSelected: selectedTab == "Promos")
                    .onTapGesture {
                        selectedTab = "Promos"
                    }
                
                
                Icon(IconName: "plus.circle.fill", IconText: "New", isSelected: selectedTab == "New", isSpecial: true)
                    .onTapGesture {
                        showSheet.toggle()
                    }
                //.sheet depsliega una vista modal
                    .sheet(isPresented: $showSheet) {
                        EditTransactionForm(
                            locationManager: locationManager,
                            bankAccountViewModel: BankAccountViewModel(), transactionViewModel: TransactionViewModel(),
                            transaction: nil)
                            .presentationDetents([.large])
                            .presentationDragIndicator(.visible)
                    }
                
                
                Icon(IconName: "creditcard", IconText: "Accounts", isSelected: selectedTab == "Accounts")
                    .onTapGesture {
                        selectedTab = "Accounts"
                    }
                
                Icon(IconName: "person", IconText: "Profile", isSelected: selectedTab == "Profile")
                    .onTapGesture {
                        selectedTab = "Profile"
                    }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 56)
    }
}

struct Icon: View {
    let IconName: String
    let IconText: String
    let isSelected: Bool
    var isSpecial: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(.primarySpendiq)
                        .frame(width: 50, height: 50)
                        .offset(y: -15)
                }
                
                if isSpecial {
                    Circle()
                        .fill(.primarySpendiq)
                        .frame(width: 60, height: 60)
                        .offset(y: -15)
                    
                    Image(systemName: IconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .offset(y: -15)
                }
                
                Image(systemName: IconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(isSelected || isSpecial ? .white : .black)
                    .offset(y: isSelected || isSpecial ? -15 : 0)
            }
            .frame(minWidth: 44, minHeight: 44)
            
            Text(IconText)
                .font(.custom("SF Pro", size: 14).weight(.medium))
                .foregroundColor(isSelected ? Color.primarySpendiq : Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

#Preview {
    //.constant es util cuando la vista espera una variable @Binding pero no hay necesidad de que esta cambie en el tiempo
    TabBar(selectedTab: .constant("Home"))
}
