import MapKit
import SwiftUI

extension MKCoordinateRegion {
    static func fitting(_ mapRect: MKMapRect) -> MKCoordinateRegion {
        let paddedRect = mapRect.insetBy(dx: -mapRect.width * 0.28, dy: -mapRect.height * 0.28)
        return MKCoordinateRegion(paddedRect)
    }

    static func centeredRegion(on coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    static func focusedRegion(on coordinate: CLLocationCoordinate2D) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    }
}

extension MapCamera {
    static func navigationCamera(on coordinate: CLLocationCoordinate2D) -> MapCamera {
        MapCamera(
            centerCoordinate: coordinate,
            distance: 400,
            heading: 0,
            pitch: 0
        )
    }
}

extension MKPolyline {
    var firstRouteCoordinate: CLLocationCoordinate2D? {
        guard pointCount > 0 else {
            return nil
        }

        return points()[0].coordinate
    }

    var lastRouteCoordinate: CLLocationCoordinate2D? {
        guard pointCount > 0 else {
            return nil
        }

        return points()[pointCount - 1].coordinate
    }
}
