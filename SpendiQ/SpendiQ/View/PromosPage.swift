import SwiftUI

struct PromosPage: View {
    @StateObject private var offerViewModel: OfferViewModel
    private var locationManager: LocationManager

    // Initialize PromosPage with LocationManager
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        _offerViewModel = StateObject(wrappedValue: OfferViewModel(locationManager: locationManager, mockData: false))
    }

    var body: some View {
        VStack {
            OfferBubbleView(viewModel: offerViewModel, locationManager: locationManager) // Pass locationManager here
                .padding()
        }
    }
}

// Preview code updated to use a mock or real instance of LocationManager
struct PromosPage_Previews: PreviewProvider {
    static var previews: some View {
        let locationManager = LocationManager()
        PromosPage(locationManager: locationManager)
    }
}
