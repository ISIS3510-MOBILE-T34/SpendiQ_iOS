import FirebaseFirestore
import FirebaseAuth
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
    
    func getTransactionsForAllAccounts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }
        
        isLoading = true
        db.collection("users").document(userId).collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error al recuperar las cuentas: \(error.localizedDescription)")
                self.isLoading = false
            } else {
                var transactionsTemp: [Transaction] = []
                var transactionsByDayTemp: [String: [Transaction]] = [:]
                var totalByDayTemp: [String: Int64] = [:]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                for document in querySnapshot?.documents ?? [] {
                    let accountID = document.documentID
                    self.db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").getDocuments { (transactionSnapshot, error) in
                        if let error = error {
                            print("Error al recuperar las transacciones: \(error.localizedDescription)")
                        } else {
                            for transactionDoc in transactionSnapshot?.documents ?? [] {
                                var transaction = try? transactionDoc.data(as: Transaction.self)
                                transaction?.id = transactionDoc.documentID
                                
                                if let transaction = transaction {
                                    transactionsTemp.append(transaction)
                                    let day = dateFormatter.string(from: transaction.dateTime.dateValue())
                                    if transactionsByDayTemp[day] != nil {
                                        transactionsByDayTemp[day]?.append(transaction)
                                    } else {
                                        transactionsByDayTemp[day] = [transaction]
                                    }
                                    
                                    totalByDayTemp[day] = (totalByDayTemp[day] ?? 0) + transaction.amount
                                }
                            }
                        }
                        
                        DispatchQueue.main.async {
                            self.transactions = transactionsTemp
                            self.transactionsByDay = transactionsByDayTemp
                            self.totalByDay = totalByDayTemp
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    func addTransaction(accountID: String, transactionName: String, amount: Int64, transactionType: String, dateTime: Timestamp, location: Location?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }
        
        guard !accountID.isEmpty else {
            print("Error: accountID está vacío")
            return
        }
        
        let newTransaction = Transaction(
            id: "", // Firestore asignará automáticamente el `id` al crear el documento
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
                    print("Error al guardar la transacción: \(error.localizedDescription)")
                } else {
                    print("Transacción guardada exitosamente")
                    self.updateAccountBalanceOnAdd(accountID: accountID, amount: amount, transactionType: transactionType)
                    self.getTransactionsForAllAccounts()
                    
                    // Llamada al endpoint después de agregar la transacción
                    self.analyzeTransaction(userId: userId, transactionId: newTransaction.id ?? "")
                }
            }
        } catch {
            print("Error al guardar la transacción: \(error.localizedDescription)")
        }
    }
    
    func updateTransaction(transaction: Transaction, transactionName: String, amount: Int64, transactionType: String, dateTime: Timestamp, location: Location) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
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
                    print("Error al actualizar la transacción: \(error.localizedDescription)")
                } else {
                    print("Transacción actualizada exitosamente")
                    self.adjustAccountBalanceAfterEdit(oldTransaction: transaction, newTransaction: updatedTransaction)
                    self.getTransactionsForAllAccounts()
                    
                    // Llamada al endpoint después de actualizar la transacción
                    self.analyzeTransaction(userId: userId, transactionId: transaction.id ?? "")
                }
            }
        } catch {
            print("Error al actualizar la transacción: \(error.localizedDescription)")
        }
    }
    
    func deleteTransaction(accountID: String, transactionID: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }
        
        db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").document(transactionID).getDocument { (document, error) in
            if let document = document, document.exists {
                let transaction = try? document.data(as: Transaction.self)
                if let transaction = transaction {
                    self.db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").document(transactionID).delete { error in
                        if let error = error {
                            print("Error al eliminar la transacción: \(error.localizedDescription)")
                        } else {
                            print("Transacción eliminada exitosamente")
                            self.reverseAccountBalance(accountID: accountID, amount: transaction.amount, transactionType: transaction.transactionType)
                            self.getTransactionsForAllAccounts()
                        }
                    }
                }
            } else {
                print("Transacción no encontrada para eliminar")
            }
        }
    }
    
    func getAccountName(accountID: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }
        
        if accounts[accountID] != nil {
            return
        }
        
        db.collection("users").document(userId).collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountName = document.data()?["name"] as? String ?? "Cuenta desconocida"
                DispatchQueue.main.async {
                    self.accounts[accountID] = accountName
                }
            } else {
                print("Cuenta no encontrada para ID: \(accountID)")
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
                print("Error al llamar al endpoint de análisis: \(error.localizedDescription)")
            } else {
                print("Llamado al endpoint de análisis exitoso")
            }
        }.resume()
    }
}
