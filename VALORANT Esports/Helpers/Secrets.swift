import Foundation

enum Secrets {
    /// The Riot API key loaded from the main bundle (Info.plist / Build Settings).
    /// To make this work, ensure you have:
    /// 1. Added Secrets.xcconfig to your Project-wide configurations.
    /// 2. Added a key 'RIOT_API_KEY' with value '$(RIOT_API_KEY)' in your Target's Info tab.
    static var riotAPIKey: String? {
        return Bundle.main.infoDictionary?["RIOT_API_KEY"] as? String
    }
}
