import Foundation

enum OrderStatus: String, Hashable {
    case draft
    case readyToSend
    case sentSimulated
    case pendingSync
}

struct Order: Identifiable, Hashable {
    let id: UUID
    let store: Store
    var recommendations: [Recommendation]
    let date: Date
    var totalPieces: Int
    var avoidedWasteMXN: Double
    var status: OrderStatus
}
