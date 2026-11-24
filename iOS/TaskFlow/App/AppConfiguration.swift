import Foundation

enum AppConfiguration {
    private static let fallbackBaseURL = URL(string: "http://localhost:8080")!

    static var apiBaseURL: URL {
        if let override = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: override) {
            return url
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
           !value.isEmpty,
           let url = URL(string: value) {
            return url
        }
        return fallbackBaseURL
    }
}
