// Developed by Alonso Hernandez

import SwiftUI

struct OfferCardView: View {
    var offer: Offer
    @ObservedObject var locationManager: LocationManager
    @State private var image: UIImage? // State for the loaded image

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
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        ProgressView() // Show progress while loading the image
                            .frame(width: 50, height: 50)
                            .onAppear {
                                loadImage()
                            }
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
    }
    
    private func loadImage() {
        let imageKey = offer.id // Use offer ID as the unique key
        
        // Try to load the image from cache first
        if let cachedImage = ImageCacheManager.shared.loadImage(forKey: imageKey!) {
            self.image = cachedImage
        } else {
            // Fetch the image from the internet
            guard let url = URL(string: offer.shopImage) else { return }
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let downloadedImage = UIImage(data: data) else { return }
                
                DispatchQueue.main.async {
                    self.image = downloadedImage
                    ImageCacheManager.shared.saveImage(downloadedImage, forKey: imageKey!)
                }
            }.resume()
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
