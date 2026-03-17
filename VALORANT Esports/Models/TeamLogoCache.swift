//
//  TeamLogoCache.swift
//  VALORANT Esports
//
//  Created by AI on 3/14/26.
//

import Foundation

actor TeamLogoCache {
    static let shared = TeamLogoCache()
    
    // Memory cache of team name (lowercased) to logo URL string
    private var cache: [String: String] = [:]
    
    // In-flight fetches to avoid duplicating API requests for the same match ID
    private var inProgress: [String: Task<Void, Never>] = [:]
    
    private init() {}
    
    /// Returns the cached logo URL string for a given team name.
    /// If not present, it fetches the match details using `matchID` to extract
    /// BOTH teams' logos, caches them, and then returns the requested logo.
    func getLogo(for teamName: String, matchID: String) async -> String? {
        let key = teamName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Check if we already have it
        if let logo = cache[key], !logo.isEmpty {
            return logo
        }
        
        // 2. We don't have it. If a fetch for this match is already running, wait for it.
        if let existingTask = inProgress[matchID] {
            await existingTask.value
            return cache[key]
        }
        
        // 3. Otherwise, spawn a new fetch task
        let fetchTask = Task {
            await fetchAndCacheLogos(matchID: matchID)
        }
        
        inProgress[matchID] = fetchTask
        await fetchTask.value
        inProgress.removeValue(forKey: matchID)
        // 4. Cache and return the default logo if still missing, unless TBD
        if let fetchedLogo = cache[key], !fetchedLogo.isEmpty {
            return fetchedLogo
        } else if key != "tbd" && key != "tbc" {
            let defaultLogo = "https://www.vlr.gg/img/vlr/tmp/vlr.png"
            cache[key] = defaultLogo
            return defaultLogo
        }
        
        return nil
    }
    
    private func fetchAndCacheLogos(matchID: String) async {
        guard !matchID.isEmpty, let url = URL(string: "https://vlrggapi.vercel.app/v2/match/details?match_id=\(matchID)") else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            let result = try await MainActor.run { try JSONDecoder().decode(VLRMatchDetailResponse.self, from: data) }
            
            // The API returns segments. For standard matches, usually segment[0] contains the teams
            if let firstSegment = result.data.segments.first {
                for team in firstSegment.teams {
                    let teamKey = team.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    guard teamKey != "tbd" && teamKey != "tbc" else { continue }
                    
                    let parsedLogo = (team.logo ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if parsedLogo.isEmpty || !parsedLogo.contains("owcdn.net") {
                        cache[teamKey] = "https://www.vlr.gg/img/vlr/tmp/vlr.png"
                    } else {
                        cache[teamKey] = parsedLogo
                    }
                }
            }
        } catch {
            print("[\(matchID)] Failed to fetch or decode match details for logo cache: \(error)")
        }
    }
}
