//
//  HelpView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 1/10/24.
//
import SwiftUI

struct HelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help")
                    .font(.custom("SFProDisplay-Bold", size: 24))
                    .padding(.bottom, 10)

                Text("""
                If you have any questions or need assistance with SpendiQ, please refer to the following:

                - **User Guide**: Access the user guide within the app for detailed instructions.
                - **Contact Us**: For direct support, email us at support@spendiQ.com.
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
