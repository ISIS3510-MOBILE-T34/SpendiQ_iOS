//import Foundation
//
//struct Transaction: Codable, Identifiable {
//    var id: String?
//    var transactionName: String
//    var amount: Float
//    var fromAccountID: String
//    var toAccountID: String?
//    var transactionType: String
//    var dateTime: Date
//    var latitude: Double?
//    var longitude: Double?
//    var shopID: String?
//}

import Foundation
import FirebaseFirestore
import CoreLocation

struct Transaction: Codable, Identifiable {
    @DocumentID var id: String?
    var transactionName: String
    var amount: Float // Cambiado a Double para precisión financiera
    var fromAccountID: String
    var toAccountID: String?
    var transactionType: String
    var dateTime: Date
    var latitude: Double?
    var longitude: Double?
    var shopID: String? // Asociado a la tienda donde se realizó la compra
}
