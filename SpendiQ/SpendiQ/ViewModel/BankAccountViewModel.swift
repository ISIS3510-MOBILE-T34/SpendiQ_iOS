// BankAccountViewModel.swift

import FirebaseFirestore

class BankAccountViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    private let db = Firestore.firestore()
    
    func addAccount(name: String, amount: Double) {
        let newAccount = BankAccount(id: nil, name: name, amount: amount)
        
        do {
            let _ = try db.collection("accounts").addDocument(from: newAccount) { error in
                if let error = error {
                    print("Error saving account: \(error.localizedDescription)")
                } else {
                    print("Account saved successfully")
                    self.getBankAccounts()
                }
            }
        } catch {
            print("Error saving account: \(error.localizedDescription)")
        }
    }
    
    func getBankAccounts() {
        db.collection("accounts").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error retrieving accounts: \(error.localizedDescription)")
            } else {
                let accounts = querySnapshot?.documents.compactMap { document -> BankAccount? in
                    var account = try? document.data(as: BankAccount.self)
                    account?.id = document.documentID
                    return account
                }
                DispatchQueue.main.async {
                    self.accounts = accounts ?? []
                    print("Loaded accounts: \(self.accounts)")
                }
            }
        }
    }
    
    func deleteAccount(accountID: String) {
        db.collection("accounts").document(accountID).delete { error in
            if let error = error {
                print("Error deleting account: \(error.localizedDescription)")
            } else {
                print("Account deleted successfully")
                self.getBankAccounts()
            }
        }
    }
    
    func updateAccount(accountID: String, newName: String, newBalance: Double) {
        db.collection("accounts").document(accountID).updateData([
            "name": newName,
            "amount": newBalance
        ]) { error in
            if let error = error {
                print("Error updating account: \(error.localizedDescription)")
            } else {
                print("Account updated successfully")
                self.getBankAccounts()
            }
        }
    }
    
    func updateAccountBalance(accountID: String, amountChange: Double) {
        db.collection("accounts").document(accountID).getDocument { (document, error) in
            if let document = document, document.exists {
                let currentBalance = document.data()?["amount"] as? Double ?? 0.0
                let newBalance = currentBalance + amountChange
                self.db.collection("accounts").document(accountID).updateData([
                    "amount": newBalance
                ]) { error in
                    if let error = error {
                        print("Error updating account balance: \(error.localizedDescription)")
                    } else {
                        print("Account balance updated")
                        self.getBankAccounts()
                    }
                }
            }
        }
    }
}
