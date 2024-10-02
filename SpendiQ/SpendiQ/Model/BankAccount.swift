import Foundation

struct BankAccount: Codable, Identifiable, Equatable {
    var id: String? 
    var name: String
    var amount: Double
}
