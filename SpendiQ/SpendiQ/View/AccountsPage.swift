import SwiftUI

struct AccountsPage: View {
    @State private var accounts: [AccountData] = [] // Lista de cuentas
    @State private var showAddAccountSheet = false // Control para mostrar el formulario de agregar cuenta
    
    var body: some View {
        VStack {
            // Verificamos si hay cuentas en la lista
            if accounts.isEmpty {
                Text("No accounts available")
                    .padding(.top, 20)
            } else {
                List {
                    ForEach(accounts) { account in
                        HStack {
                            Text(account.name)
                            Spacer()
                            Text("$\(account.initialBalance, specifier: "%.2f")")
                        }
                    }
                }
            }
            
            // Botón para agregar una nueva cuenta
            Button(action: {
                showAddAccountSheet = true
            }) {
                Text("Add New Account")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
            }
            .sheet(isPresented: $showAddAccountSheet) {
                AccountForm { newAccount in
                    // Agregar la nueva cuenta a la lista
                    accounts.append(newAccount)
                }
            }
        }
    }
}

// Modelo de datos para la cuenta
struct AccountData: Identifiable {
    let id = UUID()
    var name: String
    var initialBalance: Double
}

#Preview {
    AccountsPage()
}
