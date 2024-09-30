import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: String
    @State private var showSheet = false // Controla si se muestra la Bottom Sheet

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

                // Aquí es donde el botón "New" activa la Bottom Sheet con el formulario directamente
                Icon(IconName: "plus.circle.fill", IconText: "New", isSelected: selectedTab == "New", isSpecial: true)
                    .onTapGesture {
                        showSheet.toggle() // Activa la presentación de la Bottom Sheet
                    }
                    .sheet(isPresented: $showSheet) {
                        EditTransactionForm() // Muestra el formulario directamente
                            .presentationDetents([.large]) // Controla las alturas del modal
                            .presentationDragIndicator(.visible) // Barra de "drag"
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
                        .foregroundColor(isSelected || isSpecial ? .white : .black)
                        .offset(y: isSelected || isSpecial ? -15 : 0)
                        .accessibilityLabel("\(IconText) Icon")
                }
                
                Image(systemName: IconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSelected || isSpecial ? .white : .black)
                    .offset(y: isSelected || isSpecial ? -15 : 0)
                    .accessibilityLabel("\(IconText) Icon")
            }
            .frame(minWidth: 44, minHeight: 44)

            Text(IconText)
                .font(.custom("SF Pro", size: 12).weight(.medium))
                .foregroundColor(isSelected ? Color.primarySpendiq : Color.black)
                .accessibilityLabel(IconText)
                .accessibilityHint(isSelected ? "Currently selected" : "Tap to select \(IconText)")
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.top, isSelected || isSpecial ? -5 : 0)
    }
}

#Preview {
    TabBar(selectedTab: .constant("Home"))
}
