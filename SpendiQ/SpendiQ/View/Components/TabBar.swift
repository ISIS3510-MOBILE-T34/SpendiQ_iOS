import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: String
    @State private var showNewOptions = false // Controla si se muestran los botones desplegables
    
    var body: some View {
        ZStack {
            // Fondo opaco cuando los botones están desplegados
            if showNewOptions {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .frame(height: 560)
                    .onTapGesture {
                        withAnimation {
                            showNewOptions = false
                        }
                    }
            }

            VStack {
                Spacer()
                
                HStack(spacing: 35) {
                    Icon(IconName: "house", IconText: "Home", isSelected: selectedTab == "Home")
                        .onTapGesture {
                            selectedTab = "Home"
                        }
                    
                    Icon(IconName: "gift", IconText: "Promos", isSelected: selectedTab == "Promos")
                        .onTapGesture {
                            selectedTab = "Promos"
                        }

                    // Botón "New" que despliega las opciones hacia arriba
                    ZStack {
                        Icon(IconName: "plus.circle.fill", IconText: "New", isSelected: selectedTab == "New", isSpecial: true)
                            .onTapGesture {
                                withAnimation {
                                    showNewOptions.toggle()
                                }
                            }
                        
                        // Botones desplegables hacia arriba
                        if showNewOptions {
                            VStack(spacing: 12) {
                                Button(action: {
                                    // Acción para "Expense"
                                }) {
                                    Text("Expense")
                                        .padding()
                                        .frame(width: 140)
                                        .background(Color.primarySpendiq)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    // Acción para "Income"
                                }) {
                                    Text("Income")
                                        .padding()
                                        .frame(width: 140)
                                        .background(Color.primarySpendiq)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }

                                Button(action: {
                                    // Acción para "Transaction"
                                }) {
                                    Text("Transaction")
                                        .padding()
                                        .frame(width: 140)
                                        .background(Color.primarySpendiq)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                            .transition(.move(edge: .bottom))
                            .offset(y: -300) // Desplaza los botones hacia arriba
                        }
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
