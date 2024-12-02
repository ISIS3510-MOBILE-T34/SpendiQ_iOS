import SwiftUI

struct EditTransactionForm: View {
    @Environment(\.dismiss) var dismiss
    @State private var transactionType: String = "Expense"
    @State private var transactionName: String = ""
    @State private var amountText: String = ""
    @State private var selectedAccountID: String = ""
    @State private var selectedEmoji: String = ""
    @State private var selectedDateTime: Date = Date()
    @StateObject private var locationManager = LocationManager()
    @FocusState private var isEmojiFieldFocused: Bool
    @ObservedObject var bankAccountViewModel: BankAccountViewModel
    @ObservedObject var transactionViewModel: TransactionViewModel
    var transactionItem: Transaction?
    
    // Only "Expense" and "Income" types
    let transactionTypes = ["Expense", "Income"]
    
    
    private func saveTransactionWithLocation() {
        guard let location = locationManager.location else {
            print("Location not available")
            return
        }
        
        let transactionLocation = Location(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        guard let amount = Float(amountText) else { return }
        
        if let transactionItem = transactionItem {
            transactionViewModel.updateTransaction(
                accountID: selectedAccountID,
                transaction: transactionItem,
                transactionName: transactionName,
                amount: amount,
                transactionType: transactionType,
                dateTime: selectedDateTime,
                location: transactionLocation
            )
        } else {
            transactionViewModel.addTransaction(
                accountID: selectedAccountID,
                transactionName: transactionName,
                amount: amount,
                transactionType: transactionType,
                dateTime: selectedDateTime,
                location: transactionLocation
            )
        }
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20) {
                Text(transactionItem != nil ? "Edit Transaction" : "New Transaction")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Picker for transaction type
                Picker("Select Type", selection: $transactionType) {
                    ForEach(transactionTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .onChange(of: transactionType) { newValue in
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
                }
                
                // Form fields
                Form {
                    // Transaction name field with alphanumeric validation
                    Section(header: Text("Transaction name")) {
                        TextField("Transaction name", text: $transactionName)
                            .frame(height: 32)
                            .onChange(of: transactionName) { newValue in
                                let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0 == " " }
                                if filtered != newValue {
                                    self.transactionName = filtered
                                }
                                // Limit to 50 characters
                                if transactionName.count > 50 {
                                    transactionName = String(transactionName.prefix(50))
                                }
                            }
                    }
                    
                    // Amount field with numeric validation and max length
                    Section(header: Text("Amount")) {
                        TextField("Amount", text: $amountText)
                            .keyboardType(.decimalPad)
                            .onChange(of: amountText) { newValue in
                                // Allow only numbers and decimal point
                                let filtered = newValue.filter { "0123456789.".contains($0) }
                                if filtered != newValue {
                                    self.amountText = filtered
                                }
                                // Limit to 10 digits
                                let digits = amountText.filter { "0123456789".contains($0) }
                                if digits.count > 10 {
                                    let extraDigits = digits.count - 10
                                    amountText = String(amountText.dropLast(extraDigits))
                                }
                            }
                    }
                    
                    // Account selection
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
                        .onChange(of: bankAccountViewModel.accounts) { newAccounts in
                            if !newAccounts.isEmpty, selectedAccountID.isEmpty {
                                selectedAccountID = newAccounts.first?.id ?? ""
                            }
                        }
                    }
                    
                    // Date and time pickers
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
                .onTapGesture {
                    hideKeyboard()
                }
                
                // Action buttons
                HStack {
                    // Submit button with validation
                    Button(action: saveTransactionWithLocation) {
                        Text(transactionItem != nil ? "Save" : "Accept")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid())
                    
                    // Delete button for editing mode
                    if transactionItem != nil {
                        Button(action: {
                            transactionViewModel.deleteTransaction(
                                accountID: selectedAccountID,
                                transactionID: transactionItem!.id!
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
                    
                    // Cancel button
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
            .onTapGesture {
                hideKeyboard()
            }
            .navigationBarHidden(true)
            .onAppear {
                // Initialize form fields for editing
                if let transactionItem = transactionItem {
                    transactionType = transactionItem.transactionType
                    transactionName = transactionItem.transactionName
                    amountText = String(format: "%.2f", transactionItem.amount)
                    selectedAccountID = transactionItem.accountID
                    selectedDateTime = transactionItem.dateTime
                    selectedEmoji = selectEmoji(for: transactionType)
                } else {
                    selectedEmoji = selectEmoji(for: transactionType)
                }
            }
            
            if locationManager.location == nil {
                Text("Obtaining location...")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // Form validation function
    func isFormValid() -> Bool {
        if transactionName.isEmpty || amountText.isEmpty || selectedAccountID.isEmpty {
            return false
        }
        if Float(amountText) == nil || Float(amountText)! <= 0 {
            return false
        }
        return true
    }
    
    // Function to select emoji based on transaction type
    func selectEmoji(for transactionType: String) -> String {
        switch transactionType {
        case "Expense":
            return "💰"
        case "Income":
            return "🍾"
        default:
            return "❓"
        }
    }
    
    
    
    // Function to dismiss the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
