import Foundation

struct Store: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let customerNumber: String
    let segment: String
    let routeName: String
    let address: String
    let visitStatus: VisitStatus
    let pendingAlerts: Int
    let averageReturns: Int
    let trendPercentage: Double
    let lastVisitDaysAgo: Int
    let lastOrderPieces: Int
    let distanceKm: Double
    let estimatedMinutes: Int
    let latitude: Double
    let longitude: Double
    
    // For mock mapping
    let coordinatesMockX: Double
    let coordinatesMockY: Double

    // Foto de la tienda (nombre del asset en xcassets, opcional)
    var imageName: String? = nil
}

enum VisitStatus: String, Hashable, Codable {
    case pending
    case inProgress
    case completed
}
