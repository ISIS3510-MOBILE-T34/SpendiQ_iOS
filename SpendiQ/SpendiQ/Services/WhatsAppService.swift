// WhatsAppService.swift

import Foundation

protocol WhatsAppServiceProtocol {
    func sendVerificationCode(to phoneNumber: String, code: String, completion: @escaping (Result<Void, Error>) -> Void)
}

class WhatsAppService: WhatsAppServiceProtocol {
    
    private let apiEndpoint = "https://api.whatsapp.com/send"
    private let apiToken = "YOUR_WHATSAPP_API_TOKEN" // Securely store your API token
    
    func sendVerificationCode(to phoneNumber: String, code: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: apiEndpoint) else {
            completion(.failure(ServiceError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "to": phoneNumber,
            "type": "text",
            "text": [
                "body": "Your verification code is \(code). Please enter this code to complete your login."
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(ServiceError.invalidPayload))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Check for successful status code (e.g., 200)
            if let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode {
                completion(.success(()))
            } else {
                completion(.failure(ServiceError.serverError))
            }
        }
        
        task.resume()
    }
}

enum ServiceError: Error {
    case invalidURL
    case invalidPayload
    case serverError
}
