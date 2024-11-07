import Foundation

struct Location: Codable {
    var latitude: Double
    var longitude: Double
}

struct Transaction: Codable, Identifiable {
    var id: String?
    var accountID: String
    var transactionName: String
    var amount: Float
    var amountAnomaly: Bool
    var automatic: Bool
    var dateTime: Date
    var location: Location
    var locationAnomaly: Bool
    var transactionType: String
}
