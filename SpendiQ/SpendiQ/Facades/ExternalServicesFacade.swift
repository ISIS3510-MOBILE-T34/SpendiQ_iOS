// ExternalServicesFacade.swift

import Foundation

protocol ExternalServicesFacadeProtocol {
    func initiateTwoFactorAuthentication(for user: TwoFactorAuthModel, completion: @escaping (Result<Void, Error>) -> Void)
}

class ExternalServicesFacade: ExternalServicesFacadeProtocol {
    
    private let whatsAppService: WhatsAppServiceProtocol
    
    init(whatsAppService: WhatsAppServiceProtocol = WhatsAppService()) {
        self.whatsAppService = whatsAppService
    }
    
    func initiateTwoFactorAuthentication(for user: TwoFactorAuthModel, completion: @escaping (Result<Void, Error>) -> Void) {
        // Generate a random 6-digit verification code
        let code = String(format: "%06d", Int.random(in: 0...999999))
        
        // Update the model with the generated code
        var updatedUser = user
        updatedUser.verificationCode = code
        
        // Send the verification code via WhatsApp
        whatsAppService.sendVerificationCode(to: user.phoneNumber, code: code) { result in
            switch result {
            case .success():
                // Here, you would typically save the updatedUser model to your database
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
