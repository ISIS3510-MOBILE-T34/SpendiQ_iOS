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
    private var notifiedOffers: Set<String> = [] // Sprint 3 - Alonso Local Storage: Track notified offers

    // UserDefaults key for storing notified offer IDs - Local Storage: Sprint 3 Alonso
    private let notifiedOffersKey = "NotifiedOffers"
    
    // Minimum distance (in meters) before updating location to reduce re-renders
    private let locationUpdateThreshold: CLLocationDistance = 50.0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = locationUpdateThreshold // Set distance filter
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()

        // Load notified offers from UserDefaults
        loadNotifiedOffers()

        // Start proximity timer to check every 60 seconds
        proximityTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(checkProximityToOffers), userInfo: nil, repeats: true)

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

    @objc private func checkProximityToOffers() {
        guard let currentLocation = self.location else { return }

        // Sprint 3 - Alonso: Added a background thread for database querying using DispatchQueue.global.
        // This ensures the database fetch operation doesn't block the main thread and improves app responsiveness.
        db.collection("offers").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching offers: \(error.localizedDescription)")
                return
            }
            
            // Sprint 3 - Alonso: Process the data on a global background thread for better performance.
            DispatchQueue.global(qos: .userInitiated).async {
                guard let documents = snapshot?.documents else { return }

                let nearbyOffers = documents.compactMap { doc -> (DocumentSnapshot, Double)? in
                    guard
                        let latitude = doc.data()["latitude"] as? Double,
                        let longitude = doc.data()["longitude"] as? Double,
                        let offerId = doc.documentID as String?
                    else { return nil }

                    let offerLocation = CLLocation(latitude: latitude, longitude: longitude)
                    let distance = self.location?.distance(from: offerLocation) ?? .greatestFiniteMagnitude

                    // Sprint 3 - Alonso Local Storage: Skip already-notified offers using isOfferNotified
                    if distance <= 1000 && !self.isOfferNotified(offerId) {
                        return (doc, distance)
                    } else {
                        return nil
                    }
                }

                // Sprint 3 - Alonso: Switch back to the main thread for UI-related tasks such as sending notifications.
                DispatchQueue.main.async {
                    guard !nearbyOffers.isEmpty else { return }

                    let sortedOffers = nearbyOffers.sorted { $0.1 < $1.1 }
                    let topOffers = sortedOffers.prefix(3)

                    for (index, (offerDoc, _)) in topOffers.enumerated() {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 5.0) {
                            let offerId = offerDoc.documentID
                            self.processOfferNotification(offerDoc)
                            
                            // Sprint 3 - Alonso: Mark the offer as notified
                            self.addNotifiedOffer(offerId)
                        }
                    }
                }
            }
        }
    }


    private func processOfferNotification(_ offerDoc: DocumentSnapshot) {
        let data = offerDoc.data()
        guard
            let offerDescription = data?["offerDescription"] as? String,
            let shopImageURL = data?["shopImage"] as? String,
            let offerId = offerDoc.documentID as String?,
            let placeName = data?["placeName"] as? String
        else {
            print("Incomplete offer data for notification.")
            return
        }

        // Prepare notification content
        let content = UNMutableNotificationContent()
        content.title = placeName
        content.body = offerDescription
        content.sound = .default

        // Attach shop image if available
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
                } else {
                    print("Failed to download image for offer \(offerId).")
                }

               self.scheduleNotification(content: content, offerId: offerId)
            }
        } else {
            scheduleNotification(content: content, offerId: offerId)
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

    // Sprint 3 - Alonso: Using a background thread for downloading images using URLSession. These images are the one used in the Offers notification to the users.
    // Sprint 3 - Alonso: This offloads image download tasks from the main thread, which ensures smooth UI performance.
    private func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        DispatchQueue.global(qos: .utility).async { // .global: background thread with quality of service set for utility
            let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Image download error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                // Sprint 3: Return the downloaded image data back to the main thread to update UI-related elements.
                DispatchQueue.main.async {
                    completion(data)
                }
            }

            dataTask.resume()
        }
    }

    // MARK: - UserDefaults Handling

    // Sprint 3 - Alonso: Load notified offers from local storage
    private func loadNotifiedOffers() {
        if let savedOffers = UserDefaults.standard.array(forKey: notifiedOffersKey) as? [String] {
            notifiedOffers = Set(savedOffers)
            print("Sprint 3 - Alonso: Loaded notified offers from local storage: \(notifiedOffers)")
        } else {
            print("Sprint 3 - Alonso: No notified offers found in local storage.")
        }
    }
    
    // Sprint 3 - Alonso: Save notified offers to local storage
    private func saveNotifiedOffers() {
        UserDefaults.standard.set(Array(notifiedOffers), forKey: notifiedOffersKey)
        print("Sprint 3 - Alonso: Saved notified offers to local storage: \(notifiedOffers)")
    }
    
    // Sprint 3 - Alonso: Add a new notified offer
    func addNotifiedOffer(_ offerID: String) {
        if !notifiedOffers.contains(offerID) {
            notifiedOffers.insert(offerID)
            saveNotifiedOffers()
            print("Sprint 3 - Alonso: Added offer \(offerID) to notified offers.")
        } else {
            print("Sprint 3 - Alonso: Offer \(offerID) already exists in notified offers.")
        }
    }

    // Sprint 3 - Alonso: Check if an offer has already been notified
    func isOfferNotified(_ offerID: String) -> Bool {
        let isNotified = notifiedOffers.contains(offerID)
        print("Sprint 3 - Alonso: Offer \(offerID) notified status: \(isNotified)")
        return isNotified
    }


    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        // Update location only if it has changed significantly
        if location == nil || newLocation.distance(from: location!) > locationUpdateThreshold {
            location = newLocation
        }
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

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    deinit {
        proximityTimer?.invalidate()
    }
}
