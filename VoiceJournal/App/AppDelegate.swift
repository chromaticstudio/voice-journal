//
//  AppDelegate.swift
//  VoiceJournal
//
//  Created by Anthony Mistretta on 7/26/24.
//

import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle background fetch
        print("Background fetch occurred")
        // Your background fetch logic here

        completionHandler(.newData) // or .noData or .failed based on your fetch results
    }
}
