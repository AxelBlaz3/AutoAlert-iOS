//
//  Speed_AuditorApp.swift
//  Speed Auditor
//
//  Created by Karthik on 16/04/21.
//

import SwiftUI

@main
struct AutoAlertApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                if (appDelegate.isLoggedIn()) {
                    ContentView()
                } else {
                    LoginView()
                }
            }
        }
    }
}
