//
//  UserModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

//  UserModel.swift
import Foundation
import FirebaseAuth

struct User {
    var id: String
    var fullName: String
    var email: String
    var phoneNumber: String
    var birthDate: String
    var registrationDate: Date
    
    init(id: String, fullName: String, email: String, phoneNumber: String, birthDate: String, registrationDate: Date = Date()) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.birthDate = birthDate
        self.registrationDate = registrationDate
    }
    
    init?(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.fullName = firebaseUser.displayName ?? ""
        self.phoneNumber = firebaseUser.phoneNumber ?? ""
        self.birthDate = ""
        self.registrationDate = firebaseUser.metadata.creationDate ?? Date()
    }
}
