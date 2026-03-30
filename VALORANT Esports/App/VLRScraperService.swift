import Foundation
import SwiftUI
import Combine

@MainActor
final class VLRScraperService: ObservableObject {
    static let shared = VLRScraperService()
    private init() {}
    
    @Published var isLoading = false
    @Published var error: String? = nil
    
    func scrapeEventDetails(eventID: String) async -> VLRScrapedEvent? {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "https://www.vlr.gg/event/\(eventID)") else {
            error = "Invalid URL"
            isLoading = false
            return nil
        }
        
        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else {
                error = "Failed to decode HTML"
                isLoading = false
                return nil
            }
            
            let bracketSets = parseBrackets(html: html)
            let teams = parseTeams(html: html)
            let placements = parsePlacements(html: html)
            
            isLoading = false
            return VLRScrapedEvent(bracketSets: bracketSets, teams: teams, placements: placements)
            
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return nil
        }
    }
    
    private func parseBrackets(html: String) -> [VLRBracketSet] {
        var sets: [VLRBracketSet] = []
        let nsString = html as NSString
        let overallRange = NSRange(location: 0, length: nsString.length)
        
        // 1. Identify bracket containers
        let setRegex = try! NSRegularExpression(pattern: "<div class=\"bracket-container (mod-[^\"]+)\">", options: [])
        let setMatches = setRegex.matches(in: html, options: [], range: overallRange)
        
        for (setIndex, setMatch) in setMatches.enumerated() {
            let typeClass = nsString.substring(with: setMatch.range(at: 1))
            let title = typeClass.contains("upper") ? "Upper Bracket" : (typeClass.contains("lower") ? "Lower Bracket" : "Bracket")
            
            // Bounded range for this set
            let start = setMatch.range.location
            let nextSetStart = (setIndex + 1 < setMatches.count) ? setMatches[setIndex + 1].range.location : nsString.length
            let setRange = NSRange(location: start, length: nextSetStart - start)
            let setContent = nsString.substring(with: setRange)
            let nsSetContent = setContent as NSString
            
            var columns: [VLRBracketColumn] = []
            
            // 2. Identify columns within this set
            let colRegex = try! NSRegularExpression(pattern: "<div class=\"bracket-col mod-\\d+\">\\s*<div class=\"bracket-col-label\">\\s*([^<]+)", options: [])
            let colMatches = colRegex.matches(in: setContent, options: [], range: NSRange(location: 0, length: nsSetContent.length))
            
            for (colIndex, colMatch) in colMatches.enumerated() {
                let colLabel = nsSetContent.substring(with: colMatch.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                let colStart = colMatch.range.location
                let nextColStart = (colIndex + 1 < colMatches.count) ? colMatches[colIndex + 1].range.location : nsSetContent.length
                let colRange = NSRange(location: colStart, length: nextColStart - colStart)
                let colContent = nsSetContent.substring(with: colRange)
                let nsColContent = colContent as NSString
                
                var matches: [VLRBracketMatch] = []
                
                // 3. Identify matches within this column
                let matchRegex = try! NSRegularExpression(pattern: "<a class=\"bracket-item\\s*[^\"]*\" title=\"([^\"]*)\" href=\"([^\"]*)\">", options: [])
                let matchMatches = matchRegex.matches(in: colContent, options: [], range: NSRange(location: 0, length: nsColContent.length))
                
                for (mIndex, mMatch) in matchMatches.enumerated() {
                    let href = nsColContent.substring(with: mMatch.range(at: 2))
                    
                    let mStart = mMatch.range.location
                    let nextMStart = (mIndex + 1 < matchMatches.count) ? matchMatches[mIndex + 1].range.location : nsColContent.length
                    let mRange = NSRange(location: mStart, length: nextMStart - mStart)
                    let mContent = nsColContent.substring(with: mRange)
                    let nsMContent = mContent as NSString
                    
                    // 4. Teams parsing within the match item
                    // Using a more robust regex that handles optional parts better
                    let teamRegex = try! NSRegularExpression(pattern: "<div class=\"bracket-item-team\\s*([^\" >]*)[^>]*data-team-id=\"(\\d+)\">.*?<img src=\"([^\"]*)\">.*?<span>([^<]+)</span>.*?<div class=\"bracket-item-team-score\">\\s*([^<\\s]+)", options: [.dotMatchesLineSeparators])
                    let tMatches = teamRegex.matches(in: mContent, options: [], range: NSRange(location: 0, length: nsMContent.length))
                    
                    var t1: VLRBracketTeam? = nil
                    var t2: VLRBracketTeam? = nil
                    
                    if tMatches.count >= 1 {
                        let tm = tMatches[0]
                        let classes = nsMContent.substring(with: tm.range(at: 1))
                        let logo = "https:" + nsMContent.substring(with: tm.range(at: 3))
                        let name = nsMContent.substring(with: tm.range(at: 4))
                        let score = nsMContent.substring(with: tm.range(at: 5))
                        t1 = VLRBracketTeam(name: name, score: score, isWinner: classes.contains("mod-winner"), logoURL: logo)
                    }
                    if tMatches.count >= 2 {
                        let tm = tMatches[1]
                        let classes = nsMContent.substring(with: tm.range(at: 1))
                        let logo = "https:" + nsMContent.substring(with: tm.range(at: 3))
                        let name = nsMContent.substring(with: tm.range(at: 4))
                        let score = nsMContent.substring(with: tm.range(at: 5))
                        t2 = VLRBracketTeam(name: name, score: score, isWinner: classes.contains("mod-winner"), logoURL: logo)
                    }
                    
                    // 5. Time and status
                    let statusRegex = try! NSRegularExpression(pattern: "<div class=\" bracket-item-status.*?\">\\s*<div>\\s*<span></span>\\s*([^<\\s][^<]*)", options: [.dotMatchesLineSeparators])
                    let stMatch = statusRegex.firstMatch(in: mContent, options: [], range: NSRange(location: 0, length: nsMContent.length))
                    let timeStr = stMatch.map { nsMContent.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines) }
                    
                    matches.append(VLRBracketMatch(id: href, team1: t1, team2: t2, time: timeStr, status: nil))
                }
                columns.append(VLRBracketColumn(label: colLabel, matches: matches))
            }
            sets.append(VLRBracketSet(title: title, columns: columns))
        }
        
        return sets
    }
    
    private func parseTeams(html: String) -> [VLREventTeamSeeding] {
        var teams: [VLREventTeamSeeding] = []
        let nsString = html as NSString
        
        let teamRegex = try! NSRegularExpression(pattern: "<div class=\"wf-card event-team\">.*?<a class=\"event-team-name\" href=\"([^\"]+)\">\\s*([^<]+).*?<img src=\"([^\"]+)\" class=\"event-team-players-mask-team\">.*?<div class=\"event-team-note wf-module-item\">\\s*<a[^>]*>([^<]+)</a>", options: [.dotMatchesLineSeparators])
        let matches = teamRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let id = nsString.substring(with: match.range(at: 1))
            let name = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            let logo = "https:" + nsString.substring(with: match.range(at: 3))
            let seeding = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)
            
            teams.append(VLREventTeamSeeding(id: id, name: name, logoURL: logo, seeding: seeding))
        }
        
        return teams
    }
    
    private func parsePlacements(html: String) -> [VLREventPlacement] {
        var placements: [VLREventPlacement] = []
        let nsString = html as NSString
        
        // Find placement table rows
        let rowRegex = try! NSRegularExpression(pattern: "<div class=\"row[^\"]*\" role=\"row\">\\s*<div class=\"cell\" role=\"cell\"[^>]*>\\s*(.*?(?:<sup>.*?</sup>)?)\\s*</div>\\s*<div class=\"cell\" role=\"cell\" style=\"justify-content: flex-end\">\\s*(.*?)\\s*</div>\\s*<div class=\"cell\" role=\"cell\"[^>]*>\\s*<a class=\"wf-module-item[^\"]*\" href=\"/team/(\\d+)/([^\"]*)\">.*?<img src=\"([^\"]*)\".*?<span>([^<]+)</span>", options: [.dotMatchesLineSeparators])
        let matches = rowRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let rankRaw = nsString.substring(with: match.range(at: 1))
                .replacingOccurrences(of: "<sup>", with: "")
                .replacingOccurrences(of: "</sup>", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let prize = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            let teamLogo = "https:" + nsString.substring(with: match.range(at: 5))
            let teamName = nsString.substring(with: match.range(at: 6)).trimmingCharacters(in: .whitespacesAndNewlines)
            
            placements.append(VLREventPlacement(rank: rankRaw, teamName: teamName, teamLogoURL: teamLogo, prize: prize))
        }
        
        return placements
    }
}
