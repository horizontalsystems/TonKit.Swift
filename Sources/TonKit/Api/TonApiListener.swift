import Combine
import EventSource
import Foundation
import HsToolKit
import StreamURLSessionTransport
import TonStreamingAPI
import TonSwift

class TonApiListener {
    private let streamingAPI: StreamingAPI
    private let logger: Logger?

    private var address: Address?
    private let transactionSubject = PassthroughSubject<String, Never>()

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

        streamingAPI = StreamingAPI(host: URL(string: serverUrl))

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

        task = Task { [weak self, streamingAPI, address] in
            do {
                self?.state = .connecting

                let stream = try await streamingAPI.accountsTransactionsStream(accounts: [address.toRaw()])

                self?.state = .connected

                for try await events in stream {
                    self?.handleReceived(events: events)
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

    private func handleReceived(events: [EventSource.Event]) {
        logger?.debug("-> receive events: \(events.count): \(events.compactMap { $0.event }.joined(separator: ", "))")

        guard let messageEvent = events.last(where: { $0.event == "message" }), let eventData = messageEvent.data?.data(using: .utf8) else {
            return
        }

        do {
            let eventTransaction = try jsonDecoder.decode(EventSource.Transaction.self, from: eventData)
            logger?.debug("-> transaction: \(eventTransaction.txHash)")
            transactionSubject.send(eventTransaction.txHash)
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

    var transactionPublisher: AnyPublisher<String, Never> {
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

extension TonApiListener {
    struct StreamingAPI {
        enum Error: Swift.Error {
            case incorrectUrl
        }

        private let transport = StreamURLSessionTransport(urlSessionConfiguration: .default)
        private let host: URL?

        init(host: URL?) {
            self.host = host
        }

        func accountsTransactionsStream(accounts: [String]) async throws -> AsyncThrowingStream<[EventSource.Event], Swift.Error> {
            let request = AccountsTransactionsRequest(accounts: accounts)
            let urlRequest = try await urlRequest(request: request)

            let stream = try await EventSource.eventSource {
                let (bytes, _) = try await self.transport.send(request: urlRequest)
                return bytes
            }
            return stream
        }

        private func urlRequest(request: Request) async throws -> URLRequest {
            guard let host else {
                throw Error.incorrectUrl
            }

            var urlComponents = URLComponents(url: host, resolvingAgainstBaseURL: true)
            urlComponents?.path = request.path
            urlComponents?.queryItems = request.queryItems

            guard let url = urlComponents?.url else {
                throw Error.incorrectUrl
            }

            return URLRequest(url: url)
        }
    }

    struct AccountsTransactionsRequest: Request {
        private let accounts: [String]

        init(accounts: [String]) {
            self.accounts = accounts
        }

        var path: String {
            "/v2/sse/accounts/transactions"
        }

        var queryItems: [URLQueryItem] {
            let value = accounts.joined(separator: ",")
            return [URLQueryItem(name: "accounts", value: value)]
        }
    }
}
