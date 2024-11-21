// Developed by Alonso Hernanez

import SwiftUI
import MapKit

struct OfferDetailView: View {
    var offer: Offer
    @EnvironmentObject var viewModel: UserViewModel
    @ObservedObject var locationManager: LocationManager
    @State private var region: MKCoordinateRegion
    @State private var annotationItems: [MapAnnotationItem] = []
    @State private var image: UIImage?
    @ObservedObject private var reachability = ReachabilityManager.shared // Singleton for network monitoring

    init(offer: Offer, locationManager: LocationManager) {
        self.offer = offer
        self.locationManager = locationManager
        
        // Initialize region based on offer's location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: offer.latitude, longitude: offer.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
        
        // Initialize annotations with the shop
        let shopAnnotation = MapAnnotationItem(
            coordinate: CLLocationCoordinate2D(latitude: offer.latitude, longitude: offer.longitude),
            annotationType: .shop
        )
        _annotationItems = State(initialValue: [shopAnnotation])
    }
    
    var body: some View {
        VStack {
            // Offline Note
            if !reachability.isConnected {
                Text("You are offline and may not have the most updated information.")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.bottom, 10)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Special Offers Near You")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 15)
                        .padding(.bottom, 15)
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack {
                        // Shop Image with ImageCacheManager
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            ProgressView()
                                .frame(width: 80, height: 80)
                                .onAppear {
                                    loadImage()
                                }
                        }

                        // Shop Name and Distance
                        VStack(alignment: .leading, spacing: 4) {
                            Text(offer.placeName)
                                .font(.headline)
                            
                            Text(displayDistance(offer.distance))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(offer.offerDescription)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.bottom, 10)
                    
                    // Map with Annotations
                    Map(coordinateRegion: $region, annotationItems: annotationItems) { annotation in
                        MapAnnotation(coordinate: annotation.coordinate) {
                            if annotation.annotationType == .shop {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title)
                            } else if annotation.annotationType == .user {
                                Image(systemName: "location.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title)
                            }
                        }
                    }
                    .frame(height: 300)
                    .cornerRadius(15)
                    .padding(.bottom, 20)
                    .onAppear {
                        if let userLocation = locationManager.location {
                            addUserAnnotation(userLocation.coordinate)
                            updateRegion()
                        }
                    }
                    .onReceive(locationManager.$location) { userLocation in
                        if let userLocation = userLocation {
                            addUserAnnotation(userLocation.coordinate)
                            updateRegion()
                        }
                    }

                    // Sales Description
                    Text("Sales")
                        .font(.headline)
                        .padding(.bottom, 5)

                    Text(offer.offerDescription)
                        .padding(.bottom, 10)
                    
                    // Recommendation Reason
                    Text("This Sale is special for you: \(offer.recommendationReason)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitle("Offer Details", displayMode: .inline)
    }

    private func loadImage() {
        let imageKey = offer.id
        
        // Sprint 3: Load from cache if available
        if let cachedImage = ImageCacheManager.shared.loadImage(forKey: imageKey!) {
            self.image = cachedImage
        } else {
            // Download and cache the image
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
            return "\(distance)m away"
        } else {
            let km = Double(distance) / 1000.0
            return String(format: "%.1fkm away", km)
        }
    }

    // Annotation Model
    struct MapAnnotationItem: Identifiable {
        let id = UUID()
        var coordinate: CLLocationCoordinate2D
        var annotationType: AnnotationType
        
        enum AnnotationType {
            case shop
            case user
        }
    }

    func addUserAnnotation(_ coordinate: CLLocationCoordinate2D) {
        let userAnnotation = MapAnnotationItem(
            coordinate: coordinate,
            annotationType: .user
        )
        annotationItems.removeAll { $0.annotationType == .user }
        annotationItems.append(userAnnotation)
    }

    func updateRegion() {
        guard let userAnnotation = annotationItems.first(where: { $0.annotationType == .user }) else { return }
        guard let shopAnnotation = annotationItems.first(where: { $0.annotationType == .shop }) else { return }

        let userPoint = MKMapPoint(userAnnotation.coordinate)
        let shopPoint = MKMapPoint(shopAnnotation.coordinate)

        let mapRectUser = MKMapRect(origin: userPoint, size: MKMapSize(width: 0, height: 0))
        let mapRectShop = MKMapRect(origin: shopPoint, size: MKMapSize(width: 0, height: 0))

        let unionRect = mapRectUser.union(mapRectShop)
        let paddedRect = unionRect.insetBy(dx: -unionRect.size.width * 0.5, dy: -unionRect.size.height * 0.5)
        let region = MKCoordinateRegion(paddedRect)
        self.region = region
    }
}
