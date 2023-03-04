//
//  LocationManager.swift
//  COWStatusCrumb
//
//  Created by XQF on 04.03.23.
//

// taken from https://github.com/rileytestut/Clip. many thanks

import CoreLocation
import Combine
import UIKit

extension LocationManager
{
    typealias Status = Result<Void, Swift.Error>
    
    enum Error: LocalizedError, RecoverableError
    {
        case requiresAlwaysAuthorization
        
        var failureReason: String? {
            switch self
            {
            case .requiresAlwaysAuthorization: return NSLocalizedString("SecondHand requires “Always” location permission.", comment: "")
            }
        }
        
        var recoverySuggestion: String? {
            switch self
            {
            case .requiresAlwaysAuthorization: return NSLocalizedString("Please grant SecondHand “Always” location permission in Settings so it can run in the background indefinitely.", comment: "")
            }
        }
        
        var recoveryOptions: [String] {
            switch self
            {
            case .requiresAlwaysAuthorization: return [NSLocalizedString("Open Settings", comment: "")]
            }
        }
        
        func attemptRecovery(optionIndex recoveryOptionIndex: Int) -> Bool
        {
            return false
        }
        
        func attemptRecovery(optionIndex recoveryOptionIndex: Int, resultHandler handler: @escaping (Bool) -> Void)
        {
            switch self
            {
            case .requiresAlwaysAuthorization:
                let openURL = URL(string: UIApplication.openSettingsURLString)!
                UIApplication.shared.open(openURL, options: [:], completionHandler: handler)
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject
{
    var status: Status? = nil

    var locationManager: CLLocationManager
    
    @Published var authorizationStatus: CLAuthorizationStatus?
    
    override init()
    {
        self.locationManager = CLLocationManager()
        self.locationManager.distanceFilter = CLLocationDistanceMax
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.allowsBackgroundLocationUpdates = true
        
        if #available(iOS 14.0, *)
        {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyReduced
        }
        else
        {
            self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        }
        
        super.init()
        
        self.locationManager.delegate = self
    }
    
    func start()
    {
        switch self.status
        {
        case .success: return
        case .failure, nil: break
        }
        
        if locationManager.authorizationStatus == .notDetermined || locationManager.authorizationStatus == .authorizedWhenInUse
        {
            self.locationManager.requestAlwaysAuthorization()
            return
        }
        
        self.locationManager.startUpdatingLocation()
    }
    
    func stop()
    {
        self.locationManager.stopUpdatingLocation()
        self.status = nil
    }
}


extension LocationManager: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        switch status
        {
        case .notDetermined:
            authorizationStatus = .notDetermined
            break
        case .restricted, .denied, .authorizedWhenInUse:
            authorizationStatus = .restricted
            self.status = .failure(Error.requiresAlwaysAuthorization)
        case .authorizedAlways:
            authorizationStatus = .authorizedWhenInUse
            self.start()
        @unknown default: break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        self.status = .success(())
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error)
    {
        if let error = error as? CLError
        {
            guard error.code != .denied else {
                self.status = .failure(Error.requiresAlwaysAuthorization)
                return
            }
        }
        
        self.status = .failure(error)
    }
}

