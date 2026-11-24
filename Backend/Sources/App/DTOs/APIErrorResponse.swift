import Vapor

struct APIErrorResponse: Content {
    let error: Bool
    let reason: String
    let fieldErrors: [String: String]?
}

struct ValidationFailure: Error {
    var reason = "Validation failed."
    let fieldErrors: [String: String]
}
