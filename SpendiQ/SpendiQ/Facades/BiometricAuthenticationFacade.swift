//
//  BiometricAuthenticationFacade.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 6/10/24.
//

import LocalAuthentication
import Combine
import FirebaseAuth

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case noCredentialsStored
    case authenticationFailed
    case systemCancel
    case firebaseError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Face ID is not available on this device"
        case .notEnrolled:
            return "Face ID is not set up on this device"
        case .noCredentialsStored:
            return "No stored credentials found. Please login with email first"
        case .authenticationFailed:
            return "Face ID authentication failed"
        case .systemCancel:
            return "Authentication was cancelled"
        case .firebaseError(let error):
            return "Firebase error: \(error.localizedDescription)"
        }
    }
}

class BiometricAuthenticationFacade {
    private let keychainService = "com.spendiq.biometric"
    private let credentialsKey = "credentials"
    
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        print("Can use biometrics: \(canEvaluate), error: \(String(describing: error))")
        return canEvaluate
    }
    
    func hasSavedCredentials() -> AnyPublisher<Bool, Never> {
        return Future { promise in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: self.keychainService,
                kSecAttrAccount as String: self.credentialsKey,
                kSecReturnData as String: true
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            print("Check saved credentials status: \(status)")
            promise(.success(status == errSecSuccess))
        }.eraseToAnyPublisher()
    }
    
    func authenticateUser() -> AnyPublisher<Bool, Error> {
        return Future { promise in
            let context = LAContext()
            let reason = "Log in to your account"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                 localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Face ID authentication error: \(error.localizedDescription)")
                        promise(.failure(error))
                        return
                    }
                    print("Face ID authentication success: \(success)")
                    promise(.success(success))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func saveBiometricCredentials(email: String, password: String) -> AnyPublisher<Bool, Error> {
        return Future { promise in
            do {
                let credentials = "\(email):\(password)".data(using: .utf8)!
                
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: self.keychainService,
                    kSecAttrAccount as String: self.credentialsKey,
                    kSecValueData as String: credentials,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                ]
                
                // Primero intentamos eliminar cualquier credencial existente
                SecItemDelete(query as CFDictionary)
                
                // Luego guardamos las nuevas credenciales
                let status = SecItemAdd(query as CFDictionary, nil)
                promise(.success(status == errSecSuccess))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func retrieveBiometricCredentials() -> AnyPublisher<(String, String)?, Error> {
        return Future { promise in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: self.keychainService,
                kSecAttrAccount as String: self.credentialsKey,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne
            ]
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            print("Retrieve credentials status: \(status)")
            
            if status == errSecSuccess,
               let data = result as? Data {
                do {
                    let decryptedString = try self.decrypt(data: data)
                    let components = decryptedString.split(separator: ":")
                    if components.count == 2 {
                        promise(.success((String(components[0]), String(components[1]))))
                    } else {
                        promise(.failure(BiometricError.noCredentialsStored))
                    }
                } catch {
                    print("Error decrypting credentials: \(error)")
                    promise(.failure(error))
                }
            } else {
                promise(.failure(BiometricError.noCredentialsStored))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Encryption Helpers
    
    private func encrypt(string: String) throws -> Data {
        guard let data = string.data(using: .utf8) else {
            throw BiometricError.authenticationFailed
        }
        
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            nil
        )
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessControl as String: access as Any,
            kSecUseAuthenticationContext as String: LAContext(),
            kSecValueData as String: data
        ]
        
        var result: AnyObject?
        let status = SecItemAdd(query as CFDictionary, &result)
        
        guard status == errSecSuccess, let encryptedData = result as? Data else {
            throw BiometricError.authenticationFailed
        }
        
        return encryptedData
    }
    
    private func decrypt(data: Data) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecValueData as String: data,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: LAContext()
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let decryptedData = result as? Data,
              let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw BiometricError.authenticationFailed
        }
        
        return decryptedString
    }
}
