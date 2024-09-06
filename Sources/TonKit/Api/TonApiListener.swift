import Combine
import EventSource
import Foundation
import HsToolKit
import StreamURLSessionTransport
import TonStreamingAPI
import TonSwift

class TonApiListener {
    private let client: TonStreamingAPI.Client
    private let logger: Logger?

    private var address: Address?
    private let transactionSubject = PassthroughSubject<Void, Never>()

    private var state: State = .disconnected {
        didSet {
            logger?.debug("Listener: \(state)")
        }
    }

    private var task: Task<Void, Never>?
    private let jsonDecoder = JSONDecoder()

    init(network: Network, logger: Logger?) {
        let serverUrl: String

        switch network {
        case .mainNet: serverUrl = "https://tonapi.io"
        case .testNet: serverUrl = "https://testnet.tonapi.io"
        }

        let transport = StreamURLSessionTransport(urlSessionConfiguration: .default)
        client = TonStreamingAPI.Client(serverURL: URL(string: serverUrl)!, transport: transport, middlewares: [])

        self.logger = logger
    }

    deinit {
        task?.cancel()
    }

    private func connect() {
        guard let address else {
            state = .disconnected
            return
        }

        switch state {
        case .connected, .connecting: return
        default: ()
        }

        task?.cancel()
        task = nil

        task = Task { [weak self, client, address] in
            do {
                self?.state = .connecting

                let stream = try await EventSource.eventSource {
                    let response = try await client.getTransactions(
                        query: .init(accounts: [address.toRaw()])
                    )
                    return try response.ok.body.text_event_hyphen_stream
                }

                guard !Task.isCancelled else { return }

                self?.state = .connected

                for try await events in stream {
                    self?.handleReceivedEvents(events)
                }

                self?.state = .disconnected

                guard !Task.isCancelled else { return }

                self?.connect()
            } catch {
                self?.logger?.error(error.localizedDescription)

                self?.state = .disconnected

                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.connect()
            }
        }
    }

    private func handleReceivedEvents(_ events: [EventSource.Event]) {
        logger?.debug("-> receive events: \(events.count): \(events.compactMap { $0.event }.joined(separator: ", "))")

        guard let messageEvent = events.last(where: { $0.event == "message" }), let eventData = messageEvent.data?.data(using: .utf8) else {
            return
        }

        do {
            let eventTransaction = try jsonDecoder.decode(EventSource.Transaction.self, from: eventData)
            logger?.debug("-> transaction: \(eventTransaction.txHash)")
            transactionSubject.send()
        } catch {}
    }
}

extension TonApiListener: IApiListener {
    func start(address: Address) {
        self.address = address
        connect()
    }

    func stop() {
        address = nil
        task?.cancel()
        task = nil
    }

    var transactionPublisher: AnyPublisher<Void, Never> {
        transactionSubject.eraseToAnyPublisher()
    }
}

extension TonApiListener {
    enum State {
        case connecting
        case connected
        case disconnected
    }
}
