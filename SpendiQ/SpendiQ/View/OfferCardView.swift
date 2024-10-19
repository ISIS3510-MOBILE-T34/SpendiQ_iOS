//
//  OfferCardView.swift
//  SpendiQ
//
//  Created by Fai on 18/10/24.
//

import SwiftUI

struct OfferCardView: View {
    var offer: Offer
    
    var body: some View {
        NavigationLink(destination: OfferDetailView(offer: offer)) {
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(offer.placeName) // Updated to use placeName
                            .font(.headline)
                        
                        // Display distance in meters or kilometers
                        Text(displayDistance(offer.distance))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(offer.offerDescription) // Short description of the offer
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text(offer.recommendationReason) // Reason why the offer is recommended
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    AsyncImage(url: URL(string: offer.shopImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        ProgressView() // Show a placeholder (spinner) while loading
                    }
                }
                
                Text("Recommended: \(offer.recommendationReason)") // Recommendation reason
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
    
    // Helper function to format distance
    func displayDistance(_ distance: Int) -> String {
        if distance < 1000 {
            return "\(distance)m"
        } else {
            let km = Double(distance) / 1000.0
            return String(format: "%.1fkm", km)
        }
    }
}
