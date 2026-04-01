//
//  PlayerProfile.swift
//  VALORANT Esports
//
//  Created by AI on 3/14/26.
//

import Foundation
import SwiftUI
import Combine

struct VLRPlayerResponse: Codable {
    let data: VLRPlayerData
}

struct VLRPlayerData: Codable {
    let status: Int
    let segments: [VLRPlayerProfile]
}

struct VLRPlayerProfile: Codable {
    let id: String
    let name: String
    let real_name: String
    let avatar: String
    let country: String
    let social_links: [VLRSocialLink]
    let current_team: VLRPlayerTeam
    let past_teams: [VLRPlayerPastTeam]
    let agent_stats: [VLRPlayerAgentStat]
    let event_placements: [VLRPlayerEventPlacement]
    let news: [VLRPlayerNews]
    let total_winnings: String
}

struct VLRSocialLink: Codable {
    let platform: String
    let url: String
}

struct VLRPlayerTeam: Codable {
    let name: String
    let tag: String
    let logo: String
    let joined: String
}

struct VLRPlayerPastTeam: Codable {
    let name: String
    let tag: String
    let dates: String
    let logo: String
}

struct VLRPlayerAgentStat: Codable, Identifiable {
    var id: String { agent }
    let agent: String
    let usage_count: String
    let usage_pct: String
    let rounds: String
    let rating: String
    let acs: String
    let kd: String
    let adr: String
    let kast: String
    let kpr: String
    let apr: String
    let fkpr: String
    let fdpr: String
    let kills: String
    let deaths: String
    let assists: String
    let fk: String
    let fd: String
}

struct VLRPlayerEventPlacement: Codable, Identifiable {
    var id: String { event + date }
    let event: String
    let series: String
    let placement: String
    let prize: String
    let team: String
    let date: String
    let url: String
}

struct VLRPlayerNews: Codable, Identifiable {
    var id: String { url }
    let title: String
    let url: String
    let date: String
}
