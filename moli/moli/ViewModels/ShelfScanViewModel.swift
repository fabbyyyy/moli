import Foundation
import Observation

@Observable
final class ShelfScanViewModel {
    let store: Store
    
    init(store: Store) {
        self.store = store
    }
}
