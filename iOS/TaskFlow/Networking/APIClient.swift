import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

struct APIClient: Sendable {
    let baseURL: URL
    var session: URLSession = .shared

    private static let decoder = JSONDecoder()
    private static let encoder = JSONEncoder()

    func get<Response: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> Response {
        try await send(method: .get, path: path, queryItems: queryItems, body: nil)
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let data: Data
        do {
            data = try Self.encoder.encode(body)
        } catch {
            throw APIError.invalidRequest
        }
        return try await send(method: .post, path: path, queryItems: [], body: data)
    }

    func patch<Response: Decodable>(_ path: String) async throws -> Response {
        try await send(method: .patch, path: path, queryItems: [], body: nil)
    }

    private func send<Response: Decodable>(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem],
        body: Data?
    ) async throws -> Response {
        let request = try makeRequest(method: method, path: path, queryItems: queryItems, body: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError {
            throw APIError.network(error.code)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let payload = try? Self.decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.server(
                statusCode: httpResponse.statusCode,
                reason: payload?.reason,
                fieldErrors: payload?.fieldErrors ?? [:]
            )
        }

        do {
            return try Self.decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func makeRequest(method: HTTPMethod, path: String, queryItems: [URLQueryItem], body: Data?) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw APIError.invalidRequest
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidRequest
        }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
