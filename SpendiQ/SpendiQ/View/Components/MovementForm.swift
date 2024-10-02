import SwiftUI

struct MovementForm: View {
    @ObservedObject var bankAccountViewModel: BankAccountViewModel  // Se inyecta el ViewModel
    
    var body: some View {
        EditTransactionForm(bankAccountViewModel: bankAccountViewModel)
    }
}

struct EditTransactionForm: View {
    @Environment(\.dismiss) var dismiss
    @State private var transactionType: String = "Expense"
    @State private var transactionName: String = ""
    @State private var amount: Float = 0.0
    @State private var selectedAccountID: String = ""
    @State private var selectedTargetAccountID: String = ""
    @State private var selectedEmoji: String = ""
    @State private var selectedDateTime: Date = Date()
    @FocusState private var isEmojiFieldFocused: Bool
    @ObservedObject var bankAccountViewModel: BankAccountViewModel
    @ObservedObject var transactionViewModel = TransactionViewModel()  // Inyectar el TransactionViewModel

    let transactionTypes = ["Expense", "Income", "Transaction"]
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Transaction")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
            
            Picker("Select Type", selection: $transactionType) {
                ForEach(transactionTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 20)
            
            VStack {
                ZStack(alignment: .center) {
                    Circle()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.primarySpendiq)
                    Text(selectedEmoji.isEmpty ? "🙂" : selectedEmoji)
                        .font(.system(size: 58))
                }
                
                Button("Change icon") {
                    isEmojiFieldFocused = true
                }
                .foregroundColor(.blue)
            }
            
            Form {
                Section(header: Text("Transaction name")) {
                    TextField("Transaction name", text: $transactionName)
                        .frame(height: 32)
                }
                
                Section(header: Text("Amount")) {
                    TextField("Amount", value: $amount, format: .number)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { oldValue, newValue in
                            if newValue < 0 {
                                amount = 0.0
                            }
                        }
                }
                
                Section(header: Text("Select Account")) {
                    Picker("Account", selection: $selectedAccountID) {
                        ForEach(bankAccountViewModel.accounts) { account in
                            Text(account.name).tag(account.id ?? "")
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onAppear {
                        bankAccountViewModel.getBankAccounts()
                    }
                    .onChange(of: bankAccountViewModel.accounts) { _, newAccounts in
                        if !newAccounts.isEmpty, selectedAccountID.isEmpty {
                            selectedAccountID = newAccounts.first?.id ?? ""
                        }
                    }
                }
                
                if transactionType == "Transaction" {
                    Section(header: Text("Target Account")) {
                        Picker("Target Account", selection: $selectedTargetAccountID) {
                            ForEach(bankAccountViewModel.accounts) { account in
                                Text(account.name).tag(account.id ?? "")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: bankAccountViewModel.accounts) { _, newAccounts in
                            if !newAccounts.isEmpty, selectedTargetAccountID.isEmpty {
                                selectedTargetAccountID = newAccounts.first?.id ?? ""
                            }
                        }
                    }
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Select Date", selection: $selectedDateTime, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                
                Section(header: Text("Time")) {
                    DatePicker("Select Time", selection: $selectedDateTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(CompactDatePickerStyle())
                }
            }
            .background(Color.clear)
            
            HStack {
                Button(action: {
                    // Guardar la transacción en la base de datos
                    transactionViewModel.addTransaction(
                        accountID: selectedAccountID, transactionName: transactionName,
                        amount: amount,
                        fromAccountID: selectedAccountID,
                        toAccountID: transactionType == "Transaction" ? selectedTargetAccountID : nil,
                        transactionType: transactionType,
                        dateTime: selectedDateTime
                    )
                    dismiss()
                }) {
                    Text("Accept")
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
        .onTapGesture {
            bankAccountViewModel.getBankAccounts()
        }
    }
}

#Preview {
    MovementForm(bankAccountViewModel: BankAccountViewModel())
}
