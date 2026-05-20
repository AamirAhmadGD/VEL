//
//  TeamLogoCache.swift
//  VALORANT Esports
//
//  Created by AI on 3/14/26.
//

import Foundation

actor TeamLogoCache {
    static let shared = TeamLogoCache()
    private let userDefaultsKey = "customTeamLogos"
    
    // Hardcoded dictionary of top/popular global teams (lowercase) to their VLR.gg logo URL.
    private var cache: [String: String] = [
        "sentinels": "https://owcdn.net/img/60451cf9416ee.png",
        "fnatic": "https://owcdn.net/img/62875027c8e06.png",
        "paper rex": "https://owcdn.net/img/60d1edcf291aa.png",
        "loud": "https://owcdn.net/img/62112acaf0b38.png",
        "nrg": "https://owcdn.net/img/60cbcbd2a07dd.png",
        "drx": "https://owcdn.net/img/61e680a37315d.png",
        "krx": "https://owcdn.net/img/61e680a37315d.png",
        "100 thieves": "https://owcdn.net/img/64670cbdf32dd.png",
        "cloud9": "https://owcdn.net/img/64670cfe002e3.png",
        "leviatan": "https://owcdn.net/img/63c22b1154c5e.png", // Normalized accent
        "kru": "https://owcdn.net/img/60ec4ab2f3dc1.png",
        "heretics": "https://owcdn.net/img/63d8ff10b7410.png",
        "navi": "https://owcdn.net/img/612089ffb5cd5.png",
        "natus vincere": "https://owcdn.net/img/612089ffb5cd5.png",
        "liquid": "https://owcdn.net/img/63bd69c5e27a6.png",
        "gen.g": "https://owcdn.net/img/63251c6b8eb6a.png",
        "fpx": "https://owcdn.net/img/625fd9f8b4ae9.png",
        "funplus phoenix": "https://owcdn.net/img/625fd9f8b4ae9.png",
        "edg": "https://owcdn.net/img/62a2bb8488e0b.png",
        "edward": "https://owcdn.net/img/62a2bb8488e0b.png",
        "trace": "https://owcdn.net/img/66b033e696f8c.png",
        "g2": "https://owcdn.net/img/60b6426ddc0ee.png",
        "t1": "https://owcdn.net/img/601dcffcd4ec3.png",
        "global": "https://owcdn.net/img/619e09d1dddc2.png",
        "mibr": "https://owcdn.net/img/63d76e46af497.png",
        "evil geniuses": "https://owcdn.net/img/64670d06bce8d.png",
        "furia": "https://owcdn.net/img/60eecd333a921.png",
        "bbl": "https://owcdn.net/img/63d905fd2c2be.png",
        "fut": "https://owcdn.net/img/63d25bb5c34e3.png",
        "giants": "https://owcdn.net/img/63c5d79673a5a.png",
        "giantx": "https://owcdn.net/img/63c5d79673a5a.png",
        "vitality": "https://owcdn.net/img/63d25a80db60b.png",
        "zeta division": "https://owcdn.net/img/62767df3c9429.png",
        "detonation focusme": "https://owcdn.net/img/61dc0dadd2b10.png",
        "rrq": "https://owcdn.net/img/63f1be119d675.png",
        "rex regum qeon": "https://owcdn.net/img/63f1be119d675.png",
        "secret": "https://owcdn.net/img/63c0aefb4ceea.png",
        "bilibili": "https://owcdn.net/img/641e7f67be847.png",
        "gentle mates": "https://owcdn.net/img/6461ad58ba004.png",
        "karmine corp": "https://owcdn.net/img/63dbbdf06443c.png",
        "envy": "https://owcdn.net/img/60ef2e09b5ce5.png",
        "eternal fire": "https://owcdn.net/img/641c8d5a8bd86.png",
        "pcific": "https://owcdn.net/img/6146c82098dca.png",
        "nongshim redforce": "https://owcdn.net/img/6262b9f6b9c92.png",
        "varrel": "https://owcdn.net/img/6215b2e9e6ec1.png",
        "full sense": "https://owcdn.net/img/6182c40c81afb.png",
        "xi lai": "https://owcdn.net/img/663cdd225e2e8.png", // Normalized from xi lai gaming
        "dragon ranger": "https://owcdn.net/img/646df1a0eac7d.png",
        "tec": "https://owcdn.net/img/629f6d7ab5080.png",
        "titan": "https://owcdn.net/img/629f6d7ab5080.png",
        "jd": "https://owcdn.net/img/63bc755b4104c.png",
        "tyloo": "https://owcdn.net/img/646df4d2d6c6e.png",
        "all gamers": "https://owcdn.net/img/627fdb96e7436.png",
        "nova": "https://owcdn.net/img/646df1a0eac7d.png",
        "wolves": "https://owcdn.net/img/66b2b528be63a.png"
    ]
    
    /// Tracks teams currently being fetched to avoid duplicate requests
    private var inFlightFetches: Set<String> = []
    /// Teams we already tried and failed to find a logo for
    private var failedLookups: Set<String> = []
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedCache = try? JSONDecoder().decode([String: String].self, from: data) {
            for (k, v) in savedCache {
                cache[k] = v
            }
        }
    }
    
    /// Returns the cached logo URL string for a team.
    /// If not cached, triggers a background fetch from VLR search.
    func getLogo(for teamName: String, matchID: String) -> String? {
        let key = normalizeTeamName(teamName)
        
        // Return cached logo immediately if we have one
        if let cached = cache[key] {
            return cached
        }
        
        // If we already failed for this team, don't retry
        if failedLookups.contains(key) {
            return nil
        }
        
        // If not already fetching, kick off a background fetch
        if !inFlightFetches.contains(key) {
            inFlightFetches.insert(key)
            Task {
                await fetchLogoFromVLR(teamName: teamName, key: key)
            }
        }
        
        return nil
    }
    
    /// Allows other parts of the app to dynamically add to the dictionary.
    func saveLogo(for teamName: String, url: String) {
        let key = normalizeTeamName(teamName)
        if !key.isEmpty && key != "tbd" && key != "tbc" && !url.isEmpty {
            cache[key] = url
            persistToDisk()
        }
    }
    
    /// Fetches a team's logo by searching VLR.gg and parsing the first team result's thumbnail.
    private func fetchLogoFromVLR(teamName: String, key: String) async {
        defer { inFlightFetches.remove(key) }
        
        let encoded = teamName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? teamName
        guard let url = URL(string: "https://www.vlr.gg/search/?q=\(encoded)") else {
            failedLookups.insert(key)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let html = String(data: data, encoding: .utf8) else {
                failedLookups.insert(key)
                return
            }
            
            // Look for the first team result's image
            // Pattern: <a href="/search/r/team/... <img src="//owcdn.net/img/xxxxx.png">
            let pattern = "<a href=\"/search/r/team/\\d+/[^\"]*\"[^>]*>.*?<img src=\"([^\"]*)\""
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
                failedLookups.insert(key)
                return
            }
            
            let nsString = html as NSString
            if let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: nsString.length)),
               match.numberOfRanges >= 2 {
                var imgSrc = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if imgSrc.hasPrefix("//") {
                    imgSrc = "https:" + imgSrc
                }
                if !imgSrc.isEmpty {
                    cache[key] = imgSrc
                    persistToDisk()
                    return
                }
            }
            
            failedLookups.insert(key)
        } catch {
            failedLookups.insert(key)
        }
    }
    
    private func normalizeTeamName(_ name: String) -> String {
        var normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Aggressively normalize common prefixes/suffixes to fix VLR naming divergence
        normalized = normalized.replacingOccurrences(of: " esports club", with: "")
        normalized = normalized.replacingOccurrences(of: " esports", with: "")
        normalized = normalized.replacingOccurrences(of: " gaming", with: "")
        normalized = normalized.replacingOccurrences(of: " team", with: "")
        normalized = normalized.replacingOccurrences(of: "wuxi titan", with: "titan")
        normalized = normalized.replacingOccurrences(of: "krü", with: "kru")
        normalized = normalized.replacingOccurrences(of: "leviatán", with: "leviatan")
        return normalized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func persistToDisk() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
