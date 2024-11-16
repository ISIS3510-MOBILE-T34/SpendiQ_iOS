// TransactionViewModel.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var transactionsByDay: [String: [Transaction]] = [:]
    @Published var totalByDay: [String: Float] = [:]
    @Published var accounts: [String: String] = [:]
    private let db = FirestoreManager.shared.db
    private let bankAccountViewModel = BankAccountViewModel()
    private let context = PersistenceController.shared.container.viewContext
    
    // Computed property to get the current user's UID
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    init() {
        // Load transactions from cache
        loadCachedTransactions()
        // Fetch transactions from Firebase
        getTransactionsForAllAccounts()
    }
    
    // Fetches transactions for all accounts belonging to the current user
    func getTransactionsForAllAccounts() {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        
        db.collection("accounts")
            .whereField("user_id", isEqualTo: userID)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error retrieving accounts: \(error.localizedDescription)")
                } else {
                    var transactionsTemp: [Transaction] = []
                    var transactionsByDayTemp: [String: [Transaction]] = [:]
                    var totalByDayTemp: [String: Float] = [:]
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    
                    let group = DispatchGroup()
                    
                    for document in querySnapshot?.documents ?? [] {
                        let accountID = document.documentID
                        self.getAccountName(accountID: accountID)
                        
                        group.enter()
                        self.db.collection("accounts").document(accountID).collection("transactions").getDocuments { (transactionSnapshot, error) in
                            if let error = error {
                                print("Error retrieving transactions: \(error.localizedDescription)")
                            } else {
                                for transactionDoc in transactionSnapshot?.documents ?? [] {
                                    var transaction = try? transactionDoc.data(as: Transaction.self)
                                    transaction?.id = transactionDoc.documentID
                                    transaction?.accountID = accountID
                                    
                                    if let transaction = transaction {
                                        transactionsTemp.append(transaction)
                                        
                                        let day = dateFormatter.string(from: transaction.dateTime)
                                        
                                        if transactionsByDayTemp[day] != nil {
                                            transactionsByDayTemp[day]?.append(transaction)
                                        } else {
                                            transactionsByDayTemp[day] = [transaction]
                                        }
                                        
                                        totalByDayTemp[day] = (totalByDayTemp[day] ?? 0.0) + transaction.amount
                                    }
                                }
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        self.transactions = transactionsTemp
                        self.transactionsByDay = transactionsByDayTemp
                        self.totalByDay = totalByDayTemp
                        print("Loaded transactions for all accounts.")
                        // Save transactions to cache
                        self.saveTransactionsToCache()
                    }
                }
            }
    }
    
    // Adds a new transaction to a specific account
    func addTransaction(accountID: String, transactionName: String, amount: Float, transactionType: String, dateTime: Date, location: Location, amountAnomaly: Bool = false, locationAnomaly: Bool = false, automatic: Bool = false) {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        
        // Verify that the account belongs to the current user
        db.collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountUserID = document.data()?["user_id"] as? String
                if accountUserID == userID {
                    let newTransaction = Transaction(
                        id: nil,
                        accountID: accountID,
                        transactionName: transactionName,
                        amount: amount,
                        amountAnomaly: amountAnomaly,
                        automatic: automatic,
                        dateTime: dateTime,
                        location: location,
                        locationAnomaly: locationAnomaly,
                        transactionType: transactionType
                    )
                    
                    do {
                        let _ = try self.db.collection("accounts").document(accountID).collection("transactions").addDocument(from: newTransaction) { error in
                            if let error = error {
                                print("Error saving transaction: \(error.localizedDescription)")
                            } else {
                                print("Transaction saved successfully")
                                self.updateAccountBalanceOnAdd(accountID: accountID, amount: amount, transactionType: transactionType)
                                // Update cache
                                self.saveTransactionToCache(transaction: newTransaction)
                                // Refresh transactions
                                self.getTransactionsForAllAccounts()
                            }
                        }
                    } catch {
                        print("Error saving transaction: \(error.localizedDescription)")
                    }
                } else {
                    print("Permission denied: You can only add transactions to your own accounts.")
                }
            } else {
                print("Account does not exist.")
            }
        }
    }
    
    // Updates an existing transaction
    func updateTransaction(accountID: String, transaction: Transaction, transactionName: String, amount: Float, transactionType: String, dateTime: Date, location: Location, amountAnomaly: Bool = false, locationAnomaly: Bool = false, automatic: Bool = false) {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        guard let transactionID = transaction.id else {
            print("Transaction ID is missing.")
            return
        }
        
        // Verify that the account belongs to the current user
        db.collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountUserID = document.data()?["user_id"] as? String
                if accountUserID == userID {
                    let updatedTransaction = Transaction(
                        id: transactionID,
                        accountID: accountID,
                        transactionName: transactionName,
                        amount: amount,
                        amountAnomaly: amountAnomaly,
                        automatic: automatic,
                        dateTime: dateTime,
                        location: location,
                        locationAnomaly: locationAnomaly,
                        transactionType: transactionType
                    )
                    
                    do {
                        try self.db.collection("accounts").document(accountID).collection("transactions").document(transactionID).setData(from: updatedTransaction) { error in
                            if let error = error {
                                print("Error updating transaction: \(error.localizedDescription)")
                            } else {
                                print("Transaction updated successfully")
                                self.adjustAccountBalanceAfterEdit(accountID: accountID, oldTransaction: transaction, newTransaction: updatedTransaction)
                                // Update cache
                                self.updateTransactionInCache(transaction: updatedTransaction)
                                // Refresh transactions
                                self.getTransactionsForAllAccounts()
                            }
                        }
                    } catch {
                        print("Error updating transaction: \(error.localizedDescription)")
                    }
                } else {
                    print("Permission denied: You can only update transactions in your own accounts.")
                }
            } else {
                print("Account does not exist.")
            }
        }
    }
    
    // Deletes a transaction from a specific account
    func deleteTransaction(accountID: String, transactionID: String) {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        
        // Verify that the account belongs to the current user
        db.collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountUserID = document.data()?["user_id"] as? String
                if accountUserID == userID {
                    // Fetch the transaction to get its details
                    self.db.collection("accounts").document(accountID).collection("transactions").document(transactionID).getDocument { (document, error) in
                        if let document = document, document.exists {
                            var transaction = try? document.data(as: Transaction.self)
                            transaction?.id = transactionID
                            
                            if let transaction = transaction {
                                self.db.collection("accounts").document(accountID).collection("transactions").document(transactionID).delete { error in
                                    if let error = error {
                                        print("Error deleting transaction: \(error.localizedDescription)")
                                    } else {
                                        print("Transaction deleted successfully")
                                        self.reverseAccountBalance(accountID: accountID, amount: transaction.amount, transactionType: transaction.transactionType)
                                        // Update cache
                                        self.deleteTransactionFromCache(transactionID: transactionID)
                                        // Refresh transactions
                                        self.getTransactionsForAllAccounts()
                                    }
                                }
                            } else {
                                print("Transaction data is invalid.")
                            }
                        } else {
                            print("Transaction not found.")
                        }
                    }
                } else {
                    print("Permission denied: You can only delete transactions from your own accounts.")
                }
            } else {
                print("Account does not exist.")
            }
        }
    }
    
    // Fetches the account name for display purposes
    func getAccountName(accountID: String) {
        if accounts[accountID] != nil {
            return
        }
        
        db.collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountName = document.data()?["name"] as? String ?? "Unknown Account"
                DispatchQueue.main.async {
                    self.accounts[accountID] = accountName
                }
            } else {
                print("Account not found for ID: \(accountID)")
            }
        }
    }
    
    // Updates the account balance when a new transaction is added
    private func updateAccountBalanceOnAdd(accountID: String, amount: Float, transactionType: String) {
        var amountChange: Double = 0.0
        
        if transactionType == "Expense" {
            amountChange = -Double(amount)
        } else if transactionType == "Income" {
            amountChange = Double(amount)
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: amountChange)
    }
    
    // Reverses the account balance when a transaction is deleted
    private func reverseAccountBalance(accountID: String, amount: Float, transactionType: String) {
        var amountChange: Double = 0.0
        
        if transactionType == "Expense" {
            amountChange = Double(amount)
        } else if transactionType == "Income" {
            amountChange = -Double(amount)
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: amountChange)
    }
    
    // Adjusts the account balance when a transaction is edited
    private func adjustAccountBalanceAfterEdit(accountID: String, oldTransaction: Transaction, newTransaction: Transaction) {
        var amountChange: Double = 0.0
        
        // Reverse old transaction effect
        if oldTransaction.transactionType == "Expense" {
            amountChange += Double(oldTransaction.amount)
        } else if oldTransaction.transactionType == "Income" {
            amountChange -= Double(oldTransaction.amount)
        }
        
        // Apply new transaction effect
        if newTransaction.transactionType == "Expense" {
            amountChange -= Double(newTransaction.amount)
        } else if newTransaction.transactionType == "Income" {
            amountChange += Double(newTransaction.amount)
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: amountChange)
    }
    
    // MARK: - Caching Methods
    
    private func loadCachedTransactions() {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        do {
            let transactionEntities = try context.fetch(fetchRequest)
            let cachedTransactions = transactionEntities.map { entity -> Transaction in
                return Transaction(
                    id: entity.id,
                    accountID: entity.accountID ?? "",
                    transactionName: entity.transactionName ?? "",
                    amount: entity.amount,
                    amountAnomaly: entity.amountAnomaly,
                    automatic: entity.automatic,
                    dateTime: entity.dateTime ?? Date(),
                    location: Location(latitude: entity.latitude, longitude: entity.longitude),
                    locationAnomaly: entity.locationAnomaly,
                    transactionType: entity.transactionType ?? ""
                )
            }
            self.transactions = cachedTransactions
            organizeTransactions()
        } catch {
            print("Error fetching transactions from cache: \(error.localizedDescription)")
        }
    }
    
    private func saveTransactionsToCache() {
        // Remove existing cached transactions
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TransactionEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Error deleting old transactions from cache: \(error.localizedDescription)")
        }
        
        // Save new transactions
        for transaction in transactions {
            let transactionEntity = TransactionEntity(context: context)
            transactionEntity.id = transaction.id
            transactionEntity.accountID = transaction.accountID
            transactionEntity.transactionName = transaction.transactionName
            transactionEntity.amount = transaction.amount
            transactionEntity.amountAnomaly = transaction.amountAnomaly
            transactionEntity.automatic = transaction.automatic
            transactionEntity.dateTime = transaction.dateTime
            transactionEntity.latitude = transaction.location.latitude
            transactionEntity.longitude = transaction.location.longitude
            transactionEntity.locationAnomaly = transaction.locationAnomaly
            transactionEntity.transactionType = transaction.transactionType
        }
        
        saveContext()
    }
    
    private func saveTransactionToCache(transaction: Transaction) {
        let transactionEntity = TransactionEntity(context: context)
        transactionEntity.id = transaction.id
        transactionEntity.accountID = transaction.accountID
        transactionEntity.transactionName = transaction.transactionName
        transactionEntity.amount = transaction.amount
        transactionEntity.amountAnomaly = transaction.amountAnomaly
        transactionEntity.automatic = transaction.automatic
        transactionEntity.dateTime = transaction.dateTime
        transactionEntity.latitude = transaction.location.latitude
        transactionEntity.longitude = transaction.location.longitude
        transactionEntity.locationAnomaly = transaction.locationAnomaly
        transactionEntity.transactionType = transaction.transactionType
        
        saveContext()
    }
    
    private func updateTransactionInCache(transaction: Transaction) {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", transaction.id ?? "")
        do {
            let transactionEntities = try context.fetch(fetchRequest)
            if let transactionEntity = transactionEntities.first {
                transactionEntity.transactionName = transaction.transactionName
                transactionEntity.amount = transaction.amount
                transactionEntity.amountAnomaly = transaction.amountAnomaly
                transactionEntity.automatic = transaction.automatic
                transactionEntity.dateTime = transaction.dateTime
                transactionEntity.latitude = transaction.location.latitude
                transactionEntity.longitude = transaction.location.longitude
                transactionEntity.locationAnomaly = transaction.locationAnomaly
                transactionEntity.transactionType = transaction.transactionType
                
                saveContext()
            }
        } catch {
            print("Error updating transaction in cache: \(error.localizedDescription)")
        }
    }
    
    private func deleteTransactionFromCache(transactionID: String) {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", transactionID)
        do {
            let transactionEntities = try context.fetch(fetchRequest)
            for entity in transactionEntities {
                context.delete(entity)
            }
            saveContext()
        } catch {
            print("Error deleting transaction from cache: \(error.localizedDescription)")
        }
    }
    
    private func organizeTransactions() {
        var transactionsByDayTemp: [String: [Transaction]] = [:]
        var totalByDayTemp: [String: Float] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for transaction in transactions {
            let day = dateFormatter.string(from: transaction.dateTime)
            
            if transactionsByDayTemp[day] != nil {
                transactionsByDayTemp[day]?.append(transaction)
            } else {
                transactionsByDayTemp[day] = [transaction]
            }
            
            totalByDayTemp[day] = (totalByDayTemp[day] ?? 0.0) + transaction.amount
        }
        
        DispatchQueue.main.async {
            self.transactionsByDay = transactionsByDayTemp
            self.totalByDay = totalByDayTemp
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}
