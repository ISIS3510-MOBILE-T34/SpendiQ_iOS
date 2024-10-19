//
//  UserModel.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//

import Foundation

struct User: Identifiable {
    var id: String // Firestore document ID
    var name: String
    var profilePicture: String // URL for the profile picture
}
