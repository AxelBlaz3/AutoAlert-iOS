//
//  SmartGaugeView.swift
//  Speed Auditor
//
//  Created by Karthik on 28/04/21.
//

import UIKit
import SwiftUI
import SmartGauge

struct SmartGaugeView: UIViewRepresentable {
    var gaugeValue: Int = 0
    
    func makeUIView(context: Context) -> some UIView {
        let uiView = SmartGauge()
        let first = SGRanges("", fromValue: 0, toValue: 30, color: .green)
        let second = SGRanges("", fromValue: 30, toValue: 65, color: .orange)
        let third = SGRanges("", fromValue: 65, toValue: 100, color: .red)

        uiView.numberOfMajorTicks = 5
        uiView.numberOfMinorTicks = 4
        uiView.rangesList = [first, second, third]
        uiView.gaugeMaxValue = third.toValue
        uiView.enableRangeColorIndicator = true
        uiView.enableLegends = false
        uiView.gaugeValueTrackWidth = 0
        uiView.gaugeAngle = 60
        uiView.gaugeValue = 0
        uiView.valueTextColor = UIColor.systemBackground
        
        return uiView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        (uiView as? SmartGauge)?.gaugeValue = CGFloat(gaugeValue + 10)
        //(uiView as? SmartGauge)?.gaugeTrackColor = UIColor.blue
    }
}
