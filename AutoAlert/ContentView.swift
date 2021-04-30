//
//  ContentView.swift
//  Speed Auditor
//
//  Created by Karthik on 16/04/21.
//

import SwiftUI
import CoreMotion
import CoreLocation
import UserNotifications
import AVFoundation
import SmartGauge

struct ContentView: View {
    @State var maxSpeedSoFar = 0
    @State var speed: Int = 0
    @State var defShowAlert = false
    @State var backgroundTaskId = UIBackgroundTaskIdentifier.invalid
    @State var shouldLogout = false
    @EnvironmentObject var user: User
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.presentationMode) var presentationMode
    @StateObject var locationManager: LocationManager = LocationManager()
    
    var body: some View {
        VStack {
            NavigationLink(
                destination: LoginView(),
                isActive: $shouldLogout,
                label: {
                    Text("")
                })
            Group {
                HStack {
                    Text("Hot").font(.custom("Digital-7", size: 48)).fontWeight(.black).padding(.bottom, 32).foregroundColor(.blue)
                    Text("Car").font(.custom("Digital-7", size: 48)).fontWeight(.black).padding(.bottom, 32).foregroundColor(.red)
                }
            }
            
            SmartGaugeView(gaugeValue: locationManager.speedInMPH).frame(maxWidth: .infinity, maxHeight: 300)
            HStack {
                VStack(alignment: HorizontalAlignment.leading) {
                    HStack {
                        Text("\(locationManager.speedInMPH)").font(.custom("Digital-7", size: 72))
                        Text("MPH").padding(.top, 24)
                    }
                    Text("Speed").font(.caption)
                }.padding(.leading, 24)
                Spacer()
                
                VStack(alignment: HorizontalAlignment.leading) {
                    HStack {
                        Text("\(Int(Double(locationManager.maxSpeedCaptured) * 2.237))").font(.custom("Digital-7", size: 72))
                        Text("MPH").padding(.top, 24)
                    }
                    Text("Max speed").font(.caption)
                }.padding(.trailing, 24)
            }
            
            Button(action: {
                UserDefaults.standard.set(-1, forKey: Constants.KEY_APP_CYCLE_ID)
                UserDefaults.standard.set(-1, forKey: Constants.KEY_PREV_APP_CYCLE_ID)
                UserDefaults.standard.set(-1, forKey: Constants.KEY_USER_ID)
                UserDefaults.standard.set("", forKey: Constants.KEY_EMAIL)
                UserDefaults.standard.set(0, forKey: Constants.KEY_MAX_SPEED_CAPTURED)
                UserDefaults.standard.set("", forKey: Constants.KEY_LAST_CLOSED_TIMESTAMP)
                UserDefaults.standard.set(false, forKey: Constants.KEY_IS_LOGGED_IN)
                
                if (!presentationMode.wrappedValue.isPresented) {
                    shouldLogout = true
                    return
                }
                print(presentationMode.wrappedValue)
                presentationMode.wrappedValue.dismiss()
                print("Logout")
            }, label: {
                VStack {
                    Image(systemName: "power").resizable().foregroundColor(.red).frame(width: 32, height: 32)
                    Text("Logout").foregroundColor(.red)
                }
            })
        }
        .onAppear {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                if (success) {
                    
                }
                else if let error = error {
                    print(error.localizedDescription)
                }
            }
            
            locationManager.startUpdating(refresh: false)
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                locationManager.startUpdating(refresh: true)
                save()
            } else if newPhase == .background {
                locationManager.startUpdating(refresh: true)
                save()
            } else if newPhase == .active{
                locationManager.startUpdating(refresh: true)
            }
        }
    }
    
    func save() {
        User.setUserDefaultPreference(key: Constants.KEY_LAST_CLOSED_TIMESTAMP, value: LoginView.getCurrentTimeStamp())
        User.setUserDefaultPreference(key: Constants.KEY_PREV_APP_CYCLE_ID, value: User.getAppCycleId())
        User.setUserDefaultPreference(key: Constants.KEY_MAX_SPEED_CAPTURED, value: Int(Double(locationManager.maxSpeedCaptured) * 2.237))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
