//
//  AlertManager.swift
//  Speed Auditor
//
//  Created by Karthik on 20/04/21.
//

import AVFoundation

class AlertManager {
    var audioAlertEffect: AVAudioPlayer?
    
    func playAudio() {
        let path = Bundle.main.path(forResource: "iphone_notification.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)
        do {
            print("Spam time...")
            if (audioAlertEffect == nil) {
                audioAlertEffect = try AVAudioPlayer(contentsOf: url)
                audioAlertEffect?.numberOfLoops = 100000
                audioAlertEffect?.prepareToPlay()
                audioAlertEffect?.play()
            } else {
                audioAlertEffect!.numberOfLoops = 100000
                audioAlertEffect!.prepareToPlay()
                audioAlertEffect!.play()
            }
        } catch {
            // couldn't load file :(
            print("Couldn't find audio...")
        }
    }
}
