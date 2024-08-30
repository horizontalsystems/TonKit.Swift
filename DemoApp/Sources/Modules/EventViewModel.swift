import Combine
import Foundation
import TonKit
import TonSwift

class EventViewModel: ObservableObject {
    private let tonKit: Kit
    private var cancellables = Set<AnyCancellable>()

    @Published var syncState: SyncState
    @Published var events: [Event]

    init(tonKit: Kit) {
        self.tonKit = tonKit

        syncState = tonKit.syncState
        events = tonKit.events(tagQueries: [])

        print("EVENTS: \(events.count)")
    }
}
