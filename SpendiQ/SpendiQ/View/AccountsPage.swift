import SwiftUI

struct AccountsPage: View {
    @StateObject private var viewModel = BankAccountViewModel() // ViewModel para la lista de cuentas
    @State private var showAddAccountSheet = false // Control para mostrar el formulario de agregar cuenta
    @State private var showDeleteConfirmation = false // Control para confirmar eliminación
    @State private var selectedAccountID: String? // Cuenta seleccionada para eliminar
    @State private var selectedAccount: BankAccount? // Cuenta seleccionada para ver detalles

    var body: some View {
        VStack {
            if viewModel.accounts.isEmpty {
                Text("No accounts available")
                    .padding(.top, 20)
            } else {
                List {
                    ForEach(viewModel.accounts, id: \.id) { account in
                        HStack {
                            Text(account.name)
                            Spacer()
                            Text("$\(account.amount, specifier: "%.2f")")
                        }
                        .contentShape(Rectangle()) // Hace que toda la celda sea seleccionable
                        .onTapGesture {
                            selectedAccount = account // Almacena la cuenta seleccionada
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                selectedAccountID = account.id // Almacena el documentID de la cuenta para eliminar
                                showDeleteConfirmation = true // Muestra la alerta de confirmación
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
                AccountForm(viewModel: viewModel) // Formulario para agregar una nueva cuenta
            }
        }
        // Recargar las cuentas cada vez que la vista aparezca
        .onAppear {
            viewModel.getBankAccounts() // Llama al método que recupera las cuentas desde Firebase
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete this account?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let accountID = selectedAccountID {
                        viewModel.deleteAccount(accountID: accountID) // Usa el documentID para eliminar
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(item: $selectedAccount) { account in
            AccountDetail(account: account, viewModel: viewModel) // Navega a la página de detalle
        }
    }
}
