import Vapor

struct APIErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch {
            return makeResponse(for: error, request: request)
        }
    }

    private func makeResponse(for error: any Error, request: Request) -> Response {
        let status: HTTPResponseStatus
        let body: APIErrorResponse
        var headers: HTTPHeaders = [:]

        switch error {
        case let failure as ValidationFailure:
            status = .badRequest
            body = APIErrorResponse(error: true, reason: failure.reason, fieldErrors: failure.fieldErrors)
        case let abort as any AbortError:
            status = abort.status
            headers = abort.headers
            body = APIErrorResponse(error: true, reason: abort.reason, fieldErrors: nil)
        default:
            request.logger.report(error: error)
            status = .internalServerError
            body = APIErrorResponse(error: true, reason: "Something went wrong.", fieldErrors: nil)
        }

        let response = Response(status: status, headers: headers)
        do {
            try response.content.encode(body, as: .json)
        } catch {
            request.logger.report(error: error)
        }
        return response
    }
}
