import CoreLocation
import Observation

@Observable
final class RouteLocationService: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    var currentLocationKey: String {
        guard let currentLocation else {
            return "unknown"
        }
        
        return "\(currentLocation.latitude),\(currentLocation.longitude)"
    }

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
            manager.startUpdatingLocation()
        case .denied, .restricted:
            authorizationStatus = manager.authorizationStatus
        @unknown default:
            authorizationStatus = manager.authorizationStatus
        }
    }

    func startFollowing() {
        requestLocation()
        manager.startUpdatingLocation()
    }

    func stopFollowing() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Route location error: \(error)")
    }
}
