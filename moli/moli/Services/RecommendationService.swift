import Foundation

class RecommendationService {
    let aiService: AIAnalysisProviding
    
    init(aiService: AIAnalysisProviding = MockFoundationModelAIService()) {
        self.aiService = aiService
    }
    
    func generateOrder(for store: Store, insights: [AIInsight]) async throws -> Order {
        let recommendations = try await aiService.generateRecommendation(storeId: store.id, insights: insights)
        
        let totalPieces = recommendations.reduce(0) { $0 + $1.editableQuantity }
        
        return Order(
            id: UUID(),
            store: store,
            recommendations: recommendations,
            date: Date(),
            totalPieces: totalPieces,
            avoidedWasteMXN: 86.0, // Mock calculation based on expired goods prevented
            status: .draft
        )
    }
}
