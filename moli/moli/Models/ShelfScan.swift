import Foundation

struct ShelfScan: Identifiable, Hashable {
    let id: UUID
    let storeId: UUID
    let date: Date
    let detectedGaps: Int
    let misplacedProducts: Int
    let expiringProducts: Int
    let expiredProducts: Int
    let confidence: Double
    let explanation: String
    let selectedImageName: String?
}
