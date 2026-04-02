//
//  VLRSearchService.swift
//  VALORANT Esports
//
//  Created by AI on 3/14/26.
//

import Foundation
import Combine

@MainActor
class VLRSearchService: ObservableObject {
    @Published var results: [VLRSearchResult] = []
    @Published var isSearching = false
    
    /// Statically look up a team ID from a team name by scraping VLR.gg search results.
    /// Used when a team name is passed instead of a numeric ID (e.g., from Match Details).
    static func lookupTeamID(name: String) async -> String? {
        let encodedQuery = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        
        // 1. Try API first
        if let apiUrl = URL(string: "\(AppEnvironment.apiBaseURL)/v2/search?q=\(encodedQuery)") {
            do {
                let (data, response) = try await URLSession.shared.data(for: URLRequest(url: apiUrl))
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    let apiRes = try JSONDecoder().decode(VLRAPISearchResponse.self, from: data)
                    // Find the exact name match or first team
                    if let exactMatch = apiRes.data.results.first(where: { $0.type == "team" && $0.title.lowercased() == name.lowercased() }) {
                        return exactMatch.id
                    }
                    if let firstTeam = apiRes.data.results.first(where: { $0.type == "team" }) {
                        return firstTeam.id
                    }
                }
            } catch {
                print("API lookupTeamID failed: \(error)")
            }
        }
        
        // 2. Fallback to Scraper
        guard let url = URL(string: "https://www.vlr.gg/search/?q=\(encodedQuery)") else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let htmlString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        let pattern = "<a href=\"/search/r/team/(\\d+)/[^\"]*\"[^>]*>.*?<div class=\"search-item-title[^\"]*\">\\s*(.*?)\\s*</div>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }
        
        let nsString = htmlString as NSString
        let matches = regex.matches(in: htmlString, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            let foundID = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
            let foundTitle = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if foundTitle.lowercased() == name.lowercased() {
                return foundID
            }
        }
        
        // Fallback: return the very first team ID we found
        if let firstMatch = matches.first, firstMatch.numberOfRanges >= 2 {
            return nsString.substring(with: firstMatch.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    // Improved regex to handle VLR's current HTML structure more robustly
    private let searchPattern = "<a href=\"/search/r/(player|team)/(\\d+)/[^\"]*\"[^>]*>.*?<div class=\"search-item-thumb\">.*?<img src=\"([^\"]*)\">.*?<div class=\"search-item-title[^\"]*\">\\s*(.*?)\\s*</div>\\s*<div class=\"search-item-desc[^\"]*\">\\s*(.*?)\\s*</div>"
    
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Search Logic
    
    func search(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.count < 2 {
            self.results = []
            return
        }
        
        currentTask?.cancel()
        
        currentTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            
            isSearching = true
            let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedQuery
            
            // 1. Try API first
            let baseURL = AppEnvironment.apiBaseURL
            if let apiUrl = URL(string: "\(baseURL)/v2/search?q=\(encodedQuery)") {
                do {
                    var request = URLRequest(url: apiUrl)
                    request.timeoutInterval = 5.0
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, !Task.isCancelled {
                        let apiRes = try JSONDecoder().decode(VLRAPISearchResponse.self, from: data)
                        let parsed = apiRes.data.results.compactMap { item -> VLRSearchResult? in
                            // Map API type string to enum
                            let type: VLRSearchResultType = item.type == "team" ? .team : .player
                            if item.type == "event" { return nil } // Skip events for now as per app UI
                            
                            return VLRSearchResult(
                                type: type,
                                vlrID: item.id,
                                title: item.title,
                                subtitle: item.subtitle,
                                imageURL: URL(string: item.img_url)
                            )
                        }
                        
                        if !Task.isCancelled {
                            self.results = parsed
                            self.isSearching = false
                            return
                        }
                    }
                } catch {
                    print("API Search failed, falling back to scraper: \(error)")
                }
            }
            
            // 2. Fallback to Scraper
            guard !Task.isCancelled else { return }
            
            let vlrUrlString = "https://www.vlr.gg/search/?q=\(encodedQuery)"
            guard let url = URL(string: vlrUrlString) else {
                isSearching = false
                return
            }
            
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard !Task.isCancelled else { return }
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                      let htmlString = String(data: data, encoding: .utf8) else {
                    isSearching = false
                    return
                }
                
                let parsedResults = parseHTML(htmlString)
                
                if !Task.isCancelled {
                    self.results = parsedResults
                }
                
            } catch {
                print("Scraper search failed: \(error)")
            }
            
            if !Task.isCancelled {
                isSearching = false
            }
        }
    }
    
    private func parseHTML(_ html: String) -> [VLRSearchResult] {
        guard let regex = try? NSRegularExpression(pattern: searchPattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }
        
        let nsString = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
        
        var parsedResults: [VLRSearchResult] = []
        
        for match in matches {
            guard match.numberOfRanges == 6 else { continue }
            
            let rawTypeStr = nsString.substring(with: match.range(at: 1)).lowercased()
            let type: VLRSearchResultType = rawTypeStr == "player" ? .player : .team
            
            let id = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            
            var imgPath = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
            if imgPath.hasPrefix("//") {
                imgPath = "https:" + imgPath
            }
            let imgURL = URL(string: imgPath)
            
            let title = nsString.substring(with: match.range(at: 4))
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\t", with: "")
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                // Remove leftover VLR status badges (e.g. " inactive", " inactive ", "inactive")
                .replacingOccurrences(of: "(?i)\\s*inactive\\s*", with: "", options: .regularExpression)
                // Collapse multiple spaces to one
                .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let desc = nsString.substring(with: match.range(at: 5))
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\t", with: "")
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression) // Strip nested HTML tags like <span>
                .replacingOccurrences(of: "(?i)\\s*inactive\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let result = VLRSearchResult(
                type: type,
                vlrID: id,
                title: title,
                subtitle: desc.isEmpty ? (type == .team ? "Team" : "Player") : desc,
                imageURL: imgURL
            )
            parsedResults.append(result)
        }
        
        return parsedResults
    }
}

// MARK: - API Response Models for Search

struct VLRAPISearchResponse: Decodable {
    let status: String
    let data: VLRAPISearchData
}

struct VLRAPISearchData: Decodable {
    let results: [VLRAPISearchResult]
}

struct VLRAPISearchResult: Decodable {
    let type: String
    let id: String
    let title: String
    let subtitle: String
    let img_url: String
    let url: String
}
