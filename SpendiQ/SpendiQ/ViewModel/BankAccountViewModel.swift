// BankAccountViewModel.swift

import FirebaseFirestore
import FirebaseAuth

class BankAccountViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    private let db = FirestoreManager.shared.db
    
    // Computed property to get the current user's UID
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // Adds a new account for the current user
    func addAccount(name: String, amount: Double) {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        let newAccount = BankAccount(id: nil, name: name, amount: amount, user_id: userID)
        
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
    
    // Fetches accounts belonging to the current user
    func getBankAccounts() {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        db.collection("accounts")
            .whereField("user_id", isEqualTo: userID)
            .getDocuments { (querySnapshot, error) in
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
    
    // Deletes an account if it belongs to the current user
    func deleteAccount(accountID: String) {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        let accountRef = db.collection("accounts").document(accountID)
        
        accountRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let accountUserID = document.data()?["user_id"] as? String
                if accountUserID == userID {
                    accountRef.delete { error in
                        if let error = error {
                            print("Error deleting account: \(error.localizedDescription)")
                        } else {
                            print("Account deleted successfully")
                            self.getBankAccounts()
                        }
                    }
                } else {
                    print("Permission denied: You can only delete your own accounts.")
                }
            } else {
                print("Account does not exist.")
            }
        }
    }
    
    // Updates an account's name and balance if it belongs to the current user
    func updateAccount(accountID: String, newName: String, newBalance: Double) {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        let accountRef = db.collection("accounts").document(accountID)
        
        accountRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let accountUserID = document.data()?["user_id"] as? String
                if accountUserID == userID {
                    accountRef.updateData([
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
                } else {
                    print("Permission denied: You can only update your own accounts.")
                }
            } else {
                print("Account does not exist.")
            }
        }
    }
    
    // Updates the account balance if it belongs to the current user
    func updateAccountBalance(accountID: String, amountChange: Double) {
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        let accountRef = db.collection("accounts").document(accountID)
        
        accountRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let accountUserID = document.data()?["user_id"] as? String
                if accountUserID == userID {
                    let currentBalance = document.data()?["amount"] as? Double ?? 0.0
                    let newBalance = currentBalance + amountChange
                    accountRef.updateData([
                        "amount": newBalance
                    ]) { error in
                        if let error = error {
                            print("Error updating account balance: \(error.localizedDescription)")
                        } else {
                            print("Account balance updated")
                            self.getBankAccounts()
                        }
                    }
                } else {
                    print("Permission denied: You can only update your own accounts.")
                }
            } else {
                print("Account does not exist.")
            }
        }
    }
}
