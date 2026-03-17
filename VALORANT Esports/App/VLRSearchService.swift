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
    
    // Regex matches: <a href="/search/r/(player|team|event)/([0-9]+)/..." ... <img src="([^"]*)"> ... <div class="search-item-title..."> (Title) </div> <div class="search-item-desc..."> (Subtitle) </div>
    private let searchPattern = "<a href=\"/search/r/(player|team)/(\\d+)/[^\"]*\"[^>]*>\\s*<div class=\"search-item-thumb\">\\s*<img src=\"([^\"]*)\">\\s*</div>(?:\\s*<div style=\"[^\"]*\">)?\\s*<div class=\"search-item-title[^\"]*\">\\s*(.*?)\\s*</div>\\s*<div class=\"search-item-desc[^\"]*\">\\s*(.*?)\\s*</div>"
    
    private var currentTask: Task<Void, Never>?
    
    func search(query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuery.count < 2 {
            self.results = []
            return
        }
        
        // Cancel existing in-flight search request
        currentTask?.cancel()
        
        currentTask = Task {
            isSearching = true
            let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmedQuery
            
            guard let url = URL(string: "https://www.vlr.gg/search/?q=\(encodedQuery)") else {
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
                print("Search failed: \(error)")
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
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let desc = nsString.substring(with: match.range(at: 5))
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\t", with: "")
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
