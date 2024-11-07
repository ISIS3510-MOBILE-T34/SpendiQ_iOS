//
//  BalanceViewModel.swift
//  SpendiQ
//
//  Created by Juan Salguero on 7/11/24.
//

// BalanceViewModel.swift

import Foundation
import FirebaseFirestore
import FirebaseAuth

class BalanceViewModel: ObservableObject {
    @Published var balanceData: [(date: Date, balance: Double)] = []
    private let db = Firestore.firestore()
    var selectedTimeFrame: String = "1 Day"
    
    // Computed property to get the current user's UID
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // Fetches transactions and calculates cumulative balance over time
    func fetchBalanceData(timeFrame: String) {
        self.selectedTimeFrame = timeFrame
        guard let userID = currentUserID else {
            print("No authenticated user.")
            return
        }
        
        // Define the start date based on the selected time frame
        let calendar = Calendar.current
        var startDate: Date?
        
        switch timeFrame {
        case "1 Day":
            startDate = calendar.startOfDay(for: Date())
        case "Max":
            startDate = nil // Fetch all data
        default:
            startDate = calendar.startOfDay(for: Date())
        }
        
        // Fetch accounts belonging to the current user
        db.collection("accounts")
            .whereField("user_id", isEqualTo: userID)
            .getDocuments { (accountSnapshot, error) in
                if let error = error {
                    print("Error retrieving accounts: \(error.localizedDescription)")
                } else {
                    var allTransactions: [Transaction] = []
                    let group = DispatchGroup()
                    
                    for accountDoc in accountSnapshot?.documents ?? [] {
                        let accountID = accountDoc.documentID
                        
                        group.enter()
                        var query: Query = self.db.collection("accounts").document(accountID).collection("transactions")
                        
                        // Apply date filter if startDate is set
                        if let startDate = startDate {
                            query = query.whereField("dateTime", isGreaterThanOrEqualTo: startDate)
                        }
                        
                        query.getDocuments { (transactionSnapshot, error) in
                            if let error = error {
                                print("Error retrieving transactions: \(error.localizedDescription)")
                            } else {
                                for transactionDoc in transactionSnapshot?.documents ?? [] {
                                    do {
                                        var transaction = try transactionDoc.data(as: Transaction.self)
                                        transaction.id = transactionDoc.documentID
                                        allTransactions.append(transaction)
                                    } catch {
                                        print("Error decoding transaction: \(error)")
                                    }
                                }
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        // Process transactions to calculate cumulative balance over time
                        self.processTransactions(allTransactions: allTransactions)
                    }
                }
            }
    }
    
    // Processes transactions to calculate balance over time
    private func processTransactions(allTransactions: [Transaction]) {
        if selectedTimeFrame == "1 Day" {
            // Get starting balance asynchronously
            getStartingBalance(for: Date()) { startingBalance in
                self.calculateBalanceData(allTransactions: allTransactions, startingBalance: startingBalance)
            }
        } else {
            // For "Max", start from zero
            self.calculateBalanceData(allTransactions: allTransactions, startingBalance: 0.0)
        }
    }

    private func calculateBalanceData(allTransactions: [Transaction], startingBalance: Double) {
        // Sort transactions by date
        let sortedTransactions = allTransactions.sorted(by: { $0.dateTime < $1.dateTime })
        
        var cumulativeBalance: Double = startingBalance
        var balanceData: [(date: Date, balance: Double)] = []
        
        for transaction in sortedTransactions {
            let amount = Double(transaction.amount)
            switch transaction.transactionType {
            case "Expense":
                cumulativeBalance -= amount
            case "Income":
                cumulativeBalance += amount
            default:
                break
            }
            
            // Determine the date to use based on the time frame
            let date: Date
            switch selectedTimeFrame {
            case "1 Day":
                // Use the transaction time
                date = transaction.dateTime
            case "Max":
                // Round to the day
                date = Calendar.current.startOfDay(for: transaction.dateTime)
            default:
                date = transaction.dateTime
            }
            
            balanceData.append((date: date, balance: cumulativeBalance))
        }
        
        // Update the published property
        DispatchQueue.main.async {
            self.balanceData = balanceData
        }
    }
    
    // Gets the starting balance before the current day for "1 Day" time frame
    private func getStartingBalance(for date: Date, completion: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        var cumulativeBalance: Double = 0.0
        let group = DispatchGroup()
        
        guard let userID = currentUserID else {
            print("No authenticated user.")
            completion(cumulativeBalance)
            return
        }
        
        db.collection("accounts")
            .whereField("user_id", isEqualTo: userID)
            .getDocuments { (accountSnapshot, error) in
                if let error = error {
                    print("Error retrieving accounts: \(error.localizedDescription)")
                    completion(cumulativeBalance)
                } else {
                    var allTransactions: [Transaction] = []
                    
                    for accountDoc in accountSnapshot?.documents ?? [] {
                        let accountID = accountDoc.documentID
                        
                        group.enter()
                        let query = self.db.collection("accounts").document(accountID).collection("transactions")
                            .whereField("dateTime", isLessThan: startOfDay)
                        
                        query.getDocuments { (transactionSnapshot, error) in
                            if let error = error {
                                print("Error retrieving transactions: \(error.localizedDescription)")
                            } else {
                                for transactionDoc in transactionSnapshot?.documents ?? [] {
                                    do {
                                        var transaction = try transactionDoc.data(as: Transaction.self)
                                        transaction.id = transactionDoc.documentID
                                        allTransactions.append(transaction)
                                    } catch {
                                        print("Error decoding transaction: \(error)")
                                    }
                                }
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        // Calculate cumulative balance up to the start of the day
                        for transaction in allTransactions {
                            let amount = Double(transaction.amount)
                            switch transaction.transactionType {
                            case "Expense":
                                cumulativeBalance -= amount
                            case "Income":
                                cumulativeBalance += amount
                            default:
                                break
                            }
                        }
                        completion(cumulativeBalance)
                    }
                }
            }
    }}
