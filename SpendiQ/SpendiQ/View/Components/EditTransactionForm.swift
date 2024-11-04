import SwiftUI
import MapKit
import FirebaseFirestore

struct EditTransactionForm: View {
    @ObservedObject var locationManager: LocationManager
    @Environment(\.dismiss) var dismiss

    @State private var transactionType: String = "Expense"
    @State private var transactionName: String = ""
    @State private var amount: Int64 = 0
    @State private var selectedAccountID: String = ""
    @State private var selectedTargetAccountID: String = ""
    @State private var selectedEmoji: String = ""
    @State private var selectedDateTime: Date = Date()
    @State private var transactionLocation: CLLocationCoordinate2D?

    @State private var mapRegion: MKCoordinateRegion

    @ObservedObject var bankAccountViewModel: BankAccountViewModel
    @ObservedObject var transactionViewModel: TransactionViewModel
    var transaction: Transaction?
    
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    init(locationManager: LocationManager, bankAccountViewModel: BankAccountViewModel, transactionViewModel: TransactionViewModel, transaction: Transaction?) {
        self.locationManager = locationManager
        self.bankAccountViewModel = bankAccountViewModel
        self.transactionViewModel = transactionViewModel
        self.transaction = transaction

        // Initialize mapRegion with current location or default region
        let initialCoordinate = transaction?.location?.toCoordinate() ?? locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 20) {
                Text(transaction != nil ? "Edit Transaction" : "New Transaction")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Picker("Select Type", selection: $transactionType) {
                    ForEach(["Expense", "Income", "Transaction"], id: \.self) { type in
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
                            .foregroundColor(.yellow)
                        Text(selectedEmoji.isEmpty ? "🙂" : selectedEmoji)
                            .font(.system(size: 58))
                    }
                    Button("Change icon") {
                        // Implement an emoji selector if needed
                    }
                }
                
                Form {
                    Section(header: Text("Transaction Name")) {
                        TextField("Transaction name", text: $transactionName)
                    }
                    
                    Section(header: Text("Amount")) {
                        TextField("Amount", value: $amount, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    Section(header: Text("Select Account")) {
                        Picker("Account", selection: $selectedAccountID) {
                            ForEach(bankAccountViewModel.accounts) { account in
                                Text(account.name).tag(account.id ?? "")
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onAppear {
                            Task {
                                await loadAccounts()
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
                        }
                    }
                    
                    Section(header: Text("Date and Time")) {
                        DatePicker("Select Date and Time", selection: $selectedDateTime)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    Section(header: Text("Location")) {
                        Map(coordinateRegion: $mapRegion, interactionModes: .all, showsUserLocation: true)
                            .frame(height: 200)
                            .onAppear {
                                if transactionLocation == nil {
                                    transactionLocation = mapRegion.center
                                }
                            }
                            .onChange(of: mapRegion.center) { newCenter in
                                transactionLocation = newCenter
                            }
                    }
                }
                
                HStack {
                    Button(action: {
                        Task {
                            await saveTransaction()
                        }
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
                            Task {
                                await deleteTransaction()
                            }
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
                initializeForm()
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Helper Functions

    private func initializeForm() {
        if let transaction = transaction {
            transactionType = transaction.transactionType
            transactionName = transaction.transactionName
            amount = transaction.amount
            selectedAccountID = transaction.accountId
            selectedDateTime = transaction.dateTime.dateValue()
            transactionLocation = transaction.location?.toCoordinate()
            mapRegion.center = transactionLocation ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
            selectedEmoji = selectEmoji(for: transaction.transactionType)
        } else {
            selectedEmoji = selectEmoji(for: transactionType)
            if let userLocation = locationManager.location?.coordinate {
                transactionLocation = userLocation
                mapRegion.center = userLocation
            }
        }
    }
    
    private func selectEmoji(for transactionType: String) -> String {
        switch transactionType {
        case "Expense": return "💰"
        case "Income": return "🍾"
        case "Transaction": return "🔄"
        default: return "❓"
        }
    }
    
    private func loadAccounts() async {
        do {
            if bankAccountViewModel.accounts.isEmpty {
                try await bankAccountViewModel.getBankAccounts()
            }
            if selectedAccountID.isEmpty, let firstAccount = bankAccountViewModel.accounts.first {
                selectedAccountID = firstAccount.id ?? ""
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func saveTransaction() async {
        let dateTime = Timestamp(date: selectedDateTime)
        
        guard let location = transactionLocation else {
            errorMessage = "Location not available."
            showErrorAlert = true
            return
        }
        
        let newLocation = Location(latitude: location.latitude, longitude: location.longitude)
        
        do {
            if let transaction = transaction {
                try await transactionViewModel.updateTransaction(
                    transaction: transaction,
                    transactionName: transactionName,
                    amount: amount,
                    transactionType: transactionType,
                    dateTime: dateTime,
                    location: newLocation
                )
            } else {
                try await transactionViewModel.addTransaction(
                    accountID: selectedAccountID,
                    transactionName: transactionName,
                    amount: amount,
                    transactionType: transactionType,
                    dateTime: dateTime,
                    location: newLocation
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func deleteTransaction() async {
        guard let transaction = transaction else { return }
        do {
            try await transactionViewModel.deleteTransaction(
                accountID: transaction.accountId,
                transactionID: transaction.id ?? ""
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

// Extension to make CLLocationCoordinate2D conform to Equatable
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

// Extension to convert Location to CLLocationCoordinate2D
extension Location {
    func toCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
