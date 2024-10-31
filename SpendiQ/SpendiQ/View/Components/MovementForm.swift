// MovementForm.swift

import SwiftUI

struct MovementForm: View {
    @ObservedObject var bankAccountViewModel: BankAccountViewModel

    var body: some View {
        EditTransactionForm(
            bankAccountViewModel: bankAccountViewModel,
            transactionViewModel: TransactionViewModel(),
            transaction: nil
        )
    }
}

// EditTransactionForm.swift


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
    @ObservedObject var transactionViewModel: TransactionViewModel
    var transaction: Transaction?
    
    let transactionTypes = ["Expense", "Income", "Transaction"]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20) {
                Text(transaction != nil ? "Edit Transaction" : "New Transaction")
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
                .onChange(of: transactionType) { _, newValue in
                    selectedEmoji = selectEmoji(for: newValue)
                }
                
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
                        if let transaction = transaction {
                            transactionViewModel.updateTransaction(
                                transaction: transaction,
                                transactionName: transactionName,
                                amount: amount,
                                fromAccountID: selectedAccountID,
                                toAccountID: transactionType == "Transaction" ? selectedTargetAccountID : nil,
                                transactionType: transactionType,
                                dateTime: selectedDateTime
                            )
                        } else {
                            transactionViewModel.addTransaction(
                                accountID: selectedAccountID,
                                transactionName: transactionName,
                                amount: amount,
                                fromAccountID: selectedAccountID,
                                toAccountID: transactionType == "Transaction" ? selectedTargetAccountID : nil,
                                transactionType: transactionType,
                                dateTime: selectedDateTime
                            )
                        }
                        dismiss()
                    }) {
                        Text(transaction != nil ? "Save" : "Accept")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    if transaction != nil {
                        Button(action: {
                            transactionViewModel.deleteTransaction(
                                accountID: selectedAccountID,
                                transactionID: transaction!.id!
                            )
                            dismiss()
                        }) {
                            Text("Delete")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
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
            .navigationBarHidden(true)
            .onAppear {
                if let transaction = transaction {
                    transactionType = transaction.transactionType
                    transactionName = transaction.transactionName
                    amount = transaction.amount
                    selectedAccountID = transaction.fromAccountID
                    selectedTargetAccountID = transaction.toAccountID ?? ""
                    selectedDateTime = transaction.dateTime
                    selectedEmoji = selectEmoji(for: transaction.transactionType)
                } else {
                    selectedEmoji = selectEmoji(for: transactionType)
                }
            }
        }
    }
    
    func selectEmoji(for transactionType: String) -> String {
        switch transactionType {
        case "Expense":
            return "💰"
        case "Income":
            return "🍾"
        case "Transaction":
            return "🔄"
        default:
            return "❓"
        }
    }
}
