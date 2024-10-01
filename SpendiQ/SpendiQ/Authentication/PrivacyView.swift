//
//  PrivacyView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 1/10/24.
//

import SwiftUI

struct PrivacyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.custom("SFProDisplay-Bold", size: 24))
                    .padding(.bottom, 10)

                Text("""
                Your privacy is important to us. At SpendiQ, we collect and use your data to provide personalized financial insights. 

                - **Data Usage**: We only use your data for app functionality and never share it with third parties without your consent.
                - **Anonymization**: All data is anonymized to protect your identity.
                """)
                .font(.custom("SFProText-Regular", size: 14))
                .foregroundColor(Color(hex: "65558F"))

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Close")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "C33BA5"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .font(.custom("SFProText-Regular", size: 18))
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
        }
    }
}
