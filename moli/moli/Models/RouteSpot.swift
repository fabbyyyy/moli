import CoreLocation
import Foundation

struct RouteSpot: Identifiable {
    let id: UUID
    let store: Store
    let stopNumber: Int
    let isCompleted: Bool
    let isCurrent: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: store.latitude, longitude: store.longitude)
    }
}
