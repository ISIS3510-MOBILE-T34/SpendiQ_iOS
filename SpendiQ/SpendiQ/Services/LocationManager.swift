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

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    private var timer: Timer?
    private let db = Firestore.firestore()
    private var notifiedShops: Set<String> = [] // Keep track of shops already notified

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation

        // Request location permissions
        manager.requestWhenInUseAuthorization()
        // For always-on location access, you can use:
        // manager.requestAlwaysAuthorization()

        manager.startUpdatingLocation()

        // Start a timer to check proximity to shops every 5 seconds
        timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(checkProximityToShops), userInfo: nil, repeats: true)

        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    @objc func checkProximityToShops() {
        guard let currentLocation = self.location else {
            return
        }

        // Print user's latitude and longitude every 5 seconds for debugging
        print("User's current location: latitude \(currentLocation.coordinate.latitude), longitude \(currentLocation.coordinate.longitude)")

        // Fetch shops from Firestore
        let db = Firestore.firestore()
        db.collection("shops").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching shops: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            for doc in documents {
                let data = doc.data()
                guard
                    let latitude = data["latitude"] as? Double,
                    let longitude = data["longitude"] as? Double,
                    let shopName = data["name"] as? String,
                    let shopId = doc.documentID as String?
                else { continue }

                let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distanceInMeters = currentLocation.distance(from: shopLocation)

                // Check if within 1 km
                if distanceInMeters <= 1000 {
                    self?.checkShopHasOffers(shopId: shopId) { hasOffers in
                        if hasOffers {
                            // Send notification if not already sent
                            if !(self?.notifiedShops.contains(shopId) ?? false) {
                                self?.sendNotificationForShop(shopId: shopId, shopName: shopName)
                                self?.notifiedShops.insert(shopId)
                            }
                        }
                    }
                }
            }
        }

        // Post a notification that location has been updated
        NotificationCenter.default.post(name: NSNotification.Name("UserLocationUpdated"), object: nil, userInfo: ["location": currentLocation])
    }

    func checkShopHasOffers(shopId: String, completion: @escaping (Bool) -> Void) {
        db.collection("offers").whereField("shopReference", isEqualTo: "shops/\(shopId)").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching offers: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(!(snapshot?.documents.isEmpty ?? true))
        }
    }

    func sendNotificationForShop(shopId: String, shopName: String) {
        let content = UNMutableNotificationContent()
        content.title = "You are near \(shopName)"
        content.body = "Click here to see the special sales they have"
        content.sound = UNNotificationSound.default

        // Add custom data to identify the shop
        content.userInfo = ["shopId": shopId]

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Notification sent for shop: \(shopName)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        // Handle location access denied
        if let clError = error as? CLError, clError.code == .denied {
            // Notify other parts of the app that location access was denied
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
}
