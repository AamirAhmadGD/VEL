import Foundation
import SwiftUI
import Combine

@MainActor
final class VLRScraperService: ObservableObject {
    static let shared = VLRScraperService()
    private init() {}
    
    @Published var isLoading = false
    @Published var error: String? = nil
    
    func scrapeUpcomingMatches() async -> [VLRMatch] {
        do {
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: "https://www.vlr.gg")
            let nsString = html as NSString
            
            // Regex for upcoming match items on homepage
            let matchRegex = try NSRegularExpression(pattern: "<a class=\"wf-module-item.*?\" href=\"([^\"]+)\">.*?<div class=\"h-match-team\">(.*?)</div>.*?<div class=\"h-match-team\">(.*?)</div>.*?<div class=\"h-match-preview-event\">\\s*([^<]+).*?<div class=\"h-match-preview-series\">\\s*([^<]+).*?<div class=\"h-match-eta mod-upcoming\">\\s*([^<]+)", options: [.dotMatchesLineSeparators])
            
            let matches = matchRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            var results: [VLRMatch] = []
            
            for match in matches {
                let urlPath = nsString.substring(with: match.range(at: 1))
                let t1Content = nsString.substring(with: match.range(at: 2)) as NSString
                let t2Content = nsString.substring(with: match.range(at: 3)) as NSString
                let event = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)
                let series = nsString.substring(with: match.range(at: 5)).trimmingCharacters(in: .whitespacesAndNewlines)
                let eta = nsString.substring(with: match.range(at: 6)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Extract team name and flag from inner HTML
                let teamNameRegex = try NSRegularExpression(pattern: "<div class=\"h-match-team-name\">\\s*([^<]+)", options: [])
                let flagRegex = try NSRegularExpression(pattern: "<span class=\"flag mod-([^\"]+)\">", options: [])
                
                let t1Name = teamNameRegex.firstMatch(in: t1Content as String, options: [], range: NSRange(location: 0, length: t1Content.length))
                    .map { t1Content.substring(with: $0.range(at: 1)) }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "TBD"
                let t1Flag = flagRegex.firstMatch(in: t1Content as String, options: [], range: NSRange(location: 0, length: t1Content.length))
                    .map { "flag_" + t1Content.substring(with: $0.range(at: 1)).replacingOccurrences(of: "mod-", with: "").replacingOccurrences(of: "16", with: "_") } ?? ""
                
                let t2Name = teamNameRegex.firstMatch(in: t2Content as String, options: [], range: NSRange(location: 0, length: t2Content.length))
                    .map { t2Content.substring(with: $0.range(at: 1)) }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "TBD"
                let t2Flag = flagRegex.firstMatch(in: t2Content as String, options: [], range: NSRange(location: 0, length: t2Content.length))
                    .map { "flag_" + t2Content.substring(with: $0.range(at: 1)).replacingOccurrences(of: "mod-", with: "").replacingOccurrences(of: "16", with: "_") } ?? ""
                
                results.append(VLRMatch(
                    team1: t1Name,
                    team2: t2Name,
                    flag1: t1Flag,
                    flag2: t2Flag,
                    match_page: urlPath,
                    score1: nil,
                    score2: nil,
                    time_until_match: eta,
                    match_event: event,
                    match_series: series,
                    time_completed: nil,
                    tournament_name: event,
                    round_info: series,
                    tournament_icon: nil,
                    status: "upcoming"
                ))
            }
            return results
        } catch {
            print("Failed to scrape upcoming matches: \(error)")
            return []
        }
    }

    func scrapeLiveMatches() async -> [VLRMatch] {
        do {
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: "https://www.vlr.gg")
            let nsString = html as NSString
            
            // Regex for live match items on homepage
            let liveMatchRegex = try NSRegularExpression(pattern: "<a class=\"wf-module-item.*?\" href=\"([^\"]+)\">.*?<div class=\"h-match-team\">(.*?)</div>.*?<div class=\"h-match-team\">(.*?)</div>.*?<div class=\"h-match-preview-event\">\\s*([^<]+).*?<div class=\"h-match-preview-series\">\\s*([^<]+).*?<div class=\"h-match-eta mod-live\">\\s*([^<]+)", options: [.dotMatchesLineSeparators])
            
            let matches = liveMatchRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            var results: [VLRMatch] = []
            
            for match in matches {
                let urlPath = nsString.substring(with: match.range(at: 1))
                let t1Content = nsString.substring(with: match.range(at: 2)) as NSString
                let t2Content = nsString.substring(with: match.range(at: 3)) as NSString
                let event = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)
                let series = nsString.substring(with: match.range(at: 5)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                let teamNameRegex = try NSRegularExpression(pattern: "<div class=\"h-match-team-name\">\\s*([^<]+)", options: [])
                let scoreRegex = try NSRegularExpression(pattern: "<div class=\"h-match-team-score\">\\s*([^<]+)", options: [])
                
                let t1Name = teamNameRegex.firstMatch(in: t1Content as String, options: [], range: NSRange(location: 0, length: t1Content.length))
                    .map { t1Content.substring(with: $0.range(at: 1)) }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "TBD"
                let t1Score = scoreRegex.firstMatch(in: t1Content as String, options: [], range: NSRange(location: 0, length: t1Content.length))
                    .map { t1Content.substring(with: $0.range(at: 1)) }?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let t2Name = teamNameRegex.firstMatch(in: t2Content as String, options: [], range: NSRange(location: 0, length: t2Content.length))
                    .map { t2Content.substring(with: $0.range(at: 1)) }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "TBD"
                let t2Score = scoreRegex.firstMatch(in: t2Content as String, options: [], range: NSRange(location: 0, length: t2Content.length))
                    .map { t2Content.substring(with: $0.range(at: 1)) }?.trimmingCharacters(in: .whitespacesAndNewlines)
                
                results.append(VLRMatch(
                    team1: t1Name,
                    team2: t2Name,
                    flag1: "",
                    flag2: "",
                    match_page: urlPath,
                    score1: t1Score,
                    score2: t2Score,
                    time_until_match: "LIVE",
                    match_event: event,
                    match_series: series,
                    time_completed: nil,
                    tournament_name: event,
                    round_info: series,
                    tournament_icon: nil,
                    status: "live"
                ))
            }
            return results
        } catch {
            print("Failed to scrape live matches: \(error)")
            return []
        }
    }

    func scrapeMatchResults(page: Int) async -> [VLRMatch] {
        do {
            let url = "https://www.vlr.gg/matches/results?page=\(page)"
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: url)
            let nsString = html as NSString
            
            // Regex for results matches
            let resultRegex = try NSRegularExpression(pattern: "<a class=\"wf-module-item.*?\" href=\"([^\"]+)\">.*?<div class=\"match-item-vs-team-name\">\\s*([^<]+).*?<div class=\"match-item-vs-team-score\">\\s*([^<]+).*?<div class=\"match-item-vs-team-name\">\\s*([^<]+).*?<div class=\"match-item-vs-team-score\">\\s*([^<]+).*?<div class=\"match-item-event\">.*?<img src=\"([^\"]+)\".*?</div>\\s*([^<]+).*?<div class=\"match-item-event-series\">\\s*([^<]+).*?<div class=\"ml-eta\">\\s*([^<]+)", options: [.dotMatchesLineSeparators])
            
            let matches = resultRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            var results: [VLRMatch] = []
            
            for match in matches {
                let urlPath = nsString.substring(with: match.range(at: 1))
                let t1Name = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                let t1Score = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                let t2Name = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)
                let t2Score = nsString.substring(with: match.range(at: 5)).trimmingCharacters(in: .whitespacesAndNewlines)
                let icon = "https:" + nsString.substring(with: match.range(at: 6))
                let event = nsString.substring(with: match.range(at: 7)).trimmingCharacters(in: .whitespacesAndNewlines)
                let series = nsString.substring(with: match.range(at: 8)).trimmingCharacters(in: .whitespacesAndNewlines)
                let ago = nsString.substring(with: match.range(at: 9)).trimmingCharacters(in: .whitespacesAndNewlines) + " ago"
                
                results.append(VLRMatch(
                    team1: t1Name,
                    team2: t2Name,
                    flag1: "",
                    flag2: "",
                    match_page: urlPath,
                    score1: t1Score,
                    score2: t2Score,
                    time_until_match: nil,
                    match_event: event,
                    match_series: series,
                    time_completed: ago,
                    tournament_name: event,
                    round_info: series,
                    tournament_icon: icon,
                    status: "completed"
                ))
            }
            return results
        } catch {
            print("Failed to scrape match results: \(error)")
            return []
        }
    }

    func scrapeMatchesForEvent(eventID: String, eventName: String?) async -> [VLRMatch] {
        do {
            let url = "https://www.vlr.gg/event/matches/\(eventID)/?series_id=all"
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: url)
            let nsString = html as NSString
            
            // Regex for event match rows
            let matchRegex = try NSRegularExpression(pattern: "<a class=\"wf-module-item.*?\" href=\"([^\"]+)\">.*?<div class=\"match-item-vs-team-name\">\\s*([^<]+).*?<div class=\"match-item-vs-team-score\">\\s*([^<]+).*?<div class=\"match-item-vs-team-name\">\\s*([^<]+).*?<div class=\"match-item-vs-team-score\">\\s*([^<+]+).*?<div class=\"match-item-event-series\">\\s*([^<]+).*?<div class=\"ml-status\">\\s*([^<]+)", options: [.dotMatchesLineSeparators])
            
            let matches = matchRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            var results: [VLRMatch] = []
            
            for match in matches {
                let urlPath = nsString.substring(with: match.range(at: 1))
                let t1Name = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                let t1Score = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                let t2Name = nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespacesAndNewlines)
                let t2Score = nsString.substring(with: match.range(at: 5)).trimmingCharacters(in: .whitespacesAndNewlines)
                let series = nsString.substring(with: match.range(at: 6)).trimmingCharacters(in: .whitespacesAndNewlines)
                let status = nsString.substring(with: match.range(at: 7)).lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                results.append(VLRMatch(
                    team1: t1Name,
                    team2: t2Name,
                    flag1: "",
                    flag2: "",
                    match_page: urlPath,
                    score1: t1Score == "0" && status != "completed" && status != "final" ? nil : t1Score,
                    score2: t2Score == "0" && status != "completed" && status != "final" ? nil : t2Score,
                    time_until_match: status == "upcoming" ? "Upcoming" : (status == "live" ? "LIVE" : nil),
                    match_event: eventName,
                    match_series: series,
                    time_completed: (status == "completed" || status == "final") ? "Completed" : nil,
                    tournament_name: eventName,
                    round_info: series,
                    tournament_icon: nil,
                    status: status
                ))
            }
            return results
        } catch {
            print("Failed to scrape event matches: \(error)")
            return []
        }
    }

    func scrapeMatchDetails(matchID: String) async -> VLRMatchDetailSegment? {
        do {
            let url = "https://www.vlr.gg/\(matchID)"
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: url)
            let nsString = html as NSString
            
            // 1. Header Info (Date, Patch, Status)
            let date = regexFirstMatch(pattern: "<div class=\"match-header-date\">\\s*([^<]+)", in: html) ?? ""
            let patch = regexFirstMatch(pattern: "<div class=\"match-header-note\">\\s*([^<]+)", in: html) ?? ""
            let status = regexFirstMatch(pattern: "<div class=\"match-header-vs-note\">\\s*([^<]+)", in: html) ?? ""
            
            // 2. Event Info
            let eventName = regexFirstMatch(pattern: "<div class=\"match-header-super\">.*?<div[^>]*>.*?<a[^>]*>\\s*([^<]+)", in: html) ?? ""
            let eventSeries = regexFirstMatch(pattern: "<div class=\"match-header-event-series\">\\s*([^<]+)", in: html) ?? ""
            let eventLogo = regexFirstMatch(pattern: "<div class=\"match-header-event\">.*?<img src=\"([^\"]+)\"", in: html).map { "https:" + $0 } ?? ""
            
            let event = VLRMatchDetailEvent(name: eventName, series: eventSeries, logo: eventLogo)
            
            // 3. Teams
            var teams: [VLRMatchDetailTeam] = []
            let teamBlocksRegex = try NSRegularExpression(pattern: "<div class=\"match-header-link-name mod-[^>]*\">\\s*<div class=\"wf-title-med\">\\s*([^<]+)\\s*</div>\\s*<div class=\"wf-title-light\">\\s*([^<]*)", options: [])
            let teamMatches = teamBlocksRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            let scoreRegex = try NSRegularExpression(pattern: "<div class=\"match-header-vs-score\">.*?<span class=\"([^\"]*)\">\\s*(\\d+).*?<span class=\"([^\"]*)\">\\s*(\\d+)", options: [.dotMatchesLineSeparators])
            let scoreMatch = scoreRegex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            
            for (idx, match) in teamMatches.enumerated() {
                let name = nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                let tag = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                var score = ""
                var isWinner = false
                
                if let sm = scoreMatch {
                    if idx == 0 {
                        score = nsString.substring(with: sm.range(at: 2))
                        isWinner = nsString.substring(with: sm.range(at: 1)).contains("winner")
                    } else {
                        score = nsString.substring(with: sm.range(at: 4))
                        isWinner = nsString.substring(with: sm.range(at: 3)).contains("winner")
                    }
                }
                
                teams.append(VLRMatchDetailTeam(name: name, tag: tag, logo: nil, score: score, is_winner: isWinner))
            }
            
            // 4. Maps & Stats (Simplified for now, will expand in next step)
            let maps = parseMatchMaps(html: html)
            
            return VLRMatchDetailSegment(
                match_id: matchID,
                event: event,
                date: date,
                patch: patch,
                status: status,
                teams: teams,
                streams: nil,
                vods: nil,
                maps: maps,
                head_to_head: nil,
                performance: nil
            )
        } catch {
            print("Failed to scrape match details: \(error)")
            return nil
        }
    }

    private func parseMatchMaps(html: String) -> [VLRMatchDetailMap] {
        var maps: [VLRMatchDetailMap] = []
        let nsString = html as NSString
        
        // Identify game blocks
        let gameRegex = try! NSRegularExpression(pattern: "<div class=\"vm-stats-game\" data-game-id=\"(\\d+)\">", options: [])
        let matches = gameRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for (idx, match) in matches.enumerated() {
            let start = match.range.location
            let end = (idx + 1 < matches.count) ? matches[idx+1].range.location : nsString.length
            let content = nsString.substring(with: NSRange(location: start, length: end - start))
            
            let mapName = regexFirstMatch(pattern: "<div class=\"map\">\\s*<span>\\s*([^<\\s]+)", in: content) ?? "Map \(idx+1)"
            
            // Parse scoreboard for this map
            let players = parseMapPlayers(html: content)
            
            maps.append(VLRMatchDetailMap(
                map_name: mapName,
                picked_by: nil,
                duration: nil,
                score: nil,
                score_ct: nil,
                score_t: nil,
                score_ot: nil,
                players: players,
                rounds: nil
            ))
        }
        
        return maps
    }

    private func parseMapPlayers(html: String) -> VLRMatchDetailMapPlayers {
        // Split HTML into two tables (one for each team)
        let tables = html.components(separatedBy: "<table class=\"wf-table-inset mod-overview\">")
        if tables.count < 3 { return VLRMatchDetailMapPlayers(team1: nil, team2: nil) }
        
        func parseTable(_ tableHtml: String) -> [VLRMatchDetailPlayer] {
            var players: [VLRMatchDetailPlayer] = []
            let rowRegex = try! NSRegularExpression(pattern: "<tr[^>]*>\\s*<td class=\"mod-player\">.*?<a href=\"/player/(\\d+)/([^\"]*)\">.*?<div class=\"text-of\">([^<]+)</div>.*?<td class=\"mod-agents\">.*?<img title=\"([^\"]+)\".*?<td class=\"mod-stat\">\\s*<span class=\"side mod-both\">([^<]+)</span>.*?<td class=\"mod-stat\">\\s*<span class=\"side mod-both\">([^<]+)</span>.*?<td class=\"mod-vlr-kills\">\\s*<span class=\"side mod-both\">([^<]+)</span>.*?<td class=\"mod-vlr-deaths\">\\s*<span class=\"side mod-both\">([^<]+)</span>.*?<td class=\"mod-vlr-assists\">\\s*<span class=\"side mod-both\">([^<]+)</span>.*?<td class=\"mod-stat\">\\s*<span class=\"side mod-both\">([^<]+)</span>.*?<td class=\"mod-stat\">\\s*<span class=\"side mod-both\">([^<]+)</span>.*?<td class=\"mod-stat\">\\s*<span class=\"side mod-both\">([^<]+)</span>", options: [.dotMatchesLineSeparators])
            
            let rows = rowRegex.matches(in: tableHtml, options: [], range: NSRange(location: 0, length: (tableHtml as NSString).length))
            for row in rows {
                let ns = tableHtml as NSString
                players.append(VLRMatchDetailPlayer(
                    player_id: ns.substring(with: row.range(at: 1)),
                    name: ns.substring(with: row.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines),
                    agent: ns.substring(with: row.range(at: 4)),
                    rating: ns.substring(with: row.range(at: 5)),
                    acs: ns.substring(with: row.range(at: 6)),
                    kills: ns.substring(with: row.range(at: 7)),
                    deaths: ns.substring(with: row.range(at: 8)),
                    assists: ns.substring(with: row.range(at: 9)),
                    kd_diff: nil,
                    kast: ns.substring(with: row.range(at: 10)),
                    adr: ns.substring(with: row.range(at: 11)),
                    hs_pct: ns.substring(with: row.range(at: 12)),
                    fk: nil,
                    fd: nil,
                    fk_diff: nil
                ))
            }
            return players
        }
        
        return VLRMatchDetailMapPlayers(
            team1: parseTable(tables[1]),
            team2: parseTable(tables[2])
        )
    }

    private func regexFirstMatch(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: ns.length)) else { return nil }
        if match.numberOfRanges > 1 {
            return ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    func scrapeEvents() async -> [VLREvent] {
        do {
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: "https://www.vlr.gg/events")
            let nsString = html as NSString
            
            let eventRegex = try NSRegularExpression(pattern: "<a class=\"wf-card.*?\" href=\"([^\"]+)\">.*?<img src=\"([^\"]+)\".*?<div class=\"wf-title\">\\s*([^<]+).*?<div class=\"event-item-desc-item mod-status\">\\s*([^<]+)", options: [.dotMatchesLineSeparators])
            
            let matches = eventRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            var results: [VLREvent] = []
            
            for match in matches {
                let urlPath = nsString.substring(with: match.range(at: 1))
                let logo = "https:" + nsString.substring(with: match.range(at: 2))
                let name = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                let statusRaw = nsString.substring(with: match.range(at: 4)).lowercased()
                
                let status = statusRaw.contains("ongoing") ? "ongoing" : (statusRaw.contains("upcoming") ? "upcoming" : "completed")
                
                results.append(VLREvent(
                    title: name,
                    status: status,
                    prize: "", // No prize info available
                    dates: "", // No date info available
                    region: "", // No region info available
                    thumb: logo,
                    urlPath: urlPath
                ))
            }
            return results
        } catch {
            print("Failed to scrape events: \(error)")
            return []
        }
    }

    func scrapePastEvents(page: Int) async -> [VLREvent] {
        do {
            let url = "https://www.vlr.gg/events/?completed=1&page=\(page)"
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: url)
            let nsString = html as NSString
            
            let eventRegex = try NSRegularExpression(pattern: "<a class=\"wf-card.*?\" href=\"([^\"]+)\">.*?<img src=\"([^\"]+)\".*?<div class=\"wf-title\">\\s*([^<]+).*?<div class=\"event-item-desc-item mod-status\">\\s*([^<]+)", options: [.dotMatchesLineSeparators])
            
            let matches = eventRegex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            var results: [VLREvent] = []
            
            for match in matches {
                let urlPath = nsString.substring(with: match.range(at: 1))
                let logo = "https:" + nsString.substring(with: match.range(at: 2))
                let name = nsString.substring(with: match.range(at: 3)).trimmingCharacters(in: .whitespacesAndNewlines)
                
                results.append(VLREvent(
                    title: name,
                    status: "completed",
                    prize: "",
                    dates: "",
                    region: "",
                    thumb: logo,
                    urlPath: urlPath
                ))
            }
            return results
        } catch {
            print("Failed to scrape past events: \(error)")
            return []
        }
    }

    func scrapePlayerProfile(id: String) async -> VLRPlayerProfile? {
        do {
            let url = "https://www.vlr.gg/player/\(id)"
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: url)
            
            let name = regexFirstMatch(pattern: "<h1 class=\"wf-title\">\\s*([^<]+)", in: html) ?? ""
            let realName = regexFirstMatch(pattern: "<div class=\"player-real-name\">\\s*([^<]+)", in: html) ?? ""
            let team = regexFirstMatch(pattern: "<div class=\"player-header-team\">.*?<div[^>]*>\\s*([^<]+)", in: html) ?? ""
            let teamLogo = regexFirstMatch(pattern: "<div class=\"player-header-team\">.*?<img src=\"([^\"]+)\"", in: html).map { "https:" + $0 } ?? ""
            let region = regexFirstMatch(pattern: "<div class=\"ge-text-light\">\\s*([^<]+)", in: html) ?? ""
            
            return VLRPlayerProfile(
                id: id,
                name: name,
                real_name: realName,
                avatar: nil,
                country: region,
                social_links: nil,
                current_team: VLRPlayerTeam(name: team, tag: nil, logo: teamLogo, joined: nil),
                past_teams: nil,
                agent_stats: nil,
                event_placements: nil,
                news: nil,
                total_winnings: nil
            )
        } catch {
            print("Failed to scrape player profile: \(error)")
            return nil
        }
    }

    func scrapeTeamProfile(id: String) async -> VLRTeamProfile? {
        do {
            let url = "https://www.vlr.gg/team/\(id)"
            let html = try await VLRNetworkHelper.shared.fetchHTML(from: url)
            
            let name = regexFirstMatch(pattern: "<h1 class=\"wf-title\">\\s*([^<]+)", in: html) ?? ""
            let tag = regexFirstMatch(pattern: "<h2 class=\"wf-title mod-subs\">\\s*([^<]+)", in: html) ?? ""
            let region = regexFirstMatch(pattern: "<div class=\"ge-text-light\">\\s*([^<]+)", in: html) ?? ""
            let logo = regexFirstMatch(pattern: "<div class=\"team-header-logo\">.*?<img src=\"([^\"]+)\"", in: html).map { "https:" + $0 } ?? ""
            
            return VLRTeamProfile(
                id: id,
                name: name,
                tag: tag,
                logo: logo,
                region: region,
                social_links: nil,
                roster: nil,
                event_placements: nil,
                news: nil,
                total_winnings: nil
            )
        } catch {
            print("Failed to scrape team profile: \(error)")
            return nil
        }
    }
}
