//
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
    private var notifiedOffers: Set<String> = [] // Track notified offers

    // UserDefaults key for storing notified offer IDs
    private let notifiedOffersKey = "NotifiedOffers"

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()

        // Load notified offers from UserDefaults
        loadNotifiedOffers()

        // Start proximity timer to check every 20 seconds
        proximityTimer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(checkProximityToOffers), userInfo: nil, repeats: true)

        // Set the notification center's delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                //print("Notification permission granted.")
                
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    @objc private func checkProximityToOffers() {
        guard let currentLocation = self.location else { return }

        // Query offers
        db.collection("offers").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching offers: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            // Filter offers within 1km and not notified
            let nearbyOffers = documents.compactMap { doc -> (DocumentSnapshot, Double)? in
                guard
                    let latitude = doc.data()["latitude"] as? Double,
                    let longitude = doc.data()["longitude"] as? Double,
                    let offerId = doc.documentID as String?
                else { return nil }

                let offerLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distance = currentLocation.distance(from: offerLocation)

                if distance <= 1000 && !self.notifiedOffers.contains(offerId) {
                    return (doc, distance)
                } else {
                    return nil
                }
            }

            guard !nearbyOffers.isEmpty else { return }

            // Sort offers by distance ascending
            let sortedOffers = nearbyOffers.sorted { $0.1 < $1.1 }

            // Take top 3 nearest offers
            let topOffers = sortedOffers.prefix(3)

            // Send notifications with 5 seconds delay between each
            for (index, (offerDoc, _)) in topOffers.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 5.0) {
                    self.processOfferNotification(offerDoc)
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
            let placeName = data?["placeName"] as? String // Ensure placeName is retrieved
        else {
            print("Incomplete offer data for notification.")
            return
        }

        // Prepare notification content
        let content = UNMutableNotificationContent()
        content.title = placeName // Set the title to placeName
        content.body = offerDescription // Set the body to offerDescription
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
            // If invalid image URL, send notification without attachment
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

    private func downloadImage(from url: URL, completion: @escaping (Data?) -> Void) {
        // Simple image download
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Image download error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }

    // MARK: - UserDefaults Handling

    private func loadNotifiedOffers() {
        if let savedOffers = UserDefaults.standard.array(forKey: notifiedOffersKey) as? [String] {
            notifiedOffers = Set(savedOffers)
        }
    }

    private func saveNotifiedOffers() {
        UserDefaults.standard.set(Array(notifiedOffers), forKey: notifiedOffersKey)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
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
        // Show the notification as a banner and play a sound even when the app is in the foreground
        completionHandler([.banner, .sound])
    }

    deinit {
        proximityTimer?.invalidate()
    }
}
