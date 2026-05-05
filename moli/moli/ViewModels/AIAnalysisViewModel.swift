import Foundation
import Observation

@MainActor
@Observable
final class AIAnalysisViewModel {
    let store: Store
    private let imagePath: String?
    var isLoading: Bool = true
    var shelfInsights: [AIInsight] = []
    var historyInsights: [AIInsight] = []
    var contextInsights: [AIInsight] = []
    var recommendations: [Recommendation] = []
    var order: Order?
    
    let aiService: AIAnalysisProviding
    let recommendationService: RecommendationService
    
    init(store: Store, imagePath: String? = nil, aiService: AIAnalysisProviding? = nil) {
        let resolvedAIService = aiService ?? MockFoundationModelAIService()
        self.store = store
        self.imagePath = imagePath
        self.aiService = resolvedAIService
        self.recommendationService = RecommendationService(aiService: resolvedAIService)
    }
    
    func analyze() async {
        isLoading = true
        do {
            let insights = try await aiService.analyzeShelf(storeId: store.id, imagePath: imagePath)
            
            self.shelfInsights = insights.filter { $0.type == .expired || $0.type == .gap || $0.type == .expiringSoon }
            self.historyInsights = insights.filter { $0.type == .trend || $0.type == .rotation }
            self.contextInsights = insights.filter { $0.type == .warning }
            
            self.order = try await recommendationService.generateOrder(for: store, insights: insights)
            self.recommendations = self.order?.recommendations ?? []
            
            isLoading = false
        } catch {
            print("Error during analysis: \(error)")
            isLoading = false
        }
    }
    
    var totalRecommendedPieces: Int {
        recommendations.reduce(0) { $0 + $1.editableQuantity }
    }
    
    func confirmOrder() {
        guard var currentOrder = order else {
            return
        }
        
        currentOrder.recommendations = recommendations
        currentOrder.totalPieces = totalRecommendedPieces
        currentOrder.status = .readyToSend
        order = currentOrder
        
        LocalPersistenceService.shared.saveOrder(currentOrder)
    }
}
