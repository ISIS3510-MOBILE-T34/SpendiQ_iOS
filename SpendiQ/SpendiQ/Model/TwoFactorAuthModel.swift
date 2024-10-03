// TwoFactorAuthModel.swift

import Foundation

struct TwoFactorAuthModel {
    let userId: String
    let phoneNumber: String
    var verificationCode: String?
    var isVerified: Bool = false
    let timestamp: Date
}
