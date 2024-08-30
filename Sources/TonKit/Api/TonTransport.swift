//import Foundation
//import StreamURLSessionTransport
//import TonAPI
//
//struct TonTransport {
//    lazy var transport: StreamURLSessionTransport = .init(urlSessionConfiguration: urlSessionConfiguration)
//
//    lazy var streamingTransport: StreamURLSessionTransport = .init(urlSessionConfiguration: streamingUrlSessionConfiguration)
//
//    var urlSessionConfiguration: URLSessionConfiguration {
//        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = 60
//        configuration.timeoutIntervalForResource = 60
//        return configuration
//    }
//
//    var streamingUrlSessionConfiguration: URLSessionConfiguration {
//        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = TimeInterval(Int.max)
//        configuration.timeoutIntervalForResource = TimeInterval(Int.max)
//        return configuration
//    }
//}
