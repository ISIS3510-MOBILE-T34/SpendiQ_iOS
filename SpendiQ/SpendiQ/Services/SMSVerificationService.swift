//
//  SMSVerificationService.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 26/10/24.
//

import Foundation
import Alamofire

class SMSVerificationService {
    private let accountSID = "ACcff0644da0562e4093e8bd246de6dadd"
    private let authToken = "f9f501d5a0487e1036ea82b4cef62375"
    private let serviceSID = "VA89d3368a2ff79675dde69ccd98e0c260"

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
