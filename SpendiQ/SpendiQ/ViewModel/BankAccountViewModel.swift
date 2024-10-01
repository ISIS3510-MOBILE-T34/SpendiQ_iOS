import FirebaseFirestore

class BankAccountViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    private let db = Firestore.firestore()

    // Método para agregar una nueva cuenta y guardarla en Firebase
    func addAccount(name: String, amount: Double) {
        let newAccount = BankAccount(name: name, amount: amount)
        
        do {
            let _ = try db.collection("accounts").addDocument(from: newAccount) { error in
                if let error = error {
                    print("Error saving account: \(error.localizedDescription)")
                } else {
                    print("Account saved successfully")
                    self.getBankAccounts() // Actualiza la lista después de agregar
                }
            }
        } catch {
            print("Error saving account: \(error.localizedDescription)")
        }
    }

    // Método para recuperar las cuentas existentes
    func getBankAccounts() {
        db.collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error retrieving accounts: \(error.localizedDescription)")
            } else {
                let accounts = querySnapshot?.documents.compactMap { document -> BankAccount? in
                    var account = try? document.data(as: BankAccount.self)
                    account?.id = document.documentID // Asigna el documentID a la cuenta
                    return account
                }
                DispatchQueue.main.async {
                    self.accounts = accounts ?? []
                }
            }
        }
    }

    // Método para eliminar una cuenta
    func deleteAccount(accountID: String) {
        db.collection("accounts").document(accountID).delete { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
            } else {
                print("Account deleted successfully")
                self.getBankAccounts() // Actualiza la lista después de eliminar
            }
        }
    }
}
