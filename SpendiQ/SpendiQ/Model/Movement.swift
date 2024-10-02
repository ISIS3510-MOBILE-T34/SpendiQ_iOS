import Foundation

struct Movement: Identifiable, Codable {
    var id: String?
    var movementName: String
    var accountID: String // ID de la cuenta asociada
    var movementTime: Date
    var movementAmount: Double
    var movementEmoji: String
    var isExpense: Bool
    
    init(id: String? = nil, movementName: String, accountID: String, movementTime: Date, movementAmount: Double, movementEmoji: String, isExpense: Bool) {
        self.id = id
        self.movementName = movementName
        self.accountID = accountID
        self.movementTime = movementTime
        self.movementAmount = movementAmount
        self.movementEmoji = movementEmoji
        self.isExpense = isExpense
    }
}
