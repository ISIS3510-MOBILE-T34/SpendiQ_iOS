//  LocationManager.swift
//  SpendiQ
//
//  Created by Fai on 25/09/24.
//
import Foundation
import CoreLocation
import Combine
import FirebaseFirestore
import UserNotifications

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    private var proximityTimer: Timer?
    private let db = Firestore.firestore()
    private var notifiedOffers: Set<String> = []
    private let notifiedOffersKey = "NotifiedOffers"
    
    // MARK: - Optimization 1: Dynamic Location Updates
    private var locationUpdateThreshold: CLLocationDistance {
        if let speed = manager.location?.speed, speed > 0 {
            // Adjust threshold based on user's speed: faster movement = larger threshold
            return max(50.0, min(speed * 10, 200.0))
        }
        return 50.0
    }
    
    // MARK: - Optimization 2: Batch Processing Control
    private var processingBatch = false
    private let processingQueue = DispatchQueue(label: "com.spendiq.locationprocessing", qos: .utility)
    private var pendingOffers: [(DocumentSnapshot, Double)] = []
    private var lastProcessingTime: Date?
    private let minimumProcessingInterval: TimeInterval = 30 // Minimum time between processing batches
    
    override init() {
        super.init()
        setupManager()
        setupNotifications()
        loadNotifiedOffers()
    }
    
    private func setupManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = locationUpdateThreshold
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        setupProximityTimer()
    }
    
    // MARK: - Optimization 3: Adaptive Timer
    private func setupProximityTimer() {
        proximityTimer?.invalidate()
        let interval = calculateTimerInterval()
        proximityTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkProximityToOffers()
        }
    }
    
    private func calculateTimerInterval() -> TimeInterval {
        if let speed = manager.location?.speed {
            if speed > 5.0 { // Fast movement (> 18 km/h)
                return 30.0
            } else if speed > 2.0 { // Walking speed
                return 60.0
            }
        }
        return 120.0 // Stationary or very slow movement
    }
    
    @objc private func checkProximityToOffers() {
        guard let currentLocation = self.location,
              !processingBatch,
              shouldProcessOffers() else { return }
        
        processingBatch = true
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            self.fetchAndProcessOffers(currentLocation)
        }
    }
    
    private func shouldProcessOffers() -> Bool {
        guard let lastTime = lastProcessingTime else { return true }
        return Date().timeIntervalSince(lastTime) >= minimumProcessingInterval
    }
    
    private func fetchAndProcessOffers(_ currentLocation: CLLocation) {
        db.collection("offers").getDocuments { [weak self] snapshot, error in
            guard let self = self,
                  let documents = snapshot?.documents else {
                self?.processingBatch = false
                return
            }
            
            self.processingQueue.async {
                self.processOfferDocuments(documents, currentLocation)
            }
        }
    }
    
    private func processOfferDocuments(_ documents: [QueryDocumentSnapshot], _ currentLocation: CLLocation) {
        let nearbyOffers = documents.compactMap { doc -> (DocumentSnapshot, Double)? in
            guard let latitude = doc.data()["latitude"] as? Double,
                  let longitude = doc.data()["longitude"] as? Double,
                  let offerId = doc.documentID as String? else { return nil }
            
            let offerLocation = CLLocation(latitude: latitude, longitude: longitude)
            let distance = currentLocation.distance(from: offerLocation)
            
            if distance <= 1000 && !self.isOfferNotified(offerId) {
                return (doc, distance)
            }
            return nil
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let sortedOffers = nearbyOffers.sorted { $0.1 < $1.1 }
            let topOffers = sortedOffers.prefix(3)
            
            // Process notifications with delay between each
            for (index, (offerDoc, _)) in topOffers.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 2.0) {
                    self.processOfferNotification(offerDoc)
                }
            }
            
            self.lastProcessingTime = Date()
            self.processingBatch = false
        }
    }
    
    private func processOfferNotification(_ offerDoc: DocumentSnapshot) {
        let data = offerDoc.data()
        guard let offerDescription = data?["offerDescription"] as? String,
              let shopImageURL = data?["shopImage"] as? String,
              let offerId = offerDoc.documentID as String?,
              let placeName = data?["placeName"] as? String else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = placeName
        content.body = offerDescription
        content.sound = .default
        
        if let url = URL(string: shopImageURL) {
            downloadImage(from: url) { imageData in
                if let imageData = imageData {
                    let tempDir = FileManager.default.temporaryDirectory
                    let imageURL = tempDir.appendingPathComponent("\(offerId).jpg")
                    do {
                        try imageData.write(to: imageURL)
                        let attachment = try UNNotificationAttachment(identifier: "\(offerId).jpg", url: imageURL, options: nil)
                        content.attachments = [attachment]
                    } catch {
                        print("Failed to attach image for offer \(offerId): \(error.localizedDescription)")
                    }
                }
                self.scheduleNotification(content: content, offerId: offerId)
            }
        } else {
            scheduleNotification(content: content, offerId: offerId)
        }
    }
    
    // MARK: - Location Manager Delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Update location only if it has changed significantly based on dynamic threshold
        if location == nil || newLocation.distance(from: location!) > locationUpdateThreshold {
            location = newLocation
            manager.distanceFilter = locationUpdateThreshold // Update the filter based on new speed
            setupProximityTimer() // Adjust timer based on new movement characteristics
        }
    }

    // Rest of the existing methods remain unchanged...
    // (Include all other existing methods that weren't modified)
    
    private func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Image download error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(data)
                }
            }
            dataTask.resume()
        }
    }
    
    private func scheduleNotification(content: UNMutableNotificationContent, offerId: String) {
        let request = UNNotificationRequest(identifier: offerId, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification for offer \(offerId): \(error.localizedDescription)")
            } else {
                print("Notification sent for offer \(offerId)")
                self.notifiedOffers.insert(offerId)
                self.saveNotifiedOffers()
            }
        }
    }
    
    private func loadNotifiedOffers() {
        if let savedOffers = UserDefaults.standard.array(forKey: notifiedOffersKey) as? [String] {
            notifiedOffers = Set(savedOffers)
        }
    }
    
    private func saveNotifiedOffers() {
        UserDefaults.standard.set(Array(notifiedOffers), forKey: notifiedOffersKey)
    }
    
    func isOfferNotified(_ offerID: String) -> Bool {
        return notifiedOffers.contains(offerID)
    }
    
    private func setupNotifications() {
        // Set the notification center's delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        if let clError = error as? CLError, clError.code == .denied {
            NotificationCenter.default.post(name: NSNotification.Name("LocationAccessDenied"), object: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location access denied.")
            NotificationCenter.default.post(name: NSNotification.Name("LocationAccessDenied"), object: nil)
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    deinit {
        proximityTimer?.invalidate()
    }
}
