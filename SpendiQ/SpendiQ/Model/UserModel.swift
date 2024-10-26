import Foundation
import FirebaseAuth

struct User {
    var id: String
    var fullName: String
    var email: String
    var phoneNumber: String
    var birthDate: String
    var registrationDate: Date
    var verifiedEmail: Bool

    init(id: String, fullName: String, email: String, phoneNumber: String, birthDate: String, registrationDate: Date = Date(), verifiedEmail: Bool) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phoneNumber = phoneNumber
        self.birthDate = birthDate
        self.registrationDate = registrationDate
        self.verifiedEmail = verifiedEmail
    }

    init?(from firebaseUser: FirebaseAuth.User) {
        self.id = firebaseUser.uid
        self.email = firebaseUser.email ?? ""
        self.fullName = firebaseUser.displayName ?? ""
        self.phoneNumber = firebaseUser.phoneNumber ?? ""
        self.birthDate = ""
        self.registrationDate = firebaseUser.metadata.creationDate ?? Date()
        self.verifiedEmail = firebaseUser.isEmailVerified
    }
}
