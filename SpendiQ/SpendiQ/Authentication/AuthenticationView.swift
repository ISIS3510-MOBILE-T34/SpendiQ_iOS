//
//  AuthenticationView.swift
//  SpendiQ
//
//  Created by Daniel Clavijo on 30/09/24.
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var showSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FFFFFF").edgesIgnoringSafeArea(.all)
                
                // Background rhombuses
                GeometryReader { geometry in
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        path.move(to: CGPoint(x: -width * 0.5, y: height * 1.4))
                        path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.9))
                        path.addLine(to: CGPoint(x: width * 0.0, y: height * 0.5))
                        path.addLine(to: CGPoint(x: -width * 1.0, y: height * 1.9))
                        path.closeSubpath()
                    }
                    .stroke(Color(hex: "C33BA5"), lineWidth: 5)
                    
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        path.move(to: CGPoint(x: width * 0.2, y: height * 2.0))
                        path.addLine(to: CGPoint(x: width * 0.9, y: height * 1.0))
                        path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.55))
                        path.addLine(to: CGPoint(x: -width * 0.9, y: height * 1.0))
                        path.closeSubpath()
                    }
                    .stroke(Color(hex: "B3CB54"), lineWidth: 5)
                }
                
                VStack {
                    Spacer()
                    
                    Text("SpendiQ")
                        .font(.custom("SFProDisplay-Bold", size: 74))
                        .fontWeight(.bold)
                        .padding(.bottom, 100)
                    
                    VStack(spacing: 20) {
                        NavigationLink(destination: LoginView()) {
                            Text("Log In")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "65558F"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.custom("SFProText-Regular", size: 18))
                        }
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "65558F"))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.custom("SFProText-Regular", size: 18))
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
