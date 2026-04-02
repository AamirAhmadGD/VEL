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
    
    /// The primary API base URL.
    /// In simulator, we try the local Mac server at port 3001.
    /// On device, we try the known Vercel deployment.
    static var apiBaseURL: String {
        switch current {
        case .simulator:
            return "http://127.0.0.1:3001"
        case .device:
            return "https://vlrggapi.vercel.app"
        }
    }
    
    /// Checks if the API is currently reachable and responding with 200.
    static func isAPIAvailable() async -> Bool {
        guard let url = URL(string: "\(apiBaseURL)/v2/health") else { return false }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.0 // Short timeout for availability check
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            }
        } catch {
            print("API Check (\(apiBaseURL)) failed: \(error.localizedDescription)")
        }
        return false
    }
}
