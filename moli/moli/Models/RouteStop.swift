import Foundation

struct RouteStop: Identifiable, Hashable {
    let id: UUID
    let store: Store
    let stopNumber: Int
    var isCompleted: Bool
    var isCurrent: Bool
}
