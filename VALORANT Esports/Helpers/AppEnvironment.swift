import Foundation

enum AppEnvironment {
    case simulator
    case device
    
    static var current: AppEnvironment {
        #if targetEnvironment(simulator)
        return .simulator
        #else
        return .device
        #endif
    }
    
    /// Primary: Vercel (public API). Fallback: local self-hosted.
    private static let vercelURL = "https://vlrggapi.vercel.app"
    private static let selfHostedURL = "http://127.0.0.1:3001"
    
    /// Cached resolved base URL for the current session.
    /// Defaults to Vercel until we determine otherwise.
    private(set) static var apiBaseURL: String = vercelURL
    
    /// Resolves the best available API at launch.
    /// Tries Vercel first; if that fails, tries self-hosted.
    static func resolveAPIBaseURL() async {
        // 1. Try Vercel
        if await checkHealth(baseURL: vercelURL) {
            apiBaseURL = vercelURL
            print("✅ Using Vercel API: \(vercelURL)")
            return
        }
        
        // 2. Fallback to self-hosted (only useful in simulator/local dev)
        if await checkHealth(baseURL: selfHostedURL) {
            apiBaseURL = selfHostedURL
            print("⚠️ Vercel unavailable, using self-hosted API: \(selfHostedURL)")
            return
        }
        
        // 3. Neither available — keep Vercel as default and let VLRService
        //    fall through to scraper mode
        apiBaseURL = vercelURL
        print("❌ No API available, will fall back to scraper mode")
    }
    
    /// Checks if the API at a given base URL is reachable.
    static func isAPIAvailable() async -> Bool {
        return await checkHealth(baseURL: apiBaseURL)
    }
    
    /// Quick health check for a specific base URL.
    private static func checkHealth(baseURL: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/v2/health") else { return false }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            }
        } catch {
            print("Health check (\(baseURL)) failed: \(error.localizedDescription)")
        }
        return false
    }
}
