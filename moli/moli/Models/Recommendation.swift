import Foundation

enum RecommendationStatus: String, Hashable, Codable {
    case pending
    case accepted
    case modified
    case rejected
}

struct Recommendation: Identifiable, Hashable, Codable {
    let id: UUID
    let product: Product
    let suggestedQuantity: Int
    var editableQuantity: Int
    let reason: String
    let confidence: Double
    var status: RecommendationStatus
}
