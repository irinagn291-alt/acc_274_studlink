import Foundation

/// Typed transport errors. A 404 is not retried.
enum StudlinkTransportError: Error, Equatable, Sendable {
    case timeout
    case transport
    case httpStatus(Int)
    case notFound
    case decode
    case cancelled
}

protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionTransport: HTTPTransport {
    let session: URLSession

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Owns session policy for this app. No remote catalog. User-Agent on every request.
struct StudlinkClient: Sendable {
    static let userAgent = "Studlink/1.0 (iOS; +https://studlink-proof.pro)"
    static let timeout: TimeInterval = 15

    private let transport: any HTTPTransport

    init(transport: any HTTPTransport) {
        self.transport = transport
    }

    init(session: URLSession? = nil) {
        if let session {
            transport = URLSessionTransport(session: session)
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = Self.timeout
            configuration.httpAdditionalHeaders = ["User-Agent": Self.userAgent]
            transport = URLSessionTransport(session: URLSession(configuration: configuration))
        }
    }

    func data(for request: URLRequest) async throws -> Data {
        try await perform(request, attempt: 0)
    }

    func get(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = Self.timeout
        return try await data(for: request)
    }

    func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try ChainBookCodec.decoder().decode(type, from: data)
        } catch {
            throw StudlinkTransportError.decode
        }
    }

    private func perform(_ request: URLRequest, attempt: Int) async throws -> Data {
        try Task.checkCancellation()
        var stamped = request
        if stamped.value(forHTTPHeaderField: "User-Agent") == nil {
            stamped.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        }
        if stamped.timeoutInterval <= 0 || stamped.timeoutInterval > Self.timeout {
            stamped.timeoutInterval = Self.timeout
        }
        do {
            let (data, response) = try await transport.data(for: stamped)
            try Self.validate(response)
            return data
        } catch is CancellationError {
            throw StudlinkTransportError.cancelled
        } catch let error as StudlinkTransportError {
            throw error
        } catch {
            if attempt == 0, Self.isTransient(error) {
                return try await perform(request, attempt: 1)
            }
            if (error as? URLError)?.code == .timedOut {
                throw StudlinkTransportError.timeout
            }
            throw StudlinkTransportError.transport
        }
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 404 {
            throw StudlinkTransportError.notFound
        }
        guard (200..<300).contains(http.statusCode) else {
            throw StudlinkTransportError.httpStatus(http.statusCode)
        }
    }

    private static func isTransient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}
