import Foundation
import CoreLocation
import Observation

/// @Observable rather than ObservableObject: it keeps this consistent with
/// KarmaStore and avoids depending on Combine, which Swift 6 no longer makes
/// visible through `import SwiftUI`.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    var status: CLAuthorizationStatus
    var location: CLLocation?

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 10
    }

    var isAuthorized: Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
    }

    var isDenied: Bool {
        status == .denied || status == .restricted
    }

    /// Called when the map first appears, not at launch.
    func requestIfNeeded() {
        switch status {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways: manager.startUpdatingLocation()
        default: break
        }
    }

    func stop() { manager.stopUpdatingLocation() }

    /// Metres to a venue, or nil when we have no fix — callers treat nil as
    /// "don't enforce proximity" so a denied permission never blocks check-in.
    func distance(to venue: Venue) -> Double? {
        guard let location else { return nil }
        return location.distance(from: venue.location)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        status = manager.authorizationStatus
        if isAuthorized { manager.startUpdatingLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silent: the UI already treats "no fix" as an ordinary state.
    }
}
