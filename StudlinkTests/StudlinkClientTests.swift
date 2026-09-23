import XCTest
@testable import Studlink

final class StudlinkClientTests: XCTestCase {
    func test_setsUserAgentAndSucceeds() async throws {
        let url = try XCTUnwrap(URL(string: "https://studlink-proof.pro/ping"))
        actor Box {
            var request: URLRequest?
            func keep(_ value: URLRequest) { request = value }
            func current() -> URLRequest? { request }
        }
        let box = Box()
        let transport = StubTransport { request in
            await box.keep(request)
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            ) else {
                throw URLError(.badServerResponse)
            }
            return (Data("{\"ok\":true}".utf8), response)
        }
        let client = StudlinkClient(transport: transport)
        let data = try await client.get(url)
        XCTAssertEqual(String(data: data, encoding: .utf8), "{\"ok\":true}")
        let sent = await box.current()
        XCTAssertEqual(sent?.value(forHTTPHeaderField: "User-Agent"), StudlinkClient.userAgent)
        XCTAssertEqual(sent?.timeoutInterval, StudlinkClient.timeout)
    }

    func test_retriesTransientThenSucceeds() async throws {
        let url = try XCTUnwrap(URL(string: "https://studlink-proof.pro/retry"))
        actor Hits {
            var count = 0
            func next() -> Int {
                count += 1
                return count
            }
            func value() -> Int { count }
        }
        let hits = Hits()
        let transport = StubTransport { _ in
            let n = await hits.next()
            if n == 1 {
                throw URLError(.timedOut)
            }
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            ) else {
                throw URLError(.badServerResponse)
            }
            return (Data("ok".utf8), response)
        }
        let client = StudlinkClient(transport: transport)
        let data = try await client.get(url)
        XCTAssertEqual(String(data: data, encoding: .utf8), "ok")
        let count = await hits.value()
        XCTAssertEqual(count, 2)
    }

    func test_notFoundIsNotRetried() async throws {
        let url = try XCTUnwrap(URL(string: "https://studlink-proof.pro/missing"))
        actor Hits {
            var count = 0
            func next() -> Int {
                count += 1
                return count
            }
            func value() -> Int { count }
        }
        let hits = Hits()
        let transport = StubTransport { _ in
            _ = await hits.next()
            guard let response = HTTPURLResponse(
                url: url,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            ) else {
                throw URLError(.badServerResponse)
            }
            return (Data(), response)
        }
        let client = StudlinkClient(transport: transport)
        do {
            _ = try await client.get(url)
            XCTFail("expected notFound")
        } catch let error as StudlinkTransportError {
            XCTAssertEqual(error, .notFound)
        }
        let count = await hits.value()
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSON_isDecodeError() throws {
        let client = StudlinkClient(transport: StubTransport { _ in
            throw URLError(.badURL)
        })
        XCTAssertThrowsError(try client.decode(Data("nope".utf8), as: CardWire.self)) { error in
            XCTAssertEqual(error as? StudlinkTransportError, .decode)
        }
    }
}

private struct StubTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}
