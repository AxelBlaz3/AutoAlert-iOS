//
//  SpeedUtil.swift
//  Speed Auditor
//
//  Created by Karthik on 16/04/21.
//

import Foundation
import SwiftUI
import CoreLocation
import AVFoundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static var manager: CLLocationManager? = CLLocationManager()
    var locB: CLLocation?
    var locA: CLLocation?
    var notificationManager: NotificationManager {
        NotificationManager(locationManager: self)
    }
    static var interval: Date = Date()
    static var alertTimer = Timer()
    static var finalTimer = Timer()
    var timer = Timer()
    static var isTriggered = false
    static var passengerFlag = false
    @Published var showAlert = false
    @Published var speed: Int = 0
    @Published var speedInMPH = 0
    @Published var maxSpeedCaptured: Int = 0
    var prevSpeedInMph = 0
    
    override init() {
        super.init()
        startUpdating(refresh: false)
    }
    
    func startUpdating(refresh: Bool) {
        var flag = false
        if (LocationManager.manager == nil) {
            LocationManager.manager = CLLocationManager()
            flag = true
        }
        LocationManager.manager?.delegate = self
        if (LocationManager.manager?.authorizationStatus == CLAuthorizationStatus.authorizedAlways || LocationManager.manager?.authorizationStatus == CLAuthorizationStatus.authorizedWhenInUse) {
            LocationManager.manager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            if (!refresh || flag) {
                LocationManager.manager?.startUpdatingLocation()
            }
            LocationManager.manager?.showsBackgroundLocationIndicator = true
            LocationManager.manager?.allowsBackgroundLocationUpdates = true
            LocationManager.manager?.pausesLocationUpdatesAutomatically = false
        }
        else {
            LocationManager.manager?.requestAlwaysAuthorization()
        }
    }
    
    func updateLocationAccuracy(accuracy: CLLocationAccuracy) -> Void {
        LocationManager.manager?.desiredAccuracy = accuracy
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        speed = max(0, Int(locations.last?.speed ?? -1))
        speedInMPH = Int(Double(speed) * 2.237)
        
        if (speedInMPH > 5 && !LocationManager.isTriggered) {
            // Remove previously delivered notifications if any.
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            // Invalidate timers.
            LocationManager.finalTimer.invalidate()
            timer.invalidate()
            LocationManager.alertTimer.invalidate()
            
            // Trigger a new app cycle.
            LocationManager.isTriggered = true
            // Send notification.
            notificationManager.addNotificationRequest(title: "", subtitle: "You appear to be traveling in a vehicle")
        }
        
//        if ((prevSpeedInMph < 5 && speedInMPH >= 5) || (prevSpeedInMph >= 5 && speedInMPH < 5)) {
//            LocationManager.isTriggered = false
//        }
        
//        if (speedInMPH > 15 && !LocationManager.isTriggered) {
//            LocationManager.isTriggered = true
//            timer.invalidate()
//            LocationManager.alertTimer.invalidate()
//
//            NotificationManager.isAlertTimerSet = false
//            NotificationManager.alertCount = 0
//
//            notificationManager.addNotificationRequest(title: "", subtitle: "You appear to be traveling in a vehicle")
//            //self.showAlert = true
//        } else
        if (speedInMPH < 5 && LocationManager.isTriggered && !LocationManager.passengerFlag) {
            LocationManager.finalTimer = Timer.scheduledTimer(timeInterval: 1500, target: self, selector: #selector(LocationManager.logAlertAndSendMailToAdmin), userInfo: nil, repeats: false)
            LocationManager.passengerFlag = true
            timer.invalidate()
            LocationManager.alertTimer.invalidate()
            
            NotificationManager.isAlertTimerSet = false
            NotificationManager.alertCount = 0
            
            // 7 minutes.
            LocationManager.interval = Date()
            timer = Timer.scheduledTimer(timeInterval: 420, target: self, selector: #selector(verifySpeedAfterTenMin), userInfo: nil, repeats: false)
        }
        
        maxSpeedCaptured = max(maxSpeedCaptured, speed)
        AppDelegate.maxSpeedCaptured = Int(Double(maxSpeedCaptured) * 2.237)
        prevSpeedInMph = speedInMPH
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location updates failed with error - \(error.localizedDescription)")
    }
    
    func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("Location updates are paused...")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            startUpdating(refresh: false)
        }
    }
    
    @objc func verifySpeedAfterTenMin() {
        if (speedInMPH < 5) {
            notificationManager.addNotificationRequest(title: "", subtitle: "Have you checked your vehicle for passengers?", isDestinationAlert: true)
        }
    }
    
    static func stopLocationUpdates() {
        manager?.stopUpdatingLocation()
    }
    
    @objc static func logAlertAndSendMailToAdmin() {
        // TODO: Log timestamp in database.
        LocationManager.sendMail(to: "tracyalexander1@gmail.com", from: "wielabstest@gmail.com", subject: "Alert ignored", message: "Destination alert is ignored for 25 min by \(User.getUserName()) with app cycle id - \(User.getAppCycleId()).")
    }
    
    @objc static func sendMail(to: String, from: String, subject: String, message: String, username: String = "") {
        print("Sending mail to - \(to), Subject - \(subject), Message - \(message), Username - \(username)")
        var mailDataJson =
            [URLQueryItem(name: "email", value: to),
             URLQueryItem(name: "subject", value: subject),
             URLQueryItem(name: "message", value: message),
             URLQueryItem(name: "from", value: from),
             URLQueryItem(name: "app_cycle_id", value: String(User.getAppCycleId()))
            ]
        
        if (!username.isEmpty) {
            mailDataJson.append(URLQueryItem(name: "username", value: username))
        }
        
        let url = URL(string: "https://wielabs.com/speed_auditor/send_mail.php")!
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = mailDataJson
        let queryString = urlComponents?.url!.query
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = Data(queryString!.utf8)
        
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            print("Done with task")
            guard error == nil else {
                print("Error: error calling POST")
                print(error!)
                return
            }
            guard data != nil else {
                print("Error: Did not receive data")
                return
            }
            guard let response = response as? HTTPURLResponse, (200 ..< 299) ~= response.statusCode else {
                print("Error: HTTP request failed")
                return
            }
        }
        task.resume()
    }
}
