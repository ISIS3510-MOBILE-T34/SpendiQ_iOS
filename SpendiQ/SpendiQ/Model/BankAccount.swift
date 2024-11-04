import Foundation
import FirebaseFirestore

struct BankAccount: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var name: String
    var amount: Double
}
