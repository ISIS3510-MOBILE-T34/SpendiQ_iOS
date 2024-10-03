import FirebaseFirestore

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var transactionsByDay: [String: [Transaction]] = [:]
    @Published var totalByDay: [String: Float] = [:]
    @Published var accounts: [String: String] = [:]
    private let db = Firestore.firestore()

    func getTransactionsForAllAccounts() {
        db.collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error retrieving accounts: \(error.localizedDescription)")
            } else {
                var transactionsTemp: [Transaction] = []
                var transactionsByDayTemp: [String: [Transaction]] = [:]
                var totalByDayTemp: [String: Float] = [:]

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"

                for document in querySnapshot?.documents ?? [] {
                    let accountID = document.documentID
                    self.db.collection("accounts").document(accountID).collection("transactions").getDocuments { (transactionSnapshot, error) in
                        if let error = error {
                            print("Error retrieving transactions: \(error.localizedDescription)")
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
        let newTransaction = Transaction(
            transactionName: transactionName,
            amount: amount,
            fromAccountID: fromAccountID ?? "",
            toAccountID: accountID,
            transactionType: transactionType,
            dateTime: dateTime
        )

        do {
            let _ = try db.collection("accounts").document(accountID).collection("transactions").addDocument(from: newTransaction) { error in
                if let error = error {
                    print("Error saving transaction: \(error.localizedDescription)")
                } else {
                    print("Transaction saved successfully")
                    self.getTransactionsForAllAccounts()
                }
            }
        } catch {
            print("Error saving transaction: \(error.localizedDescription)")
        }
    }

    func updateTransaction(transaction: Transaction, transactionName: String, amount: Float, fromAccountID: String, toAccountID: String?, transactionType: String, dateTime: Date) {
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
            try db.collection("accounts").document(fromAccountID).collection("transactions").document(transactionID).setData(from: updatedTransaction) { error in
                if let error = error {
                    print("Error updating transaction: \(error.localizedDescription)")
                } else {
                    print("Transaction updated successfully")
                    self.getTransactionsForAllAccounts()
                }
            }
        } catch {
            print("Error updating transaction: \(error.localizedDescription)")
        }
    }

    func deleteTransaction(accountID: String, transactionID: String) {
        db.collection("accounts").document(accountID).collection("transactions").document(transactionID).delete { error in
            if let error = error {
                print("Error deleting transaction: \(error.localizedDescription)")
            } else {
                print("Transaction deleted successfully")
                self.getTransactionsForAllAccounts()
            }
        }
    }

    func getAccountName(fromAccountID: String) {
        if accounts[fromAccountID] != nil {
            return
        }

        db.collection("accounts").document(fromAccountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountName = document.data()?["name"] as? String ?? "Unknown Account"
                DispatchQueue.main.async {
                    self.accounts[fromAccountID] = accountName
                }
            } else {
                print("Account not found for ID: \(fromAccountID)")
            }
        }
    }
}
