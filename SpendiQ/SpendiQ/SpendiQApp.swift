//
//  SpendiQApp.swift
//  SpendiQ
//
//  Created by Juan Salguero on 26/09/24.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct SpendiQApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Firebase good")

        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let shopId = response.notification.request.content.userInfo["shopId"] as? String
        NotificationCenter.default.post(name: NSNotification.Name("ShowOffersList"), object: nil, userInfo: ["shopId": shopId ?? ""])
        completionHandler()
    }

    // Optional: Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Display the notification as a banner and play a sound even when the app is in the foreground
        completionHandler([.banner, .sound])
    }
}
