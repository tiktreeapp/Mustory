//
//  MustoryApp.swift
//  Mustory
//
//  Created by apple on 2026/2/23.
//

import SwiftUI
import SwiftData
import MusicKit

@main
struct MustoryApp: App {
    @State private var musicManager = MusicManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if musicManager.authorizationStatus == .authorized {
                    HomeView()
                } else {
                    LaunchView()
                }
            }
            .animation(.default, value: musicManager.authorizationStatus)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh auth status when app returns to foreground
                // This handles the case where user revokes access in system Settings
                Task {
                    await musicManager.refreshAuthorizationStatus()
                }
            }
        }
    }
}
