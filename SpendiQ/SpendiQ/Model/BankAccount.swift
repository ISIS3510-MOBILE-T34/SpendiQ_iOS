import Foundation

struct BankAccount: Codable, Identifiable, Equatable {
    var id: String? 
    var name: String
    var amount: Double
    var user_id: String
}
