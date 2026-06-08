//
//  Match.swift
//  VALORANT Esports
//
//  Created by Aamir Ahmad on 2/2/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Match List Response Models (v2/match)

struct VLRMatchResponse: Codable, Sendable {
    let status: String?
    let data: VLRMatchData
}

struct VLRMatchData: Codable, Sendable {
    let status: Int?
    let segments: [VLRMatch]
}

struct VLRMatch: Codable, Identifiable, Sendable {
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

    var status: String? = nil // Added to support event-specific matches and better category filtering

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
        return components.first(where: { Int($0) != nil }) ?? ""
    }

    static var placeholder: VLRMatch {
        VLRMatch(team1: "Team 1", team2: "Team 2", flag1: "us", flag2: "ca", match_page: "/123/placeholder", score1: "0", score2: "0", time_until_match: "TBD", match_event: "Placeholder Event", match_series: "Placeholder Series", time_completed: "TBD", tournament_name: "Placeholder Tournament", round_info: "Placeholder Round", tournament_icon: nil)
    }

    static func placeholder(matchID: String) -> VLRMatch {
        VLRMatch(
            team1: "TBD",
            team2: "TBD",
            flag1: "flag_us",
            flag2: "flag_us",
            match_page: "/\(matchID)/placeholder",
            score1: nil,
            score2: nil,
            time_until_match: nil,
            match_event: nil,
            match_series: nil,
            time_completed: nil,
            tournament_name: nil,
            round_info: nil,
            tournament_icon: nil
        )
    }
}

// MARK: - Event Match List Response Models (/events/matches)

struct VLREventMatchResponse: Codable, Sendable {
    let status: String?
    let data: VLREventMatchData
}

struct VLREventMatchData: Codable, Sendable {
    let status: Int
    let segments: [VLREventMatch]
}

struct VLREventMatch: Codable, Identifiable, Sendable {
    var id: String { match_id }
    let match_id: String
    let url: String
    let date: String
    let status: String
    let note: String?
    let event_series: String?
    let team1: VLREventMatchTeam
    let team2: VLREventMatchTeam
    let vods: [VLREventMatchVOD]?
}

struct VLREventMatchTeam: Codable, Sendable {
    let name: String
    let score: String?
    let is_winner: Bool?
    let logo: String?
}

struct VLREventMatchVOD: Codable, Sendable {
    let label: String?
    let url: String?
}

extension VLRMatch {
    init(from eventMatch: VLREventMatch, eventName: String? = nil) {
        self.team1 = eventMatch.team1.name
        self.team2 = eventMatch.team2.name
        self.score1 = eventMatch.team1.score
        self.score2 = eventMatch.team2.score
        
        // v1 url is full https://www.vlr.gg/123171/...
        // v2 match_page is /123171/...
        if let urlObj = URL(string: eventMatch.url) {
            self.match_page = urlObj.path
        } else {
            self.match_page = eventMatch.url
        }
        
        self.match_series = eventMatch.event_series
        self.flag1 = "" // Flags are not in this endpoint
        self.flag2 = ""
        
        if eventMatch.status.lowercased() == "completed" {
            self.time_completed = eventMatch.date
            self.time_until_match = nil
        } else {
            self.time_completed = nil
            self.time_until_match = eventMatch.date
        }
        
        self.match_event = eventName
        self.tournament_name = eventName
        self.round_info = eventMatch.event_series
        self.tournament_icon = nil
        self.status = eventMatch.status
    }
}

// MARK: - Match Detail API Response Models (v2/match/details)

struct VLRMatchDetailResponse: Codable, Sendable {
    let status: String?
    let data: VLRMatchDetailData
}

struct VLRMatchDetailData: Codable, Sendable {
    let status: Int?
    let segments: [VLRMatchDetailSegment]
}

struct VLRMatchDetailSegment: Codable, Sendable {
    let match_id: String?
    let event: VLRMatchDetailEvent?
    let date: String?
    let patch: String?
    let status: String?
    let teams: [VLRMatchDetailTeam]
    let streams: [VLRMatchDetailStream]?
    let vods: [VLRMatchDetailVOD]?
    let maps: [VLRMatchDetailMap]?
    let head_to_head: [VLRPastEncounter]?
    let performance: VLRMatchDetailPerformance?

    // Derived helpers
    var team1: VLRMatchDetailTeam? { teams.first }
    var team2: VLRMatchDetailTeam? { teams.count > 1 ? teams[1] : nil }

    var isLive: Bool { status?.lowercased() == "live" }
    var isFinal: Bool { status?.lowercased() == "final" }
    var isUpcoming: Bool { !isLive && !isFinal }

    /// Aggregate player stats across all maps for the series scoreboard
    func aggregatedPlayers() -> [AggregatedPlayerStat] {
        guard let maps = maps else { return [] }
        var dict: [String: AggregatedPlayerStat] = [:]

        for map in maps {
            let allPlayers = (map.players?.team1 ?? []) + (map.players?.team2 ?? [])
            let teamFor: [String: Int] = {
                var t: [String: Int] = [:]
                for p in (map.players?.team1 ?? []) { t[p.name] = 1 }
                for p in (map.players?.team2 ?? []) { t[p.name] = 2 }
                return t
            }()

            for player in allPlayers {
                let rating = Double(player.rating) ?? 0
                let acs = Int(player.acs) ?? 0
                let kills = Int(player.kills) ?? 0
                let deaths = Int(player.deaths) ?? 0
                let assists = Int(player.assists) ?? 0
                let kastStr = player.kast?.replacingOccurrences(of: "%", with: "") ?? "0"
                let kast = Double(kastStr) ?? 0
                let adr = Int(player.adr) ?? 0
                let hsPctStr = player.hs_pct?.replacingOccurrences(of: "%", with: "") ?? "0"
                let hsPct = Double(hsPctStr) ?? 0
                let fk = Int(player.fk ?? "0") ?? 0
                let fd = Int(player.fd ?? "0") ?? 0
                
                // If a map is completely unplayed (e.g. 0-0 live match, or unreached Map 3),
                // we still want to list the player on the scoreboard, but we shouldn't
                // penalize their Series averages by incrementing `mapCount`.
                let isUnplayed = (rating == 0 && acs == 0 && kills == 0 && deaths == 0)

                if var existing = dict[player.name] {
                    if !isUnplayed { existing.mapCount += 1 }
                    existing.ratingSum += rating
                    existing.acs += acs
                    existing.kills += kills
                    existing.deaths += deaths
                    existing.assists += assists
                    existing.kastSum += kast
                    existing.adr += adr
                    existing.hsPctSum += hsPct
                    existing.fk += fk
                    existing.fd += fd
                    // Preserve or update the ID if we didn't have one before
                    if existing.player_id == nil || existing.player_id == "" {
                        existing.player_id = player.player_id
                    }
                    dict[player.name] = existing
                } else {
                    dict[player.name] = AggregatedPlayerStat(
                        name: player.name,
                        teamIndex: teamFor[player.name] ?? 0,
                        mapCount: isUnplayed ? 0 : 1,
                        ratingSum: rating,
                        acs: acs,
                        kills: kills,
                        deaths: deaths,
                        assists: assists,
                        kastSum: kast,
                        adr: adr,
                        hsPctSum: hsPct,
                        fk: fk,
                        fd: fd,
                        player_id: player.player_id
                    )
                }
            }
        }

        return Array(dict.values)
    }
}

struct VLRMatchDetailEvent: Codable, Sendable {
    let name: String?
    let series: String?
    let logo: String?
}

struct VLRMatchDetailTeam: Codable, Sendable {
    let name: String
    let tag: String?
    let logo: String?
    let score: String?
    let is_winner: Bool?
}

struct VLRMatchDetailStream: Codable, Sendable {
    let name: String?
    let url: String?
}

struct VLRMatchDetailVOD: Codable, Sendable {
    let name: String?
    let url: String?
}

struct VLRPastEncounter: Codable, Sendable, Identifiable {
    var id: String { match_page ?? UUID().uuidString }
    let match_page: String?
    let date: String?
    let teams: [VLRMatchDetailTeam]?
    let score: String?
}

struct VLRMatchDetailMap: Codable, Sendable {
    let map_name: String?
    let picked_by: String?
    let duration: String?
    let score: VLRMatchDetailMapScore?
    let score_ct: VLRMatchDetailMapScore?
    let score_t: VLRMatchDetailMapScore?
    let score_ot: VLRMatchDetailMapScore?
    let players: VLRMatchDetailMapPlayers?
    let rounds: [VLRMatchDetailRound]?
}

struct VLRMatchDetailMapScore: Codable, Sendable {
    // These can be Int (from final maps) or String (from partial/CT-T breakdowns)
    let team1: VLRFlexibleInt?
    let team2: VLRFlexibleInt?
}

/// Handles API fields that return either a String or Int
struct VLRFlexibleInt: Codable, Sendable {
    let value: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let strVal = try? container.decode(String.self), let intVal = Int(strVal) {
            value = intVal
        } else {
            value = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let v = value { try container.encode(v) } else { try container.encodeNil() }
    }
}

struct VLRMatchDetailMapPlayers: Codable, Sendable {
    let team1: [VLRMatchDetailPlayer]?
    let team2: [VLRMatchDetailPlayer]?
}

struct VLRMatchDetailPlayer: Codable, Sendable, Identifiable {
    var id: String { (player_id != nil && !player_id!.isEmpty) ? player_id! : name }
    let player_id: String?
    let name: String
    let agent: String?
    let rating: String
    let acs: String
    let kills: String
    let deaths: String
    let assists: String
    let kd_diff: String?
    let kast: String?
    let adr: String
    let hs_pct: String?
    let fk: String?
    let fd: String?
    let fk_diff: String?
}

struct VLRMatchDetailRound: Codable, Sendable {
    let round_num: Int?
    let winner: String?
    let side: String?
}

struct VLRMatchDetailPerformance: Codable, Sendable {
    let kill_matrix: [VLRKillMatrixRow]?
    let advanced_stats: [VLRAdvancedStat]?
}

struct VLRKillMatrixRow: Codable, Sendable {
    let player: String?
    let kills_vs: [String: String]?
}

struct VLRAdvancedStat: Codable, Sendable {
    let player: String?
}

struct VLRMatchDetailEconomy: Codable, Sendable {
    // Economy rows use indexed keys "0","1"..."5" which map to team, pistol, eco, semi, full
    // We store as a flexible dict
}

// MARK: - Aggregated Series Player Stats

struct AggregatedPlayerStat: Identifiable, Sendable {
    var id: String { name }
    let name: String
    let teamIndex: Int   // 1 = team1, 2 = team2
    var mapCount: Int

    var ratingSum: Double
    var acs: Int
    var kills: Int
    var deaths: Int
    var assists: Int
    var kastSum: Double
    var adr: Int
    var hsPctSum: Double
    var fk: Int
    var fd: Int
    var player_id: String?

    var avgRating: Double { mapCount > 0 ? ratingSum / Double(mapCount) : 0 }
    var avgKAST: Double   { mapCount > 0 ? kastSum  / Double(mapCount) : 0 }
    var avgHSPct: Double  { mapCount > 0 ? hsPctSum / Double(mapCount) : 0 }
    var avgADR: Int       { mapCount > 0 ? adr / mapCount : 0 }
    var avgACS: Int       { mapCount > 0 ? acs / mapCount : 0 }
    var kdDiff: Int       { kills - deaths }
    var fkDiff: Int       { fk - fd }
}
