import Foundation

enum VLRNetworkError: Error {
    case invalidURL
    case noData
    case decodingError
}

struct VLRNetworkHelper {
    static let shared = VLRNetworkHelper()
    
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
    
    func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw VLRNetworkError.invalidURL
        }
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024,
                                   diskCapacity: 50 * 1024 * 1024,
                                   diskPath: "vlr-html-cache")

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 10.0

        let (data, _) = try await URLSession(configuration: config).data(for: request)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw VLRNetworkError.decodingError
        }
        
        return html
    }
}
