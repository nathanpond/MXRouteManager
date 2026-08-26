//
//  MockURLProtocol.swift
//  MXRouteManagerTests
//
//  A URLProtocol stub plus request-capture helpers, shared test
//  infrastructure for MXRouteClient tests (this plan and 03-03). No
//  @Test functions live here — just the harness.
//

import Foundation

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// A fresh, ephemeral session with `MockURLProtocol` registered — scoped to
/// this session only. `URLSession.shared` ignores `protocolClasses`, so a
/// mock registered there would silently let real traffic out.
func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

func makeResponse(_ status: Int, url: URL) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
}

/// A constant test base URL, so a mistakenly un-mocked request cannot reach
/// the real API.
let mockBaseURL = URL(string: "https://api.mxroute.test")!

extension URLRequest {
    /// `URLProtocol` receives POST bodies as a stream and `httpBody` is
    /// `nil` in that case — this drains `httpBodyStream` into `Data` so
    /// body assertions don't silently pass against `nil`.
    var capturedBody: Data? {
        if let httpBody {
            return httpBody
        }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                data.append(buffer, count: bytesRead)
            } else {
                break
            }
        }
        return data
    }
}
