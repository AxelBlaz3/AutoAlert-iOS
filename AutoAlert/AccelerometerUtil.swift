//
//  AccelerometerUtil.swift
//  Speed Auditor
//
//  Created by Karthik on 16/04/21.
//

import SwiftUI
import CoreMotion

struct AccelerometerUtil {
    let motion = CMMotionManager()
    @State private var timer: Timer = Timer()
    @Binding var x: Double
    @Binding var y: Double
    @Binding var z: Double
    @Binding var maxSpeedSoFar: Int
    @Binding var speed: Int
    @State var prevX: Double = 0
    @State var prevY: Double = 0
    @State var prevZ: Double = 0
    
    func startAccelerometers() {
        print("startAccelerometers()")
        // Make sure the accelerometer hardware is available.
        if self.motion.isAccelerometerAvailable {
            print("Accelerometer available...")
            self.motion.accelerometerUpdateInterval = 0.5
            self.motion.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                if (error == nil) {
                    x = data!.acceleration.x
                    y = data!.acceleration.y
                    z = data!.acceleration.z
                    
                    speed = Int(sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2)))
                    maxSpeedSoFar = max(maxSpeedSoFar, speed)
                    prevX = x
                    prevY = y
                    prevZ = z
                }
            }
            
            //            print("Starting updates...")
            //            let dispatchQueue = DispatchQueue(label: "QueueIdentification", qos: .background)
            //            dispatchQueue.async{
            //                while true {
            //                    if let data = self.motion.accelerometerData {
            //                        x = data.acceleration.x
            //                        y = data.acceleration.y
            //                        z = data.acceleration.z
            //
            //                        //print("x - \(x), y - \(y), z - \(z)")
            //                        // Use the accelerometer data in your app.
            //                    }
            //                }
            //            }
        } else {
            print("Accelerometer unavailable :(")
        }
    }
}
