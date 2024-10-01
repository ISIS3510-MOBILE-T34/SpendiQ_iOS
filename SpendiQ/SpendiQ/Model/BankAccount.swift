import Foundation
struct BankAccount: Codable, Identifiable {
    var id: String? // Esta propiedad ya existe
    var name: String
    var amount: Double
    
    // El protocolo 'Identifiable' requiere una propiedad 'id' no opcional.
    // Puedes proporcionar un valor predeterminado si 'id' es nil, pero si se espera que haya un id real en Firebase,
    // solo con 'id' es suficiente.
    var realID: String {
        id ?? UUID().uuidString
    }
}
