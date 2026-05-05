import Foundation

protocol AIAnalysisProviding {
    func analyzeShelf(storeId: UUID, imagePath: String?) async throws -> [AIInsight]
    func generateRecommendation(storeId: UUID, insights: [AIInsight]) async throws -> [Recommendation]
    func generateCoachInstructions(storeId: UUID) async throws -> [CoachInstruction]
}
