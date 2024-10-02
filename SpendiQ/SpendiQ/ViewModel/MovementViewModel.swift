import FirebaseFirestore

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    private let db = Firestore.firestore()

    // Función para agregar una nueva transacción a la subcolección de la cuenta
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
                    self.getTransactions(forAccountID: accountID)  // Actualizar la lista de transacciones
                }
            }
        } catch {
            print("Error saving transaction: \(error.localizedDescription)")
        }
    }

    // Función para obtener las transacciones desde la subcolección de la cuenta
    func getTransactions(forAccountID accountID: String) {
        db.collection("accounts").document(accountID).collection("transactions").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error retrieving transactions: \(error.localizedDescription)")
            } else {
                let transactions = querySnapshot?.documents.compactMap { document -> Transaction? in
                    var transaction = try? document.data(as: Transaction.self)
                    transaction?.id = document.documentID
                    return transaction
                }
                DispatchQueue.main.async {
                    self.transactions = transactions ?? []
                }
            }
        }
    }

    // Función para eliminar una transacción en la subcolección de una cuenta
    func deleteTransaction(accountID: String, transactionID: String) {
        db.collection("accounts").document(accountID).collection("transactions").document(transactionID).delete { error in
            if let error = error {
                print("Error deleting transaction: \(error.localizedDescription)")
            } else {
                print("Transaction deleted successfully")
                self.getTransactions(forAccountID: accountID)  // Actualizar la lista de transacciones
            }
        }
    }
}
