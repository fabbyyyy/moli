import Foundation
import MapKit
import Observation

@Observable
final class RouteViewModel {
    var routeStops: [RouteStop] = []
    var nextStop: RouteStop?
    var selectedSpotID: UUID?
    var activeNavigationStop: RouteStop?
    var isNavigationActive = false
    var isCalculatingRoute = false
    var routeSegments: [MKRoute] = []
    var navigationRoute: MKRoute?
    var routeErrorMessage: String?
    
    var completedStopsCount: Int {
        routeStops.filter { $0.isCompleted }.count
    }
    
    var routeSpots: [RouteSpot] {
        routeStops.map { stop in
            RouteSpot(
                id: stop.id,
                store: stop.store,
                stopNumber: stop.stopNumber,
                isCompleted: stop.isCompleted,
                isCurrent: stop.isCurrent
            )
        }
    }
    
    var routeCoordinates: [CLLocationCoordinate2D] {
        routeSpots.map(\.coordinate)
    }
    
    var selectedStop: RouteStop? {
        guard let selectedSpotID else {
            return nil
        }
        
        return routeStops.first { $0.id == selectedSpotID }
    }
    
    var selectedOrNextStop: RouteStop? {
        activeNavigationStop ?? selectedStop ?? nextStop
    }
    
    var totalRouteDistanceText: String {
        let kilometers = routeSegments.reduce(0) { $0 + $1.distance } / 1_000
        guard kilometers > 0 else {
            return "-- km"
        }
        
        return String(format: "%.1f km", kilometers)
    }
    
    var totalRouteTravelTimeText: String {
        let minutes = Int(routeSegments.reduce(0) { $0 + $1.expectedTravelTime } / 60)
        guard minutes > 0 else {
            return "-- min"
        }
        
        return "\(minutes) min"
    }

    var navigationDistanceText: String {
        guard let navigationRoute else {
            return totalRouteDistanceText
        }

        return String(format: "%.1f km", navigationRoute.distance / 1_000)
    }

    var navigationTravelTimeText: String {
        guard let navigationRoute else {
            return totalRouteTravelTimeText
        }

        return "\(max(Int(navigationRoute.expectedTravelTime / 60), 1)) min"
    }

    var navigationRemainingDistanceText: String {
        guard let navigationRoute else {
            return "--"
        }

        if navigationRoute.distance < 1_000 {
            return "\(Int(navigationRoute.distance.rounded()))"
        }

        return String(format: "%.1f", navigationRoute.distance / 1_000)
    }

    var navigationRemainingDistanceUnit: String {
        guard let navigationRoute else {
            return "m"
        }

        return navigationRoute.distance < 1_000 ? "m" : "km"
    }

    var navigationArrivalTimeText: String {
        let arrivalDate = Date().addingTimeInterval(navigationRoute?.expectedTravelTime ?? 0)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "H:mm"
        return formatter.string(from: arrivalDate)
    }

    var navigationInstructionText: String {
        navigationRoute?.steps.first(where: { !$0.instructions.isEmpty })?.instructions ?? "Sigue la ruta marcada"
    }

    var currentNavigationStep: RouteNavigationStepInfo {
        navigationStepInfo(at: 0) ?? RouteNavigationStepInfo(
            instruction: "Sigue la ruta marcada",
            distanceText: navigationRemainingDistanceText,
            systemImage: "arrow.up"
        )
    }

    var nextNavigationStep: RouteNavigationStepInfo? {
        navigationStepInfo(at: 1)
    }
    
    var mapRegion: MKCoordinateRegion {
        guard !routeCoordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        }
        
        let latitudes = routeCoordinates.map(\.latitude)
        let longitudes = routeCoordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? 19.4326
        let maxLatitude = latitudes.max() ?? 19.4326
        let minLongitude = longitudes.min() ?? -99.1332
        let maxLongitude = longitudes.max() ?? -99.1332
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLatitude - minLatitude) * 2.4, 0.02),
                longitudeDelta: max((maxLongitude - minLongitude) * 2.4, 0.02)
            )
        )
    }
    
    func loadRoute() {
        self.routeStops = LocalPersistenceService.shared.currentRoute
        self.nextStop = self.routeStops.first(where: { !$0.isCompleted })
    }
    
    func selectSpot(id: UUID?) {
        selectedSpotID = id
    }
    
    func startNavigation(to stop: RouteStop?) {
        activeNavigationStop = stop ?? selectedStop ?? nextStop
        selectedSpotID = nil
        isNavigationActive = activeNavigationStop != nil
    }
    
    func stopNavigation() {
        isNavigationActive = false
        activeNavigationStop = nil
        navigationRoute = nil
    }
    
    func openSelectedStopInMaps() {
        guard let stop = selectedOrNextStop else {
            return
        }
        
        let location = CLLocation(latitude: stop.store.latitude, longitude: stop.store.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = stop.store.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
    
    func calculateRouteFromCurrentOrder() async {
        await calculateRoute(startCoordinate: nil)
    }
    
    func calculateRoute(startCoordinate: CLLocationCoordinate2D?) async {
        let stopCoordinates = routeCoordinates
        guard stopCoordinates.count > 1 || startCoordinate != nil else {
            routeSegments = []
            return
        }
        
        isCalculatingRoute = true
        routeErrorMessage = nil
        
        var waypoints = stopCoordinates
        if let startCoordinate {
            waypoints.insert(startCoordinate, at: 0)
        }
        
        do {
            var segments: [MKRoute] = []
            for pair in zip(waypoints, waypoints.dropFirst()) {
                let route = try await calculateRouteSegment(from: pair.0, to: pair.1)
                segments.append(route)
            }
            
            routeSegments = segments
        } catch {
            routeErrorMessage = "No pude calcular la ruta por calles."
            print("Route calculation error: \(error)")
        }
        
        isCalculatingRoute = false
    }

    func calculateNavigationRoute(startCoordinate: CLLocationCoordinate2D) async {
        guard let activeNavigationStop else {
            navigationRoute = nil
            return
        }

        isCalculatingRoute = true
        routeErrorMessage = nil

        do {
            let destination = CLLocationCoordinate2D(
                latitude: activeNavigationStop.store.latitude,
                longitude: activeNavigationStop.store.longitude
            )
            let route = try await calculateRouteSegment(from: startCoordinate, to: destination)
            navigationRoute = route
            routeSegments = [route]
        } catch {
            routeErrorMessage = "No pude calcular la navegacion por calles."
            print("Navigation route calculation error: \(error)")
        }

        isCalculatingRoute = false
    }
    
    private func calculateRouteSegment(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D
    ) async throws -> MKRoute {
        let request = MKDirections.Request()
        request.source = MKMapItem(
            location: CLLocation(latitude: start.latitude, longitude: start.longitude),
            address: nil
        )
        request.destination = MKMapItem(
            location: CLLocation(latitude: end.latitude, longitude: end.longitude),
            address: nil
        )
        request.transportType = .automobile
        request.requestsAlternateRoutes = false
        
        return try await withCheckedThrowingContinuation { continuation in
            MKDirections(request: request).calculate { response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let route = response?.routes.first else {
                    continuation.resume(throwing: RouteCalculationError.noRoute)
                    return
                }
                
                continuation.resume(returning: route)
            }
        }
    }

    private func navigationStepInfo(at visibleIndex: Int) -> RouteNavigationStepInfo? {
        guard let step = navigationRoute?.steps
            .filter({ !$0.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            .dropFirst(visibleIndex)
            .first else {
            return nil
        }

        return RouteNavigationStepInfo(
            instruction: step.instructions,
            distanceText: step.formattedDistance,
            systemImage: step.directionSystemImage
        )
    }
}

private enum RouteCalculationError: Error {
    case noRoute
}

struct RouteNavigationStepInfo: Hashable {
    let instruction: String
    let distanceText: String
    let systemImage: String
}

private extension MKRoute.Step {
    var formattedDistance: String {
        if distance < 1_000 {
            return "\(Int(distance.rounded())) m"
        }

        return String(format: "%.1f km", distance / 1_000)
    }

    var directionSystemImage: String {
        let lowercasedInstruction = instructions.lowercased()

        if lowercasedInstruction.contains("left") || lowercasedInstruction.contains("izquierda") {
            return "arrow.turn.up.left"
        }

        if lowercasedInstruction.contains("right") || lowercasedInstruction.contains("derecha") {
            return "arrow.turn.up.right"
        }

        if lowercasedInstruction.contains("arrive") || lowercasedInstruction.contains("llega") {
            return "mappin.and.ellipse"
        }

        if lowercasedInstruction.contains("u-turn") || lowercasedInstruction.contains("retorno") {
            return "arrow.uturn.left"
        }

        return "arrow.up"
    }
}
