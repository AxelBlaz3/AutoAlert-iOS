//
//  ABGaugeSwiftView.swift
//  HotCar
//
//  Created by Karthik on 29/04/21.
//

import SwiftUI
import ABGaugeViewKit

struct ABGaugeSwiftView: UIViewRepresentable {
    @State var needleValue = 0
    
    func makeUIView(context: Context) -> some UIView {
        let gaugeView = ABGaugeView()
        gaugeView.backgroundColor = UIColor.systemBackground
        gaugeView.shadowColor = UIColor.systemBackground
        gaugeView.colorCodes = "929918,C8CC86,66581A,3A4A73"
        gaugeView.areas = "25,25,25,25"
        return ABGaugeView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        (uiView as? ABGaugeView)?.needleValue = CGFloat(needleValue)
    }
}
