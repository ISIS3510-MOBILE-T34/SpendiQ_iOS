// TransactionViewModel.swift

import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var transactionsByDay: [String: [Transaction]] = [:]
    @Published var totalByDay: [String: Float] = [:]
    @Published var accounts: [String: String] = [:]
    
    private let db = Firestore.firestore()
    private let bankAccountViewModel = BankAccountViewModel()
    
    // Usamos el LocationManager personalizado en lugar de CLLocationManager
    private let locationManager = LocationManager()
    
    func getTransactionsForAllAccounts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }

        db.collection("users").document(userId).collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error al recuperar las cuentas: \(error.localizedDescription)")
            } else {
                var transactionsTemp: [Transaction] = []
                var transactionsByDayTemp: [String: [Transaction]] = [:]
                var totalByDayTemp: [String: Float] = [:]

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

                                    let day = dateFormatter.string(from: transaction.dateTime)

                                    if transactionsByDayTemp[day] != nil {
                                        transactionsByDayTemp[day]?.append(transaction)
                                    } else {
                                        transactionsByDayTemp[day] = [transaction]
                                    }

                                    totalByDayTemp[day] = (totalByDayTemp[day] ?? 0.0) + transaction.amount

                                    self.getAccountName(fromAccountID: transaction.fromAccountID)
                                }
                            }
                        }

                        DispatchQueue.main.async {
                            self.transactions = transactionsTemp
                            self.transactionsByDay = transactionsByDayTemp
                            self.totalByDay = totalByDayTemp
                        }
                    }
                }
            }
        }
    }
    
    func addTransaction(accountID: String, transactionName: String, amount: Float, fromAccountID: String?, toAccountID: String?, transactionType: String, dateTime: Date) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }
        
        // Obtener la última ubicación conocida del LocationManager personalizado
        let location = locationManager.location

        let newTransaction = Transaction(
            transactionName: transactionName,
            amount: amount,
            fromAccountID: fromAccountID ?? "",
            toAccountID: toAccountID,
            transactionType: transactionType,
            dateTime: dateTime,
            latitude: location?.coordinate.latitude,  // Usar latitud si está disponible
            longitude: location?.coordinate.longitude // Usar longitud si está disponible
        )

        do {
            let _ = try db.collection("users").document(userId).collection("accounts").document(accountID).collection("transactions").addDocument(from: newTransaction) { error in
                if let error = error {
                    print("Error al guardar la transacción: \(error.localizedDescription)")
                } else {
                    print("Transacción guardada exitosamente")
                    self.updateAccountBalanceOnAdd(accountID: accountID, amount: amount, transactionType: transactionType)
                    self.getTransactionsForAllAccounts()
                }
            }
        } catch {
            print("Error al guardar la transacción: \(error.localizedDescription)")
        }
    }
    
    func updateTransaction(transaction: Transaction, transactionName: String, amount: Float, fromAccountID: String, toAccountID: String?, transactionType: String, dateTime: Date) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }
        guard let transactionID = transaction.id else { return }

        let updatedTransaction = Transaction(
            transactionName: transactionName,
            amount: amount,
            fromAccountID: fromAccountID,
            toAccountID: toAccountID,
            transactionType: transactionType,
            dateTime: dateTime
        )

        do {
            try db.collection("users").document(userId).collection("accounts").document(fromAccountID).collection("transactions").document(transactionID).setData(from: updatedTransaction) { error in
                if let error = error {
                    print("Error al actualizar la transacción: \(error.localizedDescription)")
                } else {
                    print("Transacción actualizada exitosamente")
                    self.adjustAccountBalanceAfterEdit(oldTransaction: transaction, newTransaction: updatedTransaction)
                    self.getTransactionsForAllAccounts()
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
    
    func getAccountName(fromAccountID: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }

        if accounts[fromAccountID] != nil {
            return
        }

        db.collection("users").document(userId).collection("accounts").document(fromAccountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountName = document.data()?["name"] as? String ?? "Cuenta desconocida"
                DispatchQueue.main.async {
                    self.accounts[fromAccountID] = accountName
                }
            } else {
                print("Cuenta no encontrada para ID: \(fromAccountID)")
            }
        }
    }
    
    private func updateAccountBalanceOnAdd(accountID: String, amount: Float, transactionType: String) {
        var amountChange: Double = 0.0
        
        if transactionType == "Expense" {
            amountChange = -Double(amount)
        } else if transactionType == "Income" {
            amountChange = Double(amount)
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: amountChange)
    }
    
    private func reverseAccountBalance(accountID: String, amount: Float, transactionType: String) {
        var amountChange: Double = 0.0
        
        if transactionType == "Expense" {
            amountChange = Double(amount)
        } else if transactionType == "Income" {
            amountChange = -Double(amount)
        }
        
        bankAccountViewModel.updateAccountBalance(accountID: accountID, amountChange: amountChange)
    }
    
    private func adjustAccountBalanceAfterEdit(oldTransaction: Transaction, newTransaction: Transaction) {
        guard oldTransaction.fromAccountID == newTransaction.fromAccountID else {
            // Handle account change if needed
            return
        }
        
        let accountID = newTransaction.fromAccountID
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
}
