import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidRequest
    case network(URLError.Code)
    case server(statusCode: Int, reason: String?, fieldErrors: [String: String])
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            "The request could not be created."
        case .network(.notConnectedToInternet):
            "You appear to be offline. Check your connection and try again."
        case .network(.timedOut):
            "The server took too long to respond. Please try again."
        case .network:
            "Can't reach the TaskFlow server. Make sure the backend is running."
        case let .server(statusCode, reason, _):
            reason ?? "The server returned an error (\(statusCode))."
        case .invalidResponse:
            "The server sent a response the app couldn't read."
        }
    }

    var fieldErrors: [String: String] {
        if case let .server(_, _, fieldErrors) = self {
            return fieldErrors
        }
        return [:]
    }
}

struct APIErrorResponse: Decodable {
    let reason: String?
    let fieldErrors: [String: String]?
}
