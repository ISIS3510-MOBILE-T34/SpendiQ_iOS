import SwiftUI
import MapKit

struct OfferDetailView: View {
    var offer: Offer
    
    @EnvironmentObject var viewModel: UserViewModel
    @EnvironmentObject var locationManager: LocationManager
    
    @State private var region: MKCoordinateRegion
    @State private var annotationItems: [MapAnnotationItem] = []
    
    init(offer: Offer) {
        self.offer = offer
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // SPECIAL OFFERS Title
                Text("Special Offers Near You")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 15)
                    .padding(.bottom, 15)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                HStack {
                    // Shop Image with only ProgressView as placeholder
                    AsyncImage(url: URL(string: offer.shopImage)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure(_):
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 80)
                        @unknown default:
                            EmptyView()
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
                
                // Map with Markers
                Map(coordinateRegion: $region, annotationItems: annotationItems) { annotation in
                    MapAnnotation(coordinate: annotation.coordinate) {
                        // Customize the annotation view based on the annotation type
                        if annotation.annotationType == .shop {
                            // Shop annotation
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.title)
                        } else if annotation.annotationType == .user {
                            // User annotation
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
        .navigationBarTitle("Offer Details", displayMode: .inline)
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
        // Remove existing user annotation if any
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
        
        // Add some padding to the map rect
        let paddedRect = unionRect.insetBy(dx: -unionRect.size.width * 0.5, dy: -unionRect.size.height * 0.5)
        
        // Convert the map rect to a coordinate region
        let region = MKCoordinateRegion(paddedRect)
        self.region = region
    }
}
