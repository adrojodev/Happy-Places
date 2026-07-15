//
//  LocationDataManager.swift
//  Nice Places
//
//  Created by Alan David Hernández Trujillo on 09/02/24.
//

import Foundation
import CoreLocation
import Observation

/// Retained location manager. The CLLocationManager must outlive the
/// permission prompt — a throwaway instance is deallocated before the
/// prompt can appear, so always go through this shared object.
@Observable
class LocationDataManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationDataManager()

    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }

    func requestAuthorizationIfNeeded() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
