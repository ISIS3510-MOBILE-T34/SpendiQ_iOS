import FirebaseFirestore
import FirebaseAuth
import CoreData
import CoreLocation

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var transactionsByDay: [String: [Transaction]] = [:]
    @Published var totalByDay: [String: Int64] = [:]
    @Published var accounts: [String: String] = [:]
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private let bankAccountViewModel = BankAccountViewModel()
    private let locationManager = LocationManager()
    private let context = PersistenceController.shared.container.viewContext

    init() {
        loadTransactionsFromCache()
    }
    
    // MARK: - Cache Methods
    
    private func loadTransactionsFromCache() {
        let fetchRequest: NSFetchRequest<CachedTransaction> = CachedTransaction.fetchRequest()
        
        do {
            let cachedTransactions = try context.fetch(fetchRequest)
            let transactionsTemp = cachedTransactions.map { cached in
                Transaction(
                    id: cached.id ?? "",
                    accountId: cached.accountId ?? "",
                    transactionName: cached.transactionName ?? "",
                    amount: cached.amount,
                    dateTime: Timestamp(date: cached.dateTime ?? Date()),
                    transactionType: cached.transactionType ?? "",
                    location: cached.latitude != 0 && cached.longitude != 0
                        ? Location(latitude: cached.latitude, longitude: cached.longitude)
                        : nil,
                    amountAnomaly: cached.amountAnomaly,
                    locationAnomaly: cached.locationAnomaly
                )
            }
            self.transactions = transactionsTemp
            self.groupTransactionsByDay()
        } catch {
            print("Error loading transactions from cache: \(error.localizedDescription)")
        }
    }
    
    private func cacheTransaction(_ transaction: Transaction) {
        let cachedTransaction = CachedTransaction(context: context)
        cachedTransaction.id = transaction.id
        cachedTransaction.accountId = transaction.accountId
        cachedTransaction.transactionName = transaction.transactionName
        cachedTransaction.amount = transaction.amount
        cachedTransaction.dateTime = transaction.dateTime.dateValue()
        cachedTransaction.transactionType = transaction.transactionType
        cachedTransaction.latitude = transaction.location?.latitude ?? 0.0
        cachedTransaction.longitude = transaction.location?.longitude ?? 0.0
        cachedTransaction.amountAnomaly = transaction.amountAnomaly
        cachedTransaction.locationAnomaly = transaction.locationAnomaly
        
        do {
            try context.save()
        } catch {
            print("Error saving transaction in cache: \(error.localizedDescription)")
        }
    }
    
    private func clearCache() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CachedTransaction.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Error clearing cache: \(error.localizedDescription)")
        }
    }
    
    private func groupTransactionsByDay() {
        var groupedTransactions: [String: [Transaction]] = [:]
        var dailyTotals: [String: Int64] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for transaction in transactions {
            let day = dateFormatter.string(from: transaction.dateTime.dateValue())
            if groupedTransactions[day] == nil {
                groupedTransactions[day] = []
            }
            groupedTransactions[day]?.append(transaction)
            dailyTotals[day] = (dailyTotals[day] ?? 0) + transaction.amount
        }
        
        self.transactionsByDay = groupedTransactions
        self.totalByDay = dailyTotals
    }
    
    // MARK: - Firestore Methods
    
    func getTransactionsForAllAccounts(forceRefresh: Bool = false) {
        if !forceRefresh && !transactions.isEmpty {
            print("Currently using cached data")
            groupTransactionsByDay()
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        isLoading = true
        clearCache()
        
        db.collection("users").document(userId).collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error retrieving accounts: \(error.localizedDescription)")
                self.isLoading = false
            } else {
                var transactionsTemp: [Transaction] = []
                
                for document in querySnapshot?.documents ?? [] {
                    let accountID = document.documentID
                    self.db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").getDocuments { (transactionSnapshot, error) in
                        if let error = error {
                            print("Error retrieving transactions: \(error.localizedDescription)")
                        } else {
                            for transactionDoc in transactionSnapshot?.documents ?? [] {
                                var transaction = try? transactionDoc.data(as: Transaction.self)
                                transaction?.id = transactionDoc.documentID
                                
                                if let transaction = transaction {
                                    transactionsTemp.append(transaction)
                                    self.cacheTransaction(transaction)
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.transactions = transactionsTemp
                            self.groupTransactionsByDay()
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    func addTransaction(accountID: String, transactionName: String, amount: Int64, transactionType: String, dateTime: Timestamp, location: Location?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        guard !accountID.isEmpty else {
            print("Error: Account ID cannot be empty")
            return
        }
        
        let newTransaction = Transaction(
            id: "",
            accountId: accountID,
            transactionName: transactionName,
            amount: amount,
            dateTime: dateTime,
            transactionType: transactionType,
            location: location,
            amountAnomaly: false,
            locationAnomaly: false
        )
        
        do {
            let _ = try db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").addDocument(from: newTransaction) { error in
                if let error = error {
                    print("Error saving transaction: \(error.localizedDescription)")
                } else {
                    print("Transaction saved successfully")
                    self.updateAccountBalanceOnAdd(accountID: accountID, amount: amount, transactionType: transactionType)
                    self.getTransactionsForAllAccounts()
                    self.cacheTransaction(newTransaction)
                    self.analyzeTransaction(userId: userId, transactionId: newTransaction.id ?? "")
                }
            }
        } catch {
            print("Error saving transaction: \(error.localizedDescription)")
        }
    }
    
    func updateTransaction(transaction: Transaction, transactionName: String, amount: Int64, transactionType: String, dateTime: Timestamp, location: Location) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        let updatedTransaction = Transaction(
            id: transaction.id,
            accountId: transaction.accountId,
            transactionName: transactionName,
            amount: amount,
            dateTime: dateTime,
            transactionType: transactionType,
            location: location,
            amountAnomaly: transaction.amountAnomaly,
            locationAnomaly: transaction.locationAnomaly
        )
        
        do {
            try db.collection("users").document(userId).collection("accounts").document(transaction.accountId).collection("transactions").document(transaction.id ?? "").setData(from: updatedTransaction) { error in
                if let error = error {
                    print("Error updating transaction: \(error.localizedDescription)")
                } else {
                    print("Transaction updated successfully")
                    self.adjustAccountBalanceAfterEdit(oldTransaction: transaction, newTransaction: updatedTransaction)
                    self.getTransactionsForAllAccounts()
                    self.cacheTransaction(updatedTransaction)
                    self.analyzeTransaction(userId: userId, transactionId: transaction.id ?? "")
                }
            }
        } catch {
            print("Error updating transaction: \(error.localizedDescription)")
        }
    }
    
    func deleteTransaction(accountID: String, transactionID: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").document(transactionID).getDocument { (document, error) in
            if let document = document, document.exists {
                let transaction = try? document.data(as: Transaction.self)
                if let transaction = transaction {
                    self.db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").document(transactionID).delete { error in
                        if let error = error {
                            print("Error deleting transaction: \(error.localizedDescription)")
                        } else {
                            print("Transaction deleted successfully")
                            self.reverseAccountBalance(accountID: accountID, amount: transaction.amount, transactionType: transaction.transactionType)
                            self.getTransactionsForAllAccounts()
                            self.removeTransactionFromCache(transactionID: transactionID)
                        }
                    }
                }
            } else {
                print("Transaction not found for deletion")
            }
        }
    }
    
    private func removeTransactionFromCache(transactionID: String) {
        let fetchRequest: NSFetchRequest<CachedTransaction> = CachedTransaction.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", transactionID)
        
        do {
            let results = try context.fetch(fetchRequest)
            for object in results {
                context.delete(object)
            }
            try context.save()
        } catch {
            print("Error deleting transaction from cache: \(error.localizedDescription)")
        }
    }
    
    func getAccountName(accountID: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("User not authenticated")
            return
        }
        
        if accounts[accountID] != nil {
            return
        }
        
        db.collection("users").document(userId).collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountName = document.data()?["name"] as? String ?? "Unknown account"
                DispatchQueue.main.async {
                    self.accounts[accountID] = accountName
                }
            } else {
                print("Account not found for ID: \(accountID)")
            }
        }
    }
    
    private func updateAccountBalanceOnAdd(accountID: String, amount: Int64, transactionType: String) {
        var amountChange: Int64 = 0
        
        if transactionType == "Expense" {
            amountChange = -amount
        } else if transactionType == "Income" {
            amountChange = amount
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: Double(amountChange))
    }
    
    private func reverseAccountBalance(accountID: String, amount: Int64, transactionType: String) {
        var amountChange: Int64 = 0
        
        if transactionType == "Expense" {
            amountChange = amount
        } else if transactionType == "Income" {
            amountChange = -amount
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: Double(amountChange))
    }
    
    private func adjustAccountBalanceAfterEdit(oldTransaction: Transaction, newTransaction: Transaction) {
        guard oldTransaction.accountId == newTransaction.accountId else {
            return
        }
        
        let accountID = newTransaction.accountId
        var amountChange: Int64 = 0
        
        if oldTransaction.transactionType == "Expense" {
            amountChange += oldTransaction.amount
        } else if oldTransaction.transactionType == "Income" {
            amountChange -= oldTransaction.amount
        }
        
        if newTransaction.transactionType == "Expense" {
            amountChange -= newTransaction.amount
        } else if newTransaction.transactionType == "Income" {
            amountChange += newTransaction.amount
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: Double(amountChange))
    }
    
    private func analyzeTransaction(userId: String, transactionId: String) {
        let urlString = "http://148.113.204.223:8000/api/analyze-transaction-complete/\(userId)/\(transactionId)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error calling analysis endpoint: \(error.localizedDescription)")
            } else {
                print("Analysis endpoint call successful")
            }
        }.resume()
    }
}
