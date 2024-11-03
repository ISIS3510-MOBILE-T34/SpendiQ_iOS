//
//  SMSVerificationService.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 26/10/24.
//

import Foundation
import Alamofire
import DotEnv

class SMSVerificationService {
    private let accountSID: String
    private let authToken: String
    private let serviceSID: String

    init() {
        do {
            // Load the .env file from the bundle
            if let path = Bundle.main.path(forResource: ".env", ofType: nil) {
                try DotEnv.load(path: path)
                self.accountSID = ProcessInfo.processInfo.environment["TWILIO_ACCOUNT_SID"] ?? ""
                self.authToken = ProcessInfo.processInfo.environment["TWILIO_AUTH_TOKEN"] ?? ""
                self.serviceSID = ProcessInfo.processInfo.environment["TWILIO_SERVICE_SID"] ?? ""
            } else {
                print(".env file not found")
                self.accountSID = ""
                self.authToken = ""
                self.serviceSID = ""
            }
        } catch {
            print("Failed to load .env file: \(error)")
            self.accountSID = ""
            self.authToken = ""
            self.serviceSID = ""
        }
    }

    func sendVerificationCode(to phoneNumber: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let formattedPhoneNumber = phoneNumber.starts(with: "+") ? phoneNumber : "+\(phoneNumber)"

        let url = "https://verify.twilio.com/v2/Services/\(serviceSID)/Verifications"

        let parameters: [String: String] = [
            "To": formattedPhoneNumber,
            "Channel": "sms"
        ]

        let headers: HTTPHeaders = [
            .authorization(username: accountSID, password: authToken),
            .contentType("application/x-www-form-urlencoded")
        ]

        AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default, headers: headers)
            .validate()
            .response { response in
                switch response.result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func verifyCode(_ code: String, for phoneNumber: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let formattedPhoneNumber = phoneNumber.starts(with: "+") ? phoneNumber : "+\(phoneNumber)"

        let url = "https://verify.twilio.com/v2/Services/\(serviceSID)/VerificationCheck"

        let parameters: [String: String] = [
            "To": formattedPhoneNumber,
            "Code": code
        ]

        let headers: HTTPHeaders = [
            .authorization(username: accountSID, password: authToken),
            .contentType("application/x-www-form-urlencoded")
        ]

        AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder.default, headers: headers)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let json = value as? [String: Any],
                       let status = json["status"] as? String {
                        completion(.success(status == "approved"))
                    } else {
                        completion(.failure(URLError(.cannotParseResponse)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
