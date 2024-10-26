import Foundation
import FirebaseFirestore

struct Transaction: Codable, Identifiable {
    @DocumentID var id: String?
    var accountId: String
    var transactionName: String
    var amount: Int64
    var dateTime: Timestamp
    var transactionType: String
    var location: Location?
    var amountAnomaly: Bool = false
    var locationAnomaly: Bool = false
}

struct Location: Codable {
    var latitude: Double
    var longitude: Double
}
