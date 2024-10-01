import SwiftUI

struct AccountsPage: View {
    @StateObject private var viewModel = BankAccountViewModel() // ViewModel para la lista de cuentas
    @State private var showAddAccountSheet = false // Control para mostrar el formulario de agregar cuenta
    
    var body: some View {
        VStack {
            if viewModel.accounts.isEmpty {
                Text("No accounts available")
                    .padding(.top, 20)
            } else {
                List {
                    ForEach(viewModel.accounts, id: \.name) { account in
                        HStack {
                            Text(account.name)
                            Spacer()
                            Text("$\(account.amount, specifier: "%.2f")")
                        }
                    }
                }
            }
            
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
                AccountForm(viewModel: viewModel)
            }
        }
        // Recargar las cuentas cada vez que la vista aparezca
        .onAppear {
            viewModel.getBankAccounts() // Llama al método que recupera las cuentas desde Firebase
        }
    }
}
