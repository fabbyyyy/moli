import Foundation
import Observation

@Observable
final class ConfirmationViewModel {
    let store: Store
    let pieces: Int
    let wasteAvoided: Double
    
    init(store: Store, pieces: Int, wasteAvoided: Double) {
        self.store = store
        self.pieces = pieces
        self.wasteAvoided = wasteAvoided
    }
}
