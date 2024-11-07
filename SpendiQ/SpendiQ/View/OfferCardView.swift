import SwiftUI

struct OfferCardView: View {
    var offer: Offer
    @ObservedObject var locationManager: LocationManager

    var body: some View {
        NavigationLink(destination: OfferDetailView(offer: offer, locationManager: locationManager)) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(offer.placeName)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                        
                        Text(offer.offerDescription)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.leading)
                        
                        Text(displayDistance(offer.distance))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                        
                        Text(offer.recommendationReason)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    
                    AsyncImage(url: URL(string: offer.shopImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        ProgressView()
                    }
                }
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
