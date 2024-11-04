// BankAccountViewModel.swift

import FirebaseFirestore
import FirebaseAuth

class BankAccountViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    private let db = Firestore.firestore()
    
    // Adds an account to firebase collection ("userID/accounts")
    func addAccount(name: String, amount: Double) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }

        let newAccount = BankAccount(id: nil, name: name, amount: amount)

        do {
            let _ = try db.collection("users").document(userId).collection("accounts").addDocument(from: newAccount) { error in
                if let error = error {
                    print("Error al guardar la cuenta: \(error.localizedDescription)")
                } else {
                    print("Cuenta guardada exitosamente")
                    self.getBankAccounts()
                }
            }
        } catch {
            print("Error al guardar la cuenta: \(error.localizedDescription)")
        }
    }
    
    // gets all accounts from ("userID/accounts")
    func getBankAccounts() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }

        db.collection("users").document(userId).collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error al recuperar las cuentas: \(error.localizedDescription)")
            } else {
                let accounts = querySnapshot?.documents.compactMap { document -> BankAccount? in
                    var account = try? document.data(as: BankAccount.self)
                    account?.id = document.documentID
                    return account
                }
                DispatchQueue.main.async {
                    self.accounts = accounts ?? []
                    print("Cuentas cargadas: \(self.accounts)")
                }
            }
        }
    }
    
    // delete a given account("userID/accounts/accountID")
    func deleteAccount(accountID: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }

        db.collection("users").document(userId).collection("accounts").document(accountID).delete { error in
            if let error = error {
                print("Error al eliminar la cuenta: \(error.localizedDescription)")
            } else {
                print("Cuenta eliminada exitosamente")
                self.getBankAccounts()
            }
        }
    }
    
    // update a given account("userID/accounts/accountID")
    func updateAccount(accountID: String, newName: String, newBalance: Double) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }

        db.collection("users").document(userId).collection("accounts").document(accountID).updateData([
            "name": newName,
            "amount": newBalance
        ]) { error in
            if let error = error {
                print("Error al actualizar la cuenta: \(error.localizedDescription)")
            } else {
                print("Cuenta actualizada exitosamente")
                self.getBankAccounts()
            }
        }
    }
    
    // updates de balance of a given account("userID/accounts/accountID")
    func updateAccountBalance(accountID: String, amountChange: Double) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado")
            return
        }

        db.collection("users").document(userId).collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let currentBalance = document.data()?["amount"] as? Double ?? 0.0
                let newBalance = currentBalance + amountChange
                self.db.collection("users").document(userId).collection("accounts").document(accountID).updateData([
                    "amount": newBalance
                ]) { error in
                    if let error = error {
                        print("Error al actualizar el saldo de la cuenta: \(error.localizedDescription)")
                    } else {
                        print("Saldo de la cuenta actualizado")
                        self.getBankAccounts()
                    }
                }
            }
        }
    }
}
