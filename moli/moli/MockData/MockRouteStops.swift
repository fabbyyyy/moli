import Foundation

struct MockRouteStops {
    static let todayRoute: [RouteStop] = [
        RouteStop(id: UUID(), store: MockStores.elPino, stopNumber: 6, isCompleted: false, isCurrent: true),
        RouteStop(id: UUID(), store: MockStores.elSol, stopNumber: 7, isCompleted: false, isCurrent: false),
        RouteStop(id: UUID(), store: MockStores.guadalupe, stopNumber: 8, isCompleted: false, isCurrent: false)
    ]
}
