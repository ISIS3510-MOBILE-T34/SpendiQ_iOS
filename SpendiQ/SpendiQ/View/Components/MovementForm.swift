import SwiftUI
import FirebaseCore
import CoreLocation
import MapKit

struct MovementForm: View {
    @ObservedObject var bankAccountViewModel: BankAccountViewModel
    private let locationManager = LocationManager() // Instancia de LocationManager

    var body: some View {
        EditTransactionForm(
            locationManager: locationManager,
            bankAccountViewModel: bankAccountViewModel,
            transactionViewModel: TransactionViewModel(),
            transaction: nil
        )
    }
}

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

    @State private var mapRegion = EquatableCoordinateRegion(region: MKCoordinateRegion())

    @ObservedObject var bankAccountViewModel: BankAccountViewModel
    @ObservedObject var transactionViewModel: TransactionViewModel
    var transaction: Transaction?
    
    init(locationManager: LocationManager, bankAccountViewModel: BankAccountViewModel, transactionViewModel: TransactionViewModel, transaction: Transaction?) {
        self.locationManager = locationManager
        self.bankAccountViewModel = bankAccountViewModel
        self.transactionViewModel = transactionViewModel
        self.transaction = transaction
        
        // Inicializa mapRegion con la ubicación actual o una región predeterminada
        _mapRegion = State(initialValue: EquatableCoordinateRegion(region: MKCoordinateRegion(
            center: transaction?.location?.toCoordinate() ?? locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
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
                .onChange(of: transactionType) { _, newValue in
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
                        // Aquí puedes abrir un selector de emojis o algo similar si lo necesitas
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
                            if bankAccountViewModel.accounts.isEmpty {
                                bankAccountViewModel.getBankAccounts()
                            }
                            if selectedAccountID.isEmpty, let firstAccount = bankAccountViewModel.accounts.first {
                                selectedAccountID = firstAccount.id ?? ""
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
                    
                    Section(header: Text("Date")) {
                        DatePicker("Select Date", selection: $selectedDateTime, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    Section(header: Text("Time")) {
                        DatePicker("Select Time", selection: $selectedDateTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    Section(header: Text("Location")) {
                        Map(coordinateRegion: .constant(mapRegion.region), interactionModes: .all)
                            .frame(height: 200)
                            .onAppear {
                                if transactionLocation == nil {
                                    transactionLocation = mapRegion.region.center
                                }
                            }
                            .onChange(of: mapRegion) { newRegion in
                                transactionLocation = newRegion.region.center
                            }
                    }
                }
                
                HStack {
                    Button(action: {
                        let dateTime = Timestamp(date: selectedDateTime)
                        
                        if let location = transactionLocation {
                            let newLocation = Location(latitude: location.latitude, longitude: location.longitude)
                            
                            if let transaction = transaction {
                                transactionViewModel.updateTransaction(
                                    transaction: transaction,
                                    transactionName: transactionName,
                                    amount: amount,
                                    transactionType: transactionType,
                                    dateTime: dateTime,
                                    location: newLocation
                                )
                            } else {
                                transactionViewModel.addTransaction(
                                    accountID: selectedAccountID,
                                    transactionName: transactionName,
                                    amount: amount,
                                    transactionType: transactionType,
                                    dateTime: dateTime,
                                    location: newLocation
                                )
                            }
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
                                transactionID: transaction!.id ?? ""
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
                    selectedAccountID = transaction.accountId
                    selectedDateTime = transaction.dateTime.dateValue()
                    transactionLocation = transaction.location?.toCoordinate()
                    mapRegion.region.center = transactionLocation ?? CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
                    selectedEmoji = selectEmoji(for: transaction.transactionType)
                }
            }
        }
    }
    
    func selectEmoji(for transactionType: String) -> String {
        switch transactionType {
        case "Expense": return "💰"
        case "Income": return "🍾"
        case "Transaction": return "🔄"
        default: return "❓"
        }
    }
}

// Wrapper Equatable para MKCoordinateRegion
struct EquatableCoordinateRegion: Equatable {
    var region: MKCoordinateRegion
    
    static func == (lhs: EquatableCoordinateRegion, rhs: EquatableCoordinateRegion) -> Bool {
        lhs.region.center.latitude == rhs.region.center.latitude &&
        lhs.region.center.longitude == rhs.region.center.longitude &&
        lhs.region.span.latitudeDelta == rhs.region.span.latitudeDelta &&
        lhs.region.span.longitudeDelta == rhs.region.span.longitudeDelta
    }
}

// Extensión para convertir Location a CLLocationCoordinate2D
extension Location {
    func toCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
