//
//  AppDelegate.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/26/24.
//

import UIKit
import Foundation

class AppDelegate: UIResponder, UIApplicationDelegate {

    // Existing background fetch method
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle background fetch
        print("Background fetch occurred")
        // Your background fetch logic here
        
        completionHandler(.newData) // or .noData or .failed based on your fetch results
    }
    
    // MARK: UISceneSession Lifecycle (if using scenes)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
