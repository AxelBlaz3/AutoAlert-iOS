//
//  SpeedAuditorDelegate.swift
//  Speed Auditor
//
//  Created by Karthik on 19/04/21.
//

import SwiftUI
import CoreLocation

class AppDelegate: NSObject, ObservableObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var maxSpeedCaptured: Int = 0
    
    var userName: String {
        NSUserName()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        load()
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler:
                                    @escaping () -> Void) {
        // Perform the task associated with the action.
        switch response.actionIdentifier {
        case "ACCEPT_ACTION":
            LocationManager.finalTimer.invalidate()
            LocationManager.isTriggered = false
            LocationManager.passengerFlag = false
            // Reset alertTimer and alertCount.
            LocationManager.alertTimer.invalidate()
            NotificationManager.isAlertTimerSet = false
            NotificationManager.alertCount = 0
            // Reset interval in LocationManager
            LocationManager.interval = Date()
            
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            // Send an email to parent.
            LocationManager.sendMail(to: User.getUserEmail(), from: "wielabstest@gmail.com", subject: "Hot Car App Destination Alert", message: "User \(UserDefaults.standard.string(forKey: Constants.KEY_USERNAME) ?? "") has arrived destination with top speed \(AppDelegate.maxSpeedCaptured) MPH")
            
            // updateStatistics(columnNameToBeUpdated: "speed", appCycleId: User.getPrevAppCycleId(), timestamp: User.getLastClosedTimestamp())
            
            // Update timestamp of yes button click in database.
            updateStatistics(columnNameToBeUpdated: "alert_answered_timestamp", appCycleId: User.getAppCycleId(), timestamp: LoginView.getCurrentTimeStamp())
            
            // Minimize app.
            minimizeOrKillApp()
            break
            
        case "DECLINE_ACTION":
            LocationManager.finalTimer.invalidate()
            LocationManager.stopLocationUpdates()
            LocationManager.isTriggered = true
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            updateStatistics(columnNameToBeUpdated: "alert_answered_timestamp", appCycleId: User.getAppCycleId(), timestamp: LoginView.getCurrentTimeStamp())
            
            // Show notification.
            showCheckForPassengersAlert()
            break
            
        case "OKAY_ACTION":
            LocationManager.isTriggered = true
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            break
            
        case "OKAY_ACTION_FINAL":
            LocationManager.finalTimer.invalidate()
            LocationManager.alertTimer.invalidate()
            LocationManager.stopLocationUpdates()
            minimizeOrKillApp(kill: true)
            LocationManager.isTriggered = true
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            break
        // Handle other actions…
        
        default:
            break
        }
        
        // Always call the completion handler when done.
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler:
                                    @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.content.categoryIdentifier ==
            "SPEED_ACTIONS" {
            
            // Play a sound to let the user know about the invitation.
            completionHandler([.sound, .badge, .banner, .list])
            return
        }
        else {
            // Handle other notification types...
        }
        
        
        // Don't alert the user for other types.
        completionHandler(UNNotificationPresentationOptions(rawValue: 0))
    }
    
    func minimizeOrKillApp(kill: Bool = false){
        DispatchQueue.main.async {
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        }
        if (kill) {
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { (timer) in
                exit(0)
            }
        }
    }
    
    func isLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: Constants.KEY_IS_LOGGED_IN)
    }
    
    func updateStatistics(columnNameToBeUpdated: String, appCycleId: Int, timestamp: String) {
        //print("Apple cycle id - \(appCycleId)")
        if (appCycleId < 0) {
            return
        }
        var credentialsJson: [URLQueryItem] = []
        
        //print("About to update arrival and cycle end timestamps...")
        credentialsJson.append(URLQueryItem(name: "update_column_name", value: columnNameToBeUpdated))
        credentialsJson.append(URLQueryItem(name: "app_cycle_id", value: String(appCycleId)))
        credentialsJson.append(URLQueryItem(name: "timestamp", value: timestamp))
        
        let url = URL(string: "https://wielabs.com/speed_auditor/update_statistics.php")!
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = credentialsJson
        let queryString = urlComponents?.url!.query
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = Data(queryString!.utf8)
        
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            print("Done with updating statistics.")
            guard error == nil else {
                print("Error: error calling POST")
                print(error!)
                return
            }
            guard let res = response as? HTTPURLResponse, (200 ..< 299) ~= res.statusCode else {
                print("Error: HTTP request failed, error - \((response as! HTTPURLResponse).statusCode)")
                return
            }
        }
        task.resume()
    }
    
    func postStatistics() {
        if (User.getUserId() <= 0) {
            return
        }
        let credentialsJson =
            [URLQueryItem(name: "user_id", value: String(User.getUserId())),
             URLQueryItem(name: "departure_timestamp", value: LoginView.getCurrentTimeStamp())]
        
        let url = URL(string: "https://wielabs.com/speed_auditor/statistics.php")!
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = credentialsJson
        let queryString = urlComponents?.url!.query
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = Data(queryString!.utf8)
        
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                //  someErrorAlert = true
                print("Error: error calling POST")
                print(error!)
                return
            }
            guard let data = data else {
                print("Error: Did not receive data")
                // someErrorAlert = true
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                // someErrorAlert = true
                print("Error: HTTP request failed")
                return
            }
            
            do {
                let currentUser = try JSONDecoder().decode(User.self, from: data)
                DispatchQueue.main.async {
                    User.setUserDefaultPreference(key: Constants.KEY_PREV_APP_CYCLE_ID, value: User.getAppCycleId())
                    User.setUserDefaultPreference(key: Constants.KEY_APP_CYCLE_ID, value: currentUser.appCycleId)
                }
                
                if (!User.getLastClosedTimestamp().isEmpty && User.getPrevAppCycleId() > 0) {
                    self.updateStatistics(columnNameToBeUpdated: "app_cycle_end_timestamp", appCycleId: User.getPrevAppCycleId(), timestamp: User.getLastClosedTimestamp())
                }
                // isUserCreated = true
            } catch {
                print("Can't decode user JSON (app cycle id)")
                return
            }
        }
        task.resume()
    }
    
    func load() {
        postStatistics()
    }
    
    private func showCheckForPassengersAlert() {
        let content = UNMutableNotificationContent()
        content.title = ""
        content.subtitle = "Please check for passengers in vehicle"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "SPEED_ACTIONS"
        // show this notification one second from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        let okayAction = UNNotificationAction(identifier: "OKAY_ACTION_FINAL",
                                              title: "Okay",
                                              options: UNNotificationActionOptions(rawValue: 0))
        
        // Define the notification type
        let speedActionsCategory =
            UNNotificationCategory(identifier: "SPEED_ACTIONS",
                                   actions: [okayAction],
                                   intentIdentifiers: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([speedActionsCategory])
        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
}
