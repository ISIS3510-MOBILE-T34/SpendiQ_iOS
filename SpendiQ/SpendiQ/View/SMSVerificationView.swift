//
//  SMSVerificationView.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 26/10/24.
//

import SwiftUI

struct SMSVerificationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: AuthenticationViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter SMS Verification Code")
                .font(.title)
            TextField("SMS Code", text: $viewModel.smsCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .keyboardType(.numberPad)
            Button(action: {
                viewModel.verifySMSCode(appState: appState)
            }) {
                Text("Verify")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "65558F"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
}
