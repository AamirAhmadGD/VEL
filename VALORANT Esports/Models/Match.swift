//
//  Match.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import Foundation

// Temporary Mock Match struct used by MatchDetailView until fully implemented
struct Match: Identifiable {
    let id = UUID()
    let teamA: String
    let teamB: String
    let time: String
    let tournament: String
    var bestOf: Int = 3
    var scoreA: Int = 0
    var scoreB: Int = 0
    
    var isLive: Bool {
        time.uppercased() == "LIVE"
    }

    var isUpcoming: Bool {
        time.uppercased() != "LIVE" && time.uppercased() != "FINAL"
    }
}

// API Response Models for /v2/match
struct VLRMatchResponse: Codable {
    let data: VLRMatchData
}

struct VLRMatchData: Codable {
    let segments: [VLRMatch]
}

struct VLRMatch: Codable, Identifiable {
    var id: String { match_page }
    
    let team1: String
    let team2: String
    let flag1: String
    let flag2: String
    let match_page: String
    
    // Optional because upcoming matches don't have scores
    let score1: String?
    let score2: String?
    
    // Upcoming matches
    let time_until_match: String?
    let match_event: String?
    let match_series: String?
    
    // Result matches
    let time_completed: String?
    let tournament_name: String?
    let round_info: String?
    let tournament_icon: String?
    
    // Helper accessors
    var displayTime: String {
        if let comp = time_completed { return comp }
        return time_until_match ?? "TBD"
    }
    
    var displayTournament: String {
        return (match_event ?? tournament_name)?.uppercased() ?? "VALORANT EVENT"
    }
    
    var t1ScoreText: String { score1 ?? "-" }
    var t2ScoreText: String { score2 ?? "-" }
    
    // Determine the winning team based on score (1 for team1, 2 for team2, nil if tie or unplayed)
    var winner: Int? {
        guard let s1 = score1, let s2 = score2,
              let s1Int = Int(s1), let s2Int = Int(s2) else { return nil }
        if s1Int > s2Int { return 1 }
        if s2Int > s1Int { return 2 }
        return nil
    }
    
    // Derive a flagCDN url from vlr's "flag_kr" -> "kr.png"
    var team1FlagURL: URL? {
        let code = flag1.replacingOccurrences(of: "flag_", with: "")
        return URL(string: "https://flagcdn.com/w40/\(code).png")
    }
    
    var team2FlagURL: URL? {
        let code = flag2.replacingOccurrences(of: "flag_", with: "")
        return URL(string: "https://flagcdn.com/w40/\(code).png")
    }
    
    // Extract the raw numeric ID from the match_page string (e.g., "/626544/nongshim-redforce-vs..." -> "626544")
    var numeric_id: String {
        let components = match_page.components(separatedBy: "/")
        if components.count > 1, let id = components.first(where: { Int($0) != nil }) {
            return id
        }
        return ""
    }
}

// MARK: - Match Details API Response Models

struct VLRMatchDetailResponse: Codable {
    let data: VLRMatchDetailData
}

struct VLRMatchDetailData: Codable {
    let segments: [VLRMatchDetailSegment]
}

struct VLRMatchDetailSegment: Codable {
    let teams: [VLRMatchDetailTeam]
}

struct VLRMatchDetailTeam: Codable {
    let name: String
    let logo: String
}
