import Foundation

struct Feedback: Identifiable, Hashable {
    let id: UUID
    let recommendationId: UUID
    let storeId: UUID
    let productId: UUID
    let originalQuantity: Int
    let finalQuantity: Int
    let decision: RecommendationStatus
    let sellerNote: String?
    let createdAt: Date
}
