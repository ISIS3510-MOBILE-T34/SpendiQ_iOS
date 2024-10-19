//
//  SpendiQApp.swift
//  SpendiQ
//
//  Created by Juan Salguero on 26/09/24.
//

import SwiftUI
import Firebase

@main
struct SpendiQApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    print("Firebase connection working")
    return true
  }
}
