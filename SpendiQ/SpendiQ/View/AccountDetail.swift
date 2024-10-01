import SwiftUI

struct AccountDetail: View {
    @State var account: BankAccount // Cuenta seleccionada
    @ObservedObject var viewModel: BankAccountViewModel
    @State private var isEditing = false // Control para editar
    @State private var editedName: String = ""
    @State private var editedBalance: Double = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Account Details")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)

            if isEditing {
                Form {
                    Section(header: Text("Account Name")) {
                        TextField("Enter account name", text: $editedName)
                            .frame(height: 32)
                    }

                    Section(header: Text("Balance")) {
                        TextField("Enter new balance", value: $editedBalance, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            } else {
                Text("Account Name: \(account.name)")
                Text("Balance: $\(account.amount, specifier: "%.2f")")
            }

            Spacer()

            HStack {
                if isEditing {
                    Button(action: {
                        if !editedName.isEmpty {
                            // Actualiza la cuenta en Firebase y en la lista local
                            viewModel.updateAccount(account: account, newName: editedName, newBalance: editedBalance)
                            account.name = editedName
                            account.amount = editedBalance
                            isEditing = false
                        }
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                } else {
                    Button(action: {
                        editedName = account.name
                        editedBalance = account.amount
                        isEditing = true
                    }) {
                        Text("Edit")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .padding()
        .onAppear {
            editedName = account.name
            editedBalance = account.amount
        }
    }
}
