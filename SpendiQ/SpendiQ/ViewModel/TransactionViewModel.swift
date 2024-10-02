import FirebaseFirestore

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var transactionsByDay: [String: [Transaction]] = [:]  // Agrupar transacciones por día
    @Published var totalByDay: [String: Float] = [:]  // Total de transacciones por día
    @Published var accounts: [String: String] = [:]  // Diccionario que almacena el ID de la cuenta y su nombre
    private let db = Firestore.firestore()

    // Función para obtener las transacciones de todas las cuentas
    func getTransactionsForAllAccounts() {
        db.collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error retrieving accounts: \(error.localizedDescription)")
            } else {
                var transactionsTemp: [Transaction] = []
                var transactionsByDayTemp: [String: [Transaction]] = [:]
                var totalByDayTemp: [String: Float] = [:]

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"  // Formato para agrupar por día

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

                                    // Convertir la fecha a un formato de día
                                    let day = dateFormatter.string(from: transaction.dateTime)

                                    // Agrupar transacciones por día
                                    if transactionsByDayTemp[day] != nil {
                                        transactionsByDayTemp[day]?.append(transaction)
                                    } else {
                                        transactionsByDayTemp[day] = [transaction]
                                    }

                                    // Sumar el total de cada día
                                    totalByDayTemp[day] = (totalByDayTemp[day] ?? 0.0) + transaction.amount

                                    // Obtener el nombre de la cuenta de la transacción
                                    self.getAccountName(fromAccountID: transaction.fromAccountID)
                                }
                            }
                        }

                        // Actualizar las propiedades publicadas
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
                    self.getTransactionsForAllAccounts()  // Actualizar la lista de transacciones de todas las cuentas
                }
            }
        } catch {
            print("Error saving transaction: \(error.localizedDescription)")
        }
    }

    // Función para eliminar una transacción en la subcolección de una cuenta
    func deleteTransaction(accountID: String, transactionID: String) {
        db.collection("accounts").document(accountID).collection("transactions").document(transactionID).delete { error in
            if let error = error {
                print("Error deleting transaction: \(error.localizedDescription)")
            } else {
                print("Transaction deleted successfully")
                self.getTransactionsForAllAccounts()  // Actualizar la lista de transacciones de todas las cuentas
            }
        }
    }

    // Función para obtener el nombre de la cuenta a partir del ID
    func getAccountName(fromAccountID: String) {
        // Verificar si ya tenemos el nombre de la cuenta en el diccionario
        if accounts[fromAccountID] != nil {
            return
        }
        
        // Si no está en caché, buscar en Firestore
        db.collection("accounts").document(fromAccountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let accountName = document.data()?["name"] as? String ?? "Unknown Account"
                DispatchQueue.main.async {
                    self.accounts[fromAccountID] = accountName  // Almacenar en el diccionario para uso futuro
                }
            } else {
                print("Account not found for ID: \(fromAccountID)")
            }
        }
    }
}
