//
//  EmailVerificationService.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 25/10/24.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

protocol EmailVerificationServiceProtocol {
    func sendVerificationCode(to email: String) -> AnyPublisher<Void, Error>
    func verifyCode(_ code: String, for email: String) -> AnyPublisher<Bool, Error>
}

class EmailVerificationService: EmailVerificationServiceProtocol {
    private let db = Firestore.firestore()
    private let backendURL = "http://127.0.0.1:5000"

    func sendVerificationCode(to email: String) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                let verificationCode = String(format: "%06d", Int.random(in: 0...999999))

                self?.db.collection("emailVerifications").document(email).setData([
                    "code": verificationCode,
                    "timestamp": Timestamp(date: Date())
                ]) { error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }

                    self?.sendEmail(to: email, code: verificationCode) { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            promise(.success(()))
                        }
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func verifyCode(_ code: String, for email: String) -> AnyPublisher<Bool, Error> {
        Deferred {
            Future { [weak self] promise in
                self?.db.collection("emailVerifications").document(email).getDocument { document, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let document = document, document.exists,
                          let data = document.data(),
                          let storedCode = data["code"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        promise(.success(false))
                        return
                    }
                    
                    let codeExpiryDuration: TimeInterval = 15 * 60
                    if Date().timeIntervalSince(timestamp.dateValue()) > codeExpiryDuration {
                        promise(.success(false))
                        return
                    }
                    
                    if code == storedCode {
                        self?.db.collection("emailVerifications").document(email).delete()
                        promise(.success(true))
                    } else {
                        promise(.success(false))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    private func sendEmail(to email: String, code: String, completion: @escaping (Error?) -> Void) {
        guard let url = URL(string: "\(backendURL)/send_verification_email") else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        let payload: [String: Any] = [
            "email": email,
            "code": code
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = jsonData
        } catch {
            completion(error)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  200...299 ~= httpResponse.statusCode else {
                completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to send email"]))
                return
            }

            completion(nil)
        }
        task.resume()
    }
}
