import Foundation
import Observation

@MainActor
@Observable
final class RecommendationViewModel {
    let store: Store
    let allInsights: [AIInsight]
    
    var recommendations: [Recommendation] = []
    var isLoading: Bool = true
    var order: Order?
    
    let recommendationService = RecommendationService()
    
    var totalPieces: Int {
        recommendations.reduce(0) { $0 + $1.editableQuantity }
    }
    
    init(store: Store, allInsights: [AIInsight]) {
        self.store = store
        self.allInsights = allInsights
    }
    
    func loadRecommendations() async {
        isLoading = true
        do {
            self.order = try await recommendationService.generateOrder(for: store, insights: allInsights)
            self.recommendations = self.order?.recommendations ?? []
            isLoading = false
        } catch {
            print("Error: \(error)")
            isLoading = false
        }
    }
    
    func updateQuantity(for id: UUID, quantity: Int) {
        if let index = recommendations.firstIndex(where: { $0.id == id }) {
            recommendations[index].editableQuantity = quantity
            recommendations[index].status = .modified
        }
    }
    
    func confirmOrder() {
        if var currentOrder = order {
            currentOrder.recommendations = recommendations
            currentOrder.totalPieces = totalPieces
            currentOrder.status = .readyToSend
            order = currentOrder
            LocalPersistenceService.shared.saveOrder(currentOrder)
        }
    }
}
