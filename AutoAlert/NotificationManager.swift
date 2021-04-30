//
//  NotificationManager.swift
//  Speed Auditor
//
//  Created by Karthik on 19/04/21.
//

import UserNotifications
import AVFoundation

class NotificationManager {
    let content = UNMutableNotificationContent()
    let locationManager: LocationManager
    static var isAlertTimerSet = false
    static var alertCount = 0
    var lastSubtitle = ""
    
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }

    func addNotificationRequest(title: String, subtitle: String, isDestinationAlert: Bool = false) {
//        if (subtitle != lastSubtitle) {
//            NotificationManager.isAlertTimerSet = false
//            NotificationManager.alertCount = 0
//            LocationManager.alertTimer.invalidate()
//        }
        
            content.title = title
            content.subtitle = subtitle
            content.sound = UNNotificationSound.default
            content.categoryIdentifier = "SPEED_ACTIONS"
            
            // show this notification one second from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // choose a random identifier
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            if (isDestinationAlert) {
                // Define the custom actions.
                let acceptAction = UNNotificationAction(identifier: "ACCEPT_ACTION",
                                                        title: "Yes",
                                                        options: UNNotificationActionOptions(rawValue: 0))
                let declineAction = UNNotificationAction(identifier: "DECLINE_ACTION",
                                                         title: "No",
                                                         options: UNNotificationActionOptions(rawValue: 0))
                
                // Define the notification type
                let speedActionsCategory =
                    UNNotificationCategory(identifier: "SPEED_ACTIONS",
                                           actions: [acceptAction, declineAction],
                                           intentIdentifiers: [])
                
                UNUserNotificationCenter.current().setNotificationCategories([speedActionsCategory])
                
                // Build a timer to start notification alerts for every 2 minutes.
                if (!NotificationManager.isAlertTimerSet && isDestinationAlert) {
                    lastSubtitle = subtitle
                    NotificationManager.isAlertTimerSet = true
                    LocationManager.alertTimer = Timer.scheduledTimer(timeInterval: 180, target: self, selector: #selector(alertPrevNotification), userInfo: nil, repeats: false)
                } else if (NotificationManager.isAlertTimerSet && isDestinationAlert) {
                    if (NotificationManager.alertCount < 3) {
                        LocationManager.alertTimer = Timer.scheduledTimer(timeInterval: 180, target: self, selector: #selector(alertPrevNotification), userInfo: nil, repeats: false)
                    }
                    else {
                        LocationManager.sendMail(to: User.getUserEmail(), from: "wielabstest@gmail.com", subject: "Hot Car App Urgent Alert", message: "The Hot Car App on \(NSUserName())’s phone has alerted and not been answered by the user.", username: NSUserName())
                    }
                }
                
            } else {
                let okayAction = UNNotificationAction(identifier: "OKAY_ACTION",
                                                      title: "Okay",
                                                      options: UNNotificationActionOptions(rawValue: 0))
                
                // Define the notification type
                let speedActionsCategory =
                    UNNotificationCategory(identifier: "SPEED_ACTIONS",
                                           actions: [okayAction],
                                           intentIdentifiers: [])
                
                UNUserNotificationCenter.current().setNotificationCategories([speedActionsCategory])
            }
            // add our notification request
            UNUserNotificationCenter.current().add(request)
    }
    
    @objc func alertPrevNotification() {
        NotificationManager.alertCount += 1
        print("Notification from alert with count - \(NotificationManager.alertCount)")
        addNotificationRequest(title: "", subtitle: lastSubtitle, isDestinationAlert: true)
    }
}
