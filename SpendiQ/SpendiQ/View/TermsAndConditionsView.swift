//
//  TermsAndConditionsView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 1/10/24.
//
import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms & Conditions")
                    .font(.custom("SFProDisplay-Bold", size: 24))
                    .padding(.bottom, 20)
                
                Text("""
                Welcome to SpendiQ, your ultimate financial management companion designed specifically for university students. By using SpendiQ, you agree to the following terms and conditions:

                1. **Data Collection**: SpendiQ accesses your SMS messages to gather data about your financial transactions. This helps us provide accurate insights into your income and expenses, allowing us to offer personalized recommendations.

                2. **Privacy**: Your privacy is our priority. The data collected will be anonymized and will never be shared with third parties without your consent.

                3. **Recommendations**: Based on your spending patterns, SpendiQ may suggest areas where you can save money, such as highlighting locations where you spend the most.

                4. **Freemium Model**: SpendiQ offers both free and premium features. While the free version provides essential financial tracking, premium features will enhance your experience with more detailed analytics and suggestions.

                5. **User Responsibility**: As a user, you are responsible for ensuring the accuracy of the information you provide. SpendiQ is not liable for any financial decisions you make based on the app's recommendations.

                6. **Changes to Terms**: We may update these terms and conditions periodically. You will be notified of any significant changes within the app.

                Thank you for choosing SpendiQ to manage your finances!
                """)
                .font(.custom("SFProText-Regular", size: 14))
                .foregroundColor(Color(hex: "65558F"))
                
                Button(action: {
                    // Acción para cerrar la vista de Términos y Condiciones
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
