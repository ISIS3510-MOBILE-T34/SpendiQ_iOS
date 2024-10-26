//
//  EmailVerificationView.swift
//  SpendiQ
//
//  Created by Alonso Hernandez on 25/10/24.
//

import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthenticationViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Verification Code")
                .font(.title)
            TextField("Verification Code", text: $viewModel.verificationCode)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button(action: {
                viewModel.verifyEmailCode(appState: appState)
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
