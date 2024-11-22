// BankAccountViewModel.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData
import SwiftUI

class BankAccountViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    private let db = FirestoreManager.shared.db
    private let context = PersistenceController.shared.container.viewContext

    // Computed property to get the current user's UID
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }

    init() {
        // Load accounts from cache on initialization
        loadCachedAccounts()
        // Listen for changes in Firebase
        getBankAccounts()
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
                    // Update cache
                    self.saveAccountToCache(account: newAccount)
                    // Refresh accounts
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
            .addSnapshotListener { (querySnapshot, error) in
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
                        self.saveAccountsToCache()
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
                            // Update cache
                            self.deleteAccountFromCache(accountID: accountID)
                            // Refresh accounts
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
                            // Update cache
                            self.updateAccountInCache(accountID: accountID, newName: newName, newBalance: newBalance)
                            // Refresh accounts
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
                            // Update cache
                            self.updateAccountBalanceInCache(accountID: accountID, newBalance: newBalance)
                            // Refresh accounts
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

    // MARK: - Caching Methods

    private func loadCachedAccounts() {
        let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        do {
            let accountEntities = try context.fetch(fetchRequest)
            let cachedAccounts = accountEntities.map { entity -> BankAccount in
                return BankAccount(
                    id: entity.id,
                    name: entity.name ?? "",
                    amount: entity.amount,
                    user_id: entity.user_id ?? ""
                )
            }
            self.accounts = cachedAccounts
        } catch {
            print("Error fetching accounts from cache: \(error.localizedDescription)")
        }
    }

    private func saveAccountsToCache() {
        // Remove existing cached accounts
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = AccountEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Error deleting old accounts from cache: \(error.localizedDescription)")
        }

        // Save new accounts
        for account in accounts {
            let accountEntity = AccountEntity(context: context)
            accountEntity.id = account.id
            accountEntity.name = account.name
            accountEntity.amount = account.amount
            accountEntity.user_id = account.user_id
        }

        saveContext()
    }

    private func saveAccountToCache(account: BankAccount) {
        let accountEntity = AccountEntity(context: context)
        accountEntity.id = account.id
        accountEntity.name = account.name
        accountEntity.amount = account.amount
        accountEntity.user_id = account.user_id
        saveContext()
    }

    private func deleteAccountFromCache(accountID: String) {
        let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", accountID)
        do {
            let accountEntities = try context.fetch(fetchRequest)
            for entity in accountEntities {
                context.delete(entity)
            }
            saveContext()
        } catch {
            print("Error deleting account from cache: \(error.localizedDescription)")
        }
    }

    private func updateAccountInCache(accountID: String, newName: String, newBalance: Double) {
        let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", accountID)
        do {
            let accountEntities = try context.fetch(fetchRequest)
            if let entity = accountEntities.first {
                entity.name = newName
                entity.amount = newBalance
                saveContext()
            }
        } catch {
            print("Error updating account in cache: \(error.localizedDescription)")
        }
    }

    private func updateAccountBalanceInCache(accountID: String, newBalance: Double) {
        let fetchRequest: NSFetchRequest<AccountEntity> = AccountEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", accountID)
        do {
            let accountEntities = try context.fetch(fetchRequest)
            if let entity = accountEntities.first {
                entity.amount = newBalance
                saveContext()
            }
        } catch {
            print("Error updating account balance in cache: \(error.localizedDescription)")
        }
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}
