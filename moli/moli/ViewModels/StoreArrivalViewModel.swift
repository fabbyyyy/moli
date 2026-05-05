import Foundation
import Observation

@Observable
final class StoreArrivalViewModel {
    var store: Store
    var isHandsFreeEnabled: Bool = false
    
    init(store: Store) {
        self.store = store
    }
}
