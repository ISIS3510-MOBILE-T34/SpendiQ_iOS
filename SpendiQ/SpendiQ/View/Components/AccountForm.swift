import SwiftUI

struct AccountForm: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: BankAccountViewModel // Inyectamos el ViewModel
    @State private var accountName: String = ""
    @State private var initialBalance: Double? = nil
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("New Account")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Form {
                Section(header: Text("Account Name")) {
                    TextField("Enter account name", text: $accountName)
                        .frame(height: 32)
                }
                
                Section(header: Text("Initial Balance")) {
                    TextField("Enter initial balance", value: $initialBalance, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .background(Color.clear)
            
            HStack {
                Button(action: {
                    if let balance = initialBalance, !accountName.isEmpty {
                        viewModel.addAccount(name: accountName, amount: balance)
                        dismiss() // Cerrar el modal
                    }
                }) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .frame(maxHeight: .infinity)
    }
}
