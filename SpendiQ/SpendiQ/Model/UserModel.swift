//
//  UserModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation
import FirebaseAuth

struct User: Identifiable {
    var id: String // Firestore document ID
    var name: String
    var email: String
    var profilePicture: String // URL for the profile picture

    init(id: String, name: String, email: String, profilePicture: String) {
        self.id = id
        self.name = name
        self.email = email
        self.profilePicture = profilePicture
    }

    init?(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.name = firebaseUser.displayName ?? ""
        self.email = firebaseUser.email ?? ""
        self.profilePicture = firebaseUser.photoURL?.absoluteString ?? ""
    }
}
