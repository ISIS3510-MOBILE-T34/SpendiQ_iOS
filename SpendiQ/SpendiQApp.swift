//
//  SpendiQApp.swift
//  SpendiQ
//
//  Created by Estudiantes on 25/09/24.
//

import SwiftUI
import Firebase


@main
struct SpendiQApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
