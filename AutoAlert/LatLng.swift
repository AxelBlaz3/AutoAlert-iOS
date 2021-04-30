//
//  LatLng.swift
//  Speed Auditor
//
//  Created by Karthik on 17/04/21.
//

import CoreLocation

struct LatLng: Identifiable, Hashable {
    var id: UUID
    var lat: CLLocationDegrees
    var lng: CLLocationDegrees
    
    init(lat: CLLocationDegrees, lng: CLLocationDegrees) {
        self.id = UUID()
        self.lat = lat
        self.lng = lng
    }
}
