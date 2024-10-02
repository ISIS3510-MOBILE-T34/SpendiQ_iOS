import FirebaseFirestore

class BankAccountViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    private let db = Firestore.firestore()
    
    // Función para agregar una cuenta a Firestore
    func addAccount(name: String, amount: Double) {
        let newAccount = BankAccount(id: nil, name: name, amount: amount)  // Inicialmente `id` es nil
        
        do {
            let _ = try db.collection("accounts").addDocument(from: newAccount) { error in
                if let error = error {
                    print("Error saving account: \(error.localizedDescription)")
                } else {
                    print("Account saved successfully")
                    self.getBankAccounts()  // Actualizar la lista de cuentas tras la inserción
                }
            }
        } catch {
            print("Error saving account: \(error.localizedDescription)")
        }
    }
    
    // Función para obtener cuentas desde Firestore
    func getBankAccounts() {
        db.collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error retrieving accounts: \(error.localizedDescription)")
            } else {
                let accounts = querySnapshot?.documents.compactMap { document -> BankAccount? in
                    var account = try? document.data(as: BankAccount.self)
                    account?.id = document.documentID  // Asignamos manualmente el `documentID` como `id`
                    return account
                }
                DispatchQueue.main.async {
                    self.accounts = accounts ?? []
                    print("Loaded accounts: \(self.accounts)")  // Debug: Verifica si se cargaron las cuentas
                }
            }
        }
    }
    
    // Función para eliminar una cuenta
    func deleteAccount(accountID: String) {
        db.collection("accounts").document(accountID).delete { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
            } else {
                print("Account deleted successfully")
                self.getBankAccounts()  // Actualizar la lista tras eliminar una cuenta
            }
        }
    }
    
    // Función para actualizar una cuenta en Firestore
    func updateAccount(account: BankAccount, newName: String, newBalance: Double) {
        guard let accountID = account.id else { return }
        let updatedAccount = BankAccount(id: accountID, name: newName, amount: newBalance)
        
        do {
            try db.collection("accounts").document(accountID).setData(from: updatedAccount) { error in
                if let error = error {
                    print("Error updating account: \(error.localizedDescription)")
                } else {
                    print("Account updated successfully")
                    self.getBankAccounts()  // Actualizar la lista tras la actualización
                }
            }
        } catch {
            print("Error updating account: \(error.localizedDescription)")
        }
    }
}
