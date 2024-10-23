import Foundation

struct Transaction: Codable, Identifiable {
    var id: String?
    var transactionName: String
    var amount: Float
    var fromAccountID: String
    var toAccountID: String?
    var transactionType: String
    var dateTime: Date
    var latitude: Double?
    var longitude: Double?
    var shopID: String?
}
