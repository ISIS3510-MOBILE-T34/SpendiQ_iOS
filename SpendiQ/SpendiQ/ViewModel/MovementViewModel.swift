import FirebaseFirestore

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    private let db = Firestore.firestore()
    
    // Función para agregar una nueva transacción a Firebase
    func addTransaction(transactionName: String, amount: Float, fromAccountID: String, toAccountID: String?, transactionType: String, dateTime: Date) {
        let newTransaction = Transaction(
            transactionName: transactionName,
            amount: amount,
            fromAccountID: fromAccountID,
            toAccountID: toAccountID,
            transactionType: transactionType,
            dateTime: dateTime
        )
        
        do {
            let _ = try db.collection("transactions").addDocument(from: newTransaction) { error in
                if let error = error {
                    print("Error saving transaction: \(error.localizedDescription)")
                } else {
                    print("Transaction saved successfully")
                    self.getTransactions()  // Actualizar la lista de transacciones
                }
            }
        } catch {
            print("Error saving transaction: \(error.localizedDescription)")
        }
    }
    
    // Función para obtener las transacciones desde Firebase
    func getTransactions() {
        db.collection("transactions").getDocuments { (querySnapshot, error) in
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
    
    // Función para eliminar una transacción
    func deleteTransaction(transactionID: String) {
        db.collection("transactions").document(transactionID).delete { error in
            if let error = error {
                print("Error deleting transaction: \(error.localizedDescription)")
            } else {
                print("Transaction deleted successfully")
                self.getTransactions()
            }
        }
    }
}
