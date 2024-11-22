//
//  FirestoreManager.swift
//  SpendiQ
//
//  Created by Juan Salguero on 15/11/24.
//

import Foundation
import FirebaseFirestore

final class FirestoreManager {
    
    // Propiedad estática para acceder a la instancia compartida
    static let shared = FirestoreManager()
    
    // Propiedad de Firestore
    let db: Firestore
    
    // Inicializador privado para evitar instanciación externa
    private init() {
        db = Firestore.firestore()
    }
}
