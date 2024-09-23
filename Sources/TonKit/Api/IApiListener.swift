import Combine
import TonSwift

protocol IApiListener {
    func start(address: Address)
    func stop()
    var transactionPublisher: AnyPublisher<String, Never> { get }
}
